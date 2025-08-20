#!/usr/bin/env python3
"""
JellyDemon - Intelligent Jellyfin Bandwidth Management Daemon

Main daemon script that monitors Jellyfin sessions and manages user bandwidth limits
for external streamers based on configurable allocation algorithms.

Version: 1.0 Public Beta
Focus: Jellyfin bandwidth management (router integration coming in v2.0)
"""

import sys
import time
import signal
import logging
import argparse
from pathlib import Path
from typing import Dict, Any

from modules.config import Config
from modules.logger import setup_logging
from modules.jellyfin_client import JellyfinClient
from modules.bandwidth_manager import BandwidthManager
from modules.network_utils import NetworkUtils


class JellyDemon:
    """Main daemon class for bandwidth management."""
    
    def __init__(self, config_path: str = "config.yml"):
        """Initialize the daemon with configuration."""
        self.config = Config(config_path)
        self.logger = setup_logging(self.config)
        self.running = False
        
        # Initialize clients
        self.jellyfin = JellyfinClient(self.config.jellyfin)
        self.bandwidth_manager = BandwidthManager(self.config.bandwidth)
        self.network_utils = NetworkUtils(self.config.network)
        
        # Setup signal handlers
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
        
        self.logger.info("JellyDemon initialized")
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully."""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.running = False
    
    def validate_connectivity(self) -> bool:
        """Validate connectivity to all required services."""
        self.logger.info("Validating connectivity...")
        
        # Test Jellyfin connection
        if not self.jellyfin.test_connection():
            self.logger.error("Failed to connect to Jellyfin server")
            return False
        
        self.logger.info("All connectivity tests passed")
        return True
    
    def get_current_bandwidth_usage(self) -> float:
        """Get current upload bandwidth usage estimation."""
        try:
            # Since we don't have router integration, estimate usage from active Jellyfin streams
            sessions = self.jellyfin.get_active_sessions()
            total_usage = 0.0
            
            for session in sessions:
                # Estimate bandwidth usage per session
                transcoding_info = session.get('TranscodingInfo', {})
                if transcoding_info:
                    bitrate = transcoding_info.get('Bitrate', 0)
                    if bitrate > 0:
                        total_usage += bitrate / 1_000_000  # Convert to Mbps
                else:
                    # Estimate based on media info or use default
                    now_playing = session.get('NowPlayingItem', {})
                    media_bitrate = now_playing.get('Bitrate', 5_000_000)  # Default 5 Mbps
                    total_usage += media_bitrate / 1_000_000
            
            self.logger.debug(f"Estimated current usage from Jellyfin streams: {total_usage:.2f} Mbps")
            return total_usage
        except Exception as e:
            self.logger.error(f"Failed to estimate bandwidth usage: {e}")
            return 0.0
    
    def get_external_streamers(self) -> Dict[str, Dict[str, Any]]:
        """Get list of users streaming from external IPs."""
        try:
            # Get active sessions from Jellyfin
            sessions = self.jellyfin.get_active_sessions()
            external_sessions = {}
            
            for session in sessions:
                user_id = session.get('UserId')
                remote_endpoint = session.get('RemoteEndPoint', '')
                
                if user_id and remote_endpoint:
                    # Extract IP from endpoint (format: "IP:PORT")
                    client_ip = remote_endpoint.split(':')[0]
                    
                    # Check if IP is external
                    if self.network_utils.is_external_ip(client_ip):
                        external_sessions[user_id] = {
                            'ip': client_ip,
                            'session_data': session,
                            'user_data': self.jellyfin.get_user_info(user_id)
                        }
                        self.logger.debug(f"External streamer found: {user_id} from {client_ip}")
            
            self.logger.info(f"Found {len(external_sessions)} external streamers")
            return external_sessions
            
        except Exception as e:
            self.logger.error(f"Failed to get external streamers: {e}")
            return {}
    
    def calculate_and_apply_limits(self, external_streamers: Dict[str, Dict[str, Any]], 
                                  current_usage: float):
        """Calculate and apply bandwidth limits for external users."""
        if not external_streamers:
            self.logger.debug("No external streamers, skipping bandwidth calculation")
            return
        
        try:
            # Use configured total bandwidth (no router integration)
            total_bandwidth = self.config.bandwidth.total_upload_mbps
            available_bandwidth = total_bandwidth - current_usage - self.config.bandwidth.reserved_bandwidth
            
            # Ensure we don't go negative
            if available_bandwidth < 0:
                available_bandwidth = self.config.bandwidth.min_per_user * len(external_streamers)
                self.logger.warning(f"Available bandwidth calculation resulted in negative value, "
                                  f"using minimum allocation: {available_bandwidth:.2f} Mbps")
            
            self.logger.info(f"Total: {total_bandwidth:.2f} Mbps, "
                           f"Estimated usage: {current_usage:.2f} Mbps, "
                           f"Available: {available_bandwidth:.2f} Mbps")
            
            # Calculate per-user limits
            user_limits = self.bandwidth_manager.calculate_limits(
                external_streamers, available_bandwidth
            )
            
            # Apply limits to Jellyfin users
            for user_id, limit in user_limits.items():
                if self.config.daemon.dry_run:
                    user_info = external_streamers[user_id].get('user_data', {})
                    username = user_info.get('Name', user_id) if user_info else user_id
                    self.logger.info(f"[DRY RUN] Would set user {username} limit to {limit:.2f} Mbps")
                else:
                    self.jellyfin.set_user_bandwidth_limit(user_id, limit)
                    user_info = external_streamers[user_id].get('user_data', {})
                    username = user_info.get('Name', user_id) if user_info else user_id
                    self.logger.info(f"Set user {username} bandwidth limit to {limit:.2f} Mbps")
                    
        except Exception as e:
            self.logger.error(f"Failed to calculate/apply limits: {e}")
    
    def run_single_cycle(self):
        """Run a single monitoring/adjustment cycle."""
        self.logger.debug("Starting monitoring cycle")
        
        # Get current bandwidth usage
        current_usage = self.get_current_bandwidth_usage()
        
        # Get external streamers
        external_streamers = self.get_external_streamers()
        
        # Calculate and apply bandwidth limits
        self.calculate_and_apply_limits(external_streamers, current_usage)
        
        self.logger.debug("Monitoring cycle completed")
    
    def run(self):
        """Main daemon loop."""
        if not self.validate_connectivity():
            self.logger.error("Connectivity validation failed, exiting")
            return 1
        
        self.logger.info("Starting JellyDemon main loop")
        self.running = True
        
        try:
            while self.running:
                self.run_single_cycle()
                
                # Sleep for configured interval
                for _ in range(self.config.daemon.update_interval):
                    if not self.running:
                        break
                    time.sleep(1)
                    
        except Exception as e:
            self.logger.error(f"Unexpected error in main loop: {e}")
            return 1
        
        finally:
            self.logger.info("JellyDemon shutting down")
            
            # Save anonymization mapping if enabled
            if (self.config.daemon.anonymize_logs and 
                self.config.daemon.save_anonymization_map and 
                hasattr(self.logger, 'anonymizer')):
                try:
                    self.logger.anonymizer.save_mapping(self.config.daemon.anonymization_map_file)
                    self.logger.info(f"Anonymization mapping saved to {self.config.daemon.anonymization_map_file}")
                except Exception as e:
                    self.logger.error(f"Failed to save anonymization mapping: {e}")
            
            # TODO: Restore original user settings if backup was enabled
        
        return 0


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="JellyDemon - Jellyfin Bandwidth Manager")
    parser.add_argument("--config", "-c", default="config.yml", 
                       help="Configuration file path")
    parser.add_argument("--dry-run", action="store_true",
                       help="Run in dry-run mode (no changes applied)")
    parser.add_argument("--test", action="store_true",
                       help="Test connectivity and exit")
    
    args = parser.parse_args()
    
    try:
        daemon = JellyDemon(args.config)
        
        # Override dry-run setting if specified
        if args.dry_run:
            daemon.config.daemon.dry_run = True
        
        if args.test:
            # Test mode - just validate connectivity
            if daemon.validate_connectivity():
                print("✓ All connectivity tests passed")
                return 0
            else:
                print("✗ Connectivity tests failed")
                return 1
        
        # Run the daemon
        return daemon.run()
        
    except Exception as e:
        print(f"Fatal error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main()) 
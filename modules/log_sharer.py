#!/usr/bin/env python3
"""
Log sharing module for JellyDemon
Uploads anonymized logs to pastebin services for easy sharing
"""

import os
import sys
import json
import gzip
import tempfile
import platform
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, List
import requests
import logging

logger = logging.getLogger(__name__)


class LogSharer:
    """Handles uploading logs to pastebin services for sharing."""
    
    # List of pastebin services to try (in order of preference)
    PASTEBIN_SERVICES = [
        {
            'name': 'ix.io',
            'url': 'http://ix.io',
            'method': 'POST',
            'data_field': 'f:1',
            'response_format': 'url',
        },
        {
            'name': 'dpaste.org',
            'url': 'https://dpaste.org/api/',
            'method': 'POST',
            'data_field': 'content',
            'extra_fields': {'format': 'text', 'expires': 604800},  # 7 days
            'response_format': 'json',
            'url_field': 'url',
        },
        {
            'name': 'paste.ubuntu.com',
            'url': 'https://paste.ubuntu.com/',
            'method': 'POST',
            'data_field': 'content',
            'extra_fields': {'poster': 'JellyDemon', 'syntax': 'text'},
            'response_format': 'redirect',
        }
    ]
    
    def __init__(self, config_file: str = "config.yml"):
        """Initialize log sharer."""
        self.config_file = config_file
        self.log_files = ["jellydemon.log"]
        
    def collect_logs(self, hours: int = 24, max_lines: int = 1000) -> str:
        """Collect and format logs for sharing."""
        logger.info(f"Collecting logs from last {hours} hours...")
        
        # Start building the log content
        content_parts = []
        
        # Add header with system info
        content_parts.append(self._generate_header())
        content_parts.append("\n" + "="*80 + "\n")
        
        # Add configuration info (sanitized)
        config_info = self._get_sanitized_config()
        if config_info:
            content_parts.append("CONFIGURATION (sanitized):\n")
            content_parts.append(config_info)
            content_parts.append("\n" + "="*80 + "\n")
        
        # Add recent logs
        recent_logs = self._get_recent_logs(hours, max_lines)
        if recent_logs:
            content_parts.append(f"RECENT LOGS (last {hours} hours, max {max_lines} lines):\n")
            content_parts.append(recent_logs)
        else:
            content_parts.append("No recent logs found.\n")
        
        # Add diagnostics
        diagnostics = self._run_diagnostics()
        if diagnostics:
            content_parts.append("\n" + "="*80 + "\n")
            content_parts.append("DIAGNOSTICS:\n")
            content_parts.append(diagnostics)
        
        return "\n".join(content_parts)
    
    def _generate_header(self) -> str:
        """Generate header with system information."""
        try:
            # Get JellyDemon version
            version = "Unknown"
            try:
                with open("setup.py", "r", encoding='utf-8') as f:
                    content = f.read()
                    if 'VERSION = ' in content:
                        version_line = [line for line in content.split('\n') if 'VERSION = ' in line][0]
                        version = version_line.split('"')[1]
            except:
                pass
            
            # Get system info
            system_info = {
                "JellyDemon Version": version,
                "Python Version": platform.python_version(),
                "Operating System": f"{platform.system()} {platform.release()}",
                "Architecture": platform.machine(),
                "Timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC"),
            }
            
            header_lines = ["JellyDemon Log Share"]
            header_lines.append("Generated for support/debugging purposes")
            header_lines.append("")
            
            for key, value in system_info.items():
                header_lines.append(f"{key}: {value}")
                
            return "\n".join(header_lines)
            
        except Exception as e:
            logger.warning(f"Failed to generate header: {e}")
            return f"JellyDemon Log Share - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    
    def _get_sanitized_config(self) -> Optional[str]:
        """Get sanitized configuration for sharing."""
        try:
            if not os.path.exists(self.config_file):
                return "Configuration file not found"
            
            with open(self.config_file, "r", encoding='utf-8') as f:
                config_content = f.read()
            
            # Sanitize sensitive information
            lines = config_content.split("\n")
            sanitized_lines = []
            
            for line in lines:
                # Remove API keys
                if "api_key:" in line:
                    sanitized_lines.append("  api_key: [REDACTED]")
                # Remove other potentially sensitive fields
                elif any(keyword in line.lower() for keyword in ['password', 'secret', 'token']):
                    key_part = line.split(':')[0] if ':' in line else line
                    sanitized_lines.append(f"{key_part}: [REDACTED]")
                else:
                    sanitized_lines.append(line)
            
            return "\n".join(sanitized_lines)
            
        except Exception as e:
            logger.warning(f"Failed to get sanitized config: {e}")
            return f"Failed to read configuration: {e}"
    
    def _get_recent_logs(self, hours: int, max_lines: int) -> Optional[str]:
        """Get recent log entries."""
        try:
            cutoff_time = datetime.now() - timedelta(hours=hours)
            log_lines = []
            total_lines = 0
            
            for log_file in self.log_files:
                if not os.path.exists(log_file):
                    continue
                    
                try:
                    with open(log_file, "r", encoding='utf-8') as f:
                        for line in f:
                            if total_lines >= max_lines:
                                break
                                
                            # Try to parse timestamp
                            try:
                                # Assuming log format: "YYYY-MM-DD HH:MM:SS - LEVEL - MESSAGE"
                                timestamp_str = line.split(" - ")[0]
                                log_time = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
                                
                                if log_time >= cutoff_time:
                                    log_lines.append(line.rstrip())
                                    total_lines += 1
                            except (ValueError, IndexError):
                                # If we can't parse timestamp, include the line anyway
                                log_lines.append(line.rstrip())
                                total_lines += 1
                                
                except Exception as e:
                    logger.warning(f"Failed to read {log_file}: {e}")
                    continue
            
            if log_lines:
                if total_lines >= max_lines:
                    log_lines.append(f"\n[LOG TRUNCATED - showing last {max_lines} lines]")
                return "\n".join(log_lines)
            else:
                return None
                
        except Exception as e:
            logger.error(f"Failed to get recent logs: {e}")
            return f"Failed to read logs: {e}"
    
    def _run_diagnostics(self) -> str:
        """Run basic diagnostics and return results."""
        diagnostics = []
        
        try:
            # Check if main script exists
            if os.path.exists("jellydemon.py"):
                diagnostics.append("✓ Main script found")
            else:
                diagnostics.append("✗ Main script (jellydemon.py) not found")
            
            # Check modules
            modules = ["config", "jellyfin_client", "bandwidth_manager", "logger", "anonymizer"]
            for module in modules:
                module_path = f"modules/{module}.py"
                if os.path.exists(module_path):
                    diagnostics.append(f"✓ Module {module} found")
                else:
                    diagnostics.append(f"✗ Module {module} missing")
            
            # Check configuration
            if os.path.exists(self.config_file):
                diagnostics.append("✓ Configuration file found")
                try:
                    from modules.config import Config
                    config = Config(self.config_file)
                    diagnostics.append("✓ Configuration loaded successfully")
                    
                    # Basic config validation
                    if hasattr(config, 'jellyfin') and config.jellyfin.api_key:
                        if config.jellyfin.api_key == "your_jellyfin_api_key_here":
                            diagnostics.append("✗ API key not configured (still using example)")
                        else:
                            diagnostics.append("✓ API key configured")
                    else:
                        diagnostics.append("✗ API key missing")
                        
                except Exception as e:
                    diagnostics.append(f"✗ Configuration error: {e}")
            else:
                diagnostics.append("✗ Configuration file missing")
            
            # Check log files
            for log_file in self.log_files:
                if os.path.exists(log_file):
                    size = os.path.getsize(log_file)
                    diagnostics.append(f"✓ Log file {log_file} found ({size} bytes)")
                else:
                    diagnostics.append(f"✗ Log file {log_file} not found")
            
            return "\n".join(diagnostics)
            
        except Exception as e:
            return f"Diagnostics failed: {e}"
    
    def upload_to_pastebin(self, content: str) -> Optional[str]:
        """Upload content to a pastebin service and return URL."""
        
        for service in self.PASTEBIN_SERVICES:
            try:
                logger.info(f"Trying to upload to {service['name']}...")
                
                # Prepare request data
                data = {service['data_field']: content}
                if 'extra_fields' in service:
                    data.update(service['extra_fields'])
                
                # Make request
                response = requests.post(
                    service['url'],
                    data=data,
                    timeout=30,
                    headers={'User-Agent': 'JellyDemon-LogSharer/1.0'}
                )
                
                if response.status_code == 200:
                    # Parse response based on format
                    if service['response_format'] == 'url':
                        url = response.text.strip()
                    elif service['response_format'] == 'json':
                        try:
                            json_data = response.json()
                            url = json_data.get(service['url_field'], '').strip()
                        except (json.JSONDecodeError, AttributeError) as e:
                            logger.error(f"JSON parsing failed for {service['name']}: {e}")
                            continue
                    elif service['response_format'] == 'redirect':
                        url = response.url
                    else:
                        continue
                    
                    if url and url.startswith('http'):
                        logger.info(f"Successfully uploaded to {service['name']}")
                        return url
                
                logger.warning(f"Upload to {service['name']} failed: HTTP {response.status_code}")
                
            except Exception as e:
                logger.warning(f"Upload to {service['name']} failed: {e}")
                continue
        
        return None
    
    def share_logs(self, hours: int = 24, max_lines: int = 1000) -> Optional[str]:
        """Main method to collect and share logs."""
        try:
            print("🔍 Collecting logs and system information...")
            content = self.collect_logs(hours, max_lines)
            
            if not content.strip():
                print("❌ No logs found to share")
                return None
            
            print(f"📦 Collected {len(content.split())} words of log data")
            print("🌐 Uploading to pastebin service...")
            
            url = self.upload_to_pastebin(content)
            
            if url:
                print(f"✅ Logs shared successfully!")
                print(f"🔗 Share this URL: {url}")
                print(f"⏰ Link expires automatically (check service terms)")
                print("")
                print("💡 Include this URL when reporting issues or asking for help")
                return url
            else:
                print("❌ Failed to upload logs to any pastebin service")
                print("🔧 Fallback: Create local log file for manual sharing")
                
                # Create local file as fallback
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"jellydemon_logs_{timestamp}.txt"
                
                with open(filename, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"📁 Logs saved to: {filename}")
                print("📤 You can manually upload this file to a pastebin service")
                return filename
                
        except Exception as e:
            logger.error(f"Failed to share logs: {e}")
            print(f"❌ Error sharing logs: {e}")
            return None


def main():
    """CLI entry point for log sharing."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Share JellyDemon logs for support")
    parser.add_argument("--hours", type=int, default=24, help="Hours of logs to include (default: 24)")
    parser.add_argument("--max-lines", type=int, default=1000, help="Maximum log lines (default: 1000)")
    parser.add_argument("--config", default="config.yml", help="Configuration file path")
    
    args = parser.parse_args()
    
    sharer = LogSharer(args.config)
    result = sharer.share_logs(args.hours, args.max_lines)
    
    if result:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()

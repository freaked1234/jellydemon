#!/usr/bin/env python3
"""
Quick test to demonstrate anonymization mapping save functionality.
"""

import sys
from pathlib import Path

# Add modules to path
sys.path.insert(0, str(Path(__file__).parent))

from modules.config import Config
from modules.logger import setup_logging
from modules.jellyfin_client import JellyfinClient
from modules.network_utils import NetworkUtils

def main():
    """Test anonymization mapping save."""
    print("Testing anonymization mapping save...")
    
    config = Config('config.yml')
    logger = setup_logging(config)
    
    # Simulate some activity to generate anonymization mappings
    logger.info("Starting test with user JohnDoe from 192.168.1.100")
    logger.info("User alice connected from 8.8.8.8")
    logger.info("Set user bob bandwidth limit to 15.0 Mbps")
    logger.info("External user charlie from 203.0.113.45 started streaming")
    
    # Save the mapping
    if hasattr(logger, 'anonymizer') and logger.anonymizer.enabled:
        try:
            logger.anonymizer.save_mapping(config.daemon.anonymization_map_file)
            print(f"✓ Anonymization mapping saved to {config.daemon.anonymization_map_file}")
            
            # Show what was saved
            mapping = logger.anonymizer.get_mapping_summary()
            print(f"Mapping contains:")
            print(f"  - {mapping['stats']['total_users']} anonymized users")
            print(f"  - {mapping['stats']['total_ips']} anonymized IPs")
            
        except Exception as e:
            print(f"✗ Failed to save mapping: {e}")

if __name__ == "__main__":
    main()

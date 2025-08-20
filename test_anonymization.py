#!/usr/bin/env python3
"""
Test script to demonstrate log anonymization functionality.
"""

import sys
import logging
from pathlib import Path

# Add modules to path
sys.path.insert(0, str(Path(__file__).parent))

from modules.config import Config
from modules.logger import setup_logging
from modules.anonymizer import LogAnonymizer


def test_anonymization():
    """Test the anonymization functionality."""
    print("Testing Log Anonymization")
    print("=" * 50)
    
    # Test with anonymization enabled
    print("\n1. Testing anonymization enabled:")
    anonymizer = LogAnonymizer(enabled=True)
    
    test_messages = [
        "External streamer found: user123 from 192.168.1.100",
        "Set user JohnDoe bandwidth limit to 25.50 Mbps",
        "User: alice streaming from 8.8.8.8",
        "Failed to connect for user bob@example.com from 10.0.0.15",
        "Session abc-123-def started for user TestUser",
        "API key: sk-1234567890abcdef authentication successful",
        "\"Name\": \"RealUsername\" connected from 172.16.1.50"
    ]
    
    for msg in test_messages:
        anonymized = anonymizer.anonymize_message(msg)
        print(f"  Original:  {msg}")
        print(f"  Anonymous: {anonymized}")
        print()
    
    # Show mapping summary
    print("Anonymization mapping summary:")
    mapping = anonymizer.get_mapping_summary()
    print(f"  Users anonymized: {mapping['stats']['total_users']}")
    print(f"  IPs anonymized: {mapping['stats']['total_ips']}")
    print(f"  Sessions anonymized: {mapping['stats']['total_sessions']}")
    print()
    
    # Test with anonymization disabled
    print("2. Testing anonymization disabled:")
    anonymizer_disabled = LogAnonymizer(enabled=False)
    
    test_msg = "User JohnDoe from 192.168.1.100 set to 10 Mbps"
    result = anonymizer_disabled.anonymize_message(test_msg)
    print(f"  Original:  {test_msg}")
    print(f"  Result:    {result}")
    print(f"  Changed:   {'No' if test_msg == result else 'Yes'}")


def test_logger_integration():
    """Test anonymization integration with logger."""
    print("\n" + "=" * 50)
    print("Testing Logger Integration")
    print("=" * 50)
    
    try:
        # Load config and setup logger
        config = Config('config.yml')
        logger = setup_logging(config)
        
        print(f"\nAnonymization enabled: {config.daemon.anonymize_logs}")
        
        # Test log messages
        logger.info("External streamer found: user123 from 192.168.1.100")
        logger.info("Set user JohnDoe bandwidth limit to 25.50 Mbps")
        logger.debug("User: alice streaming from 8.8.8.8")
        logger.warning("Failed connection for user bob from 10.0.0.15")
        
        print("\n✓ Log messages sent (check console output above for anonymization)")
        
        # Show final mapping if available
        if hasattr(logger, 'anonymizer') and logger.anonymizer.enabled:
            mapping = logger.anonymizer.get_mapping_summary()
            print(f"\nFinal anonymization stats:")
            print(f"  Users: {mapping['stats']['total_users']}")
            print(f"  IPs: {mapping['stats']['total_ips']}")
        
    except Exception as e:
        print(f"✗ Error testing logger integration: {e}")


def main():
    """Main test function."""
    print("JellyDemon Anonymization Test Suite")
    print("=" * 60)
    
    # Test basic anonymization
    test_anonymization()
    
    # Test logger integration
    test_logger_integration()
    
    print("\n" + "=" * 60)
    print("Testing completed!")
    print("\nFor public testing:")
    print("1. Set anonymize_logs: true in config.yml")
    print("2. Users can safely share log files")
    print("3. Anonymization mapping saved for developer reference")


if __name__ == "__main__":
    main()

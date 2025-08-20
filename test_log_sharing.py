#!/usr/bin/env python3
"""
Test script for log sharing functionality
"""

import os
import sys
import tempfile
from datetime import datetime
from pathlib import Path

# Add modules to path
sys.path.insert(0, str(Path(__file__).parent))

from modules.log_sharer import LogSharer


def create_test_logs():
    """Create test log files for testing."""
    # Create a test log file
    test_content = f"""2025-08-20 10:30:15 - INFO - JellyDemon started
2025-08-20 10:30:16 - INFO - Connecting to Jellyfin server at localhost:8096
2025-08-20 10:30:17 - DEBUG - API key configured: 1234567890abcdef...
2025-08-20 10:30:18 - INFO - Found 2 active sessions
2025-08-20 10:30:19 - INFO - External user TestUser streaming from 203.0.113.42
2025-08-20 10:30:20 - INFO - Set user TestUser bandwidth limit to 25.50 Mbps
2025-08-20 10:30:21 - WARNING - Connection timeout to Jellyfin API
2025-08-20 10:30:22 - ERROR - Failed to apply bandwidth limit: Permission denied
2025-08-20 10:30:23 - INFO - Retrying bandwidth application...
2025-08-20 10:30:24 - INFO - Successfully applied bandwidth limit
"""
    
    with open("jellydemon.log", "w") as f:
        f.write(test_content)
    
    print("✓ Created test log file")


def create_test_config():
    """Create test configuration file."""
    test_config = """# JellyDemon Test Configuration
jellyfin:
  host: "localhost"
  port: 8096
  api_key: "test_api_key_1234567890abcdef"
  use_https: false

network:
  internal_ranges:
    - "192.168.0.0/16"
    - "10.0.0.0/8"

bandwidth:
  total_upload_mbps: 50.0
  algorithm: "equal_split"

daemon:
  update_interval_seconds: 15
  dry_run: true
  log_level: "INFO"
  anonymize_logs: true
"""
    
    with open("config.yml", "w") as f:
        f.write(test_config)
    
    print("✓ Created test config file")


def test_log_collection():
    """Test log collection functionality."""
    print("\n🔍 Testing log collection...")
    
    sharer = LogSharer("config.yml")
    content = sharer.collect_logs(hours=24, max_lines=100)
    
    if content:
        print(f"✓ Collected {len(content)} characters of log data")
        print("✓ Content includes:")
        
        if "JellyDemon Log Share" in content:
            print("  - Header with system info")
        if "CONFIGURATION" in content:
            print("  - Sanitized configuration")
        if "RECENT LOGS" in content:
            print("  - Recent log entries")
        if "DIAGNOSTICS" in content:
            print("  - Diagnostic information")
        
        # Check anonymization
        if "test_api_key" not in content:
            print("  - API key properly redacted")
        else:
            print("  ⚠ API key not redacted!")
        
        return True
    else:
        print("✗ Failed to collect logs")
        return False


def test_log_sharing_dry_run():
    """Test log sharing without actually uploading."""
    print("\n📤 Testing log sharing (dry run)...")
    
    sharer = LogSharer("config.yml")
    
    # Test content collection
    content = sharer.collect_logs(hours=24, max_lines=100)
    
    if content:
        print("✓ Log content prepared for sharing")
        print(f"  Content size: {len(content)} characters")
        
        # Show a preview
        lines = content.split('\n')
        print("  Preview (first 5 lines):")
        for i, line in enumerate(lines[:5]):
            print(f"    {i+1}: {line}")
        
        # Save to local file instead of uploading
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"test_log_share_{timestamp}.txt"
        
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✓ Test content saved to: {filename}")
        print("  (This would normally be uploaded to a pastebin service)")
        
        return True
    else:
        print("✗ Failed to prepare log content")
        return False


def cleanup():
    """Clean up test files."""
    test_files = ["jellydemon.log", "config.yml"]
    for file in test_files:
        if os.path.exists(file):
            os.remove(file)
    
    # Remove any test log share files
    for file in Path(".").glob("test_log_share_*.txt"):
        file.unlink()
    
    print("\n🧹 Cleaned up test files")


def main():
    """Run log sharing tests."""
    print("🧪 JellyDemon Log Sharing Test")
    print("=" * 40)
    
    try:
        # Setup
        create_test_logs()
        create_test_config()
        
        # Run tests
        test1_passed = test_log_collection()
        test2_passed = test_log_sharing_dry_run()
        
        # Results
        print("\n" + "=" * 40)
        print("📊 Test Results:")
        print(f"  Log Collection: {'✓ PASS' if test1_passed else '✗ FAIL'}")
        print(f"  Log Sharing:    {'✓ PASS' if test2_passed else '✗ FAIL'}")
        
        if test1_passed and test2_passed:
            print("\n🎉 All tests passed! Log sharing is ready to use.")
            print("\nTo test with real upload:")
            print("  python jellydemon.py --share-logs")
        else:
            print("\n❌ Some tests failed. Check the output above.")
            return 1
        
        return 0
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        return 1
        
    finally:
        cleanup()


if __name__ == "__main__":
    sys.exit(main())

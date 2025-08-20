# JellyDemon v1.0 - Public Beta Release Notes

## 🎉 Ready for Public Testing!

JellyDemon has been successfully updated to focus on Jellyfin bandwidth management without router dependencies. This version is ready for public testing and feedback.

## ✅ What's Working

### Core Functionality
- **Jellyfin API Integration**: Complete session monitoring and user management
- **External User Detection**: Identifies users streaming from outside configured IP ranges
- **Bandwidth Allocation**: Three algorithms available (equal_split, priority_based, demand_based)
- **User Bandwidth Limits**: Automatically applies calculated limits to Jellyfin users
- **Configuration Management**: Simple YAML-based configuration
- **Comprehensive Logging**: Detailed logging with configurable levels

### Safety Features
- **Dry-run Mode**: Test without applying changes
- **User Settings Backup**: Automatically backs up original user bandwidth limits
- **Error Handling**: Robust error handling and recovery
- **Signal Handling**: Graceful shutdown with cleanup
- **Privacy Protection**: Comprehensive log anonymization for public testing

### Privacy & Anonymization (NEW!)
- **Log Anonymization**: Automatically anonymizes usernames, IP addresses, and session IDs
- **Safe Bug Reporting**: Users can share log files without exposing personal information
- **Developer Mapping**: Anonymization mapping saved for developer reference
- **Configurable**: Privacy features can be enabled/disabled via configuration

### Testing & Development
- **Test Suite**: Comprehensive testing framework
- **Multiple Test Modes**: Component-specific and integration tests
- **Development Tools**: Easy setup and configuration scripts

## 🔧 Key Changes from Router Version

### Removed Dependencies
- ❌ `paramiko` (SSH client for router access)
- ❌ `modules/openwrt_client.py` (OpenWRT integration)
- ❌ Router configuration sections
- ❌ Router connectivity tests

### Modified Components
- **Bandwidth Usage Calculation**: Now estimates usage from active Jellyfin streams instead of router data
- **Configuration**: Simplified to remove router sections, added manual `total_upload_mbps` setting
- **Main Daemon**: Removed router initialization and bandwidth monitoring
- **Test Suite**: Updated to focus on Jellyfin and bandwidth algorithm testing
- **Logging System**: Added comprehensive anonymization for privacy protection

### New Components
- **Anonymization Module**: `modules/anonymizer.py` - Handles privacy protection in logs
- **Anonymization Tests**: `test_anonymization.py` - Demonstrates privacy features
- **Privacy Configuration**: New daemon settings for controlling anonymization behavior

## 📁 Project Structure

```
jellydemon/
├── jellydemon.py              # Main daemon script
├── config.example.yml         # Example configuration (no router section)
├── requirements.txt           # Updated dependencies (no paramiko)
├── test_jellydemon.py         # Updated test suite
├── setup.py                   # Updated setup script
├── README.md                  # Updated documentation
└── modules/
    ├── __init__.py
    ├── config.py              # Updated config (no RouterConfig)
    ├── jellyfin_client.py     # Unchanged
    ├── bandwidth_manager.py   # Unchanged
    ├── logger.py              # Unchanged
    └── network_utils.py       # Unchanged
```

## 🚀 Quick Start for Testers

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Create configuration:**
   ```bash
   cp config.example.yml config.yml
   # Edit config.yml with your Jellyfin settings
   # anonymize_logs: true is enabled by default for privacy
   ```

3. **Test connectivity:**
   ```bash
   python jellydemon.py --test
   ```

4. **Run in dry-run mode:**
   ```bash
   python jellydemon.py --dry-run
   ```

5. **Test anonymization:**
   ```bash
   python test_anonymization.py
   ```

## 🔒 Privacy Protection

**Log anonymization is enabled by default** for public testing:

- Usernames become `User-001`, `User-002`, etc.
- IP addresses become `192.168.xxx.1`, `External-IP-001`, etc.
- Session IDs become `Session-001`, `Session-002`, etc.
- API keys become `[API-KEY-abc123...]`

**Safe for sharing:** Log files contain no personally identifiable information!

## 🎯 Testing Focus Areas

### Primary Testing
- **Jellyfin Integration**: Test with various Jellyfin server versions and configurations
- **External User Detection**: Verify IP range detection works correctly
- **Bandwidth Algorithms**: Test all three allocation methods with different user scenarios
- **User Limit Application**: Confirm bandwidth limits are properly applied and restored

### Configuration Testing
- **Different Network Setups**: Test with various internal IP ranges
- **Bandwidth Settings**: Test with different total bandwidth and allocation settings
- **Algorithm Comparison**: Compare results between equal_split, priority_based, and demand_based

### Edge Cases
- **No External Users**: Behavior when all users are internal
- **High User Count**: Performance with many simultaneous external streamers
- **Configuration Errors**: Error handling with invalid configurations
- **Jellyfin Downtime**: Behavior when Jellyfin server is unavailable

## 🛣️ Roadmap

### v2.0 - Router Integration (Coming Soon)
- Automatic bandwidth monitoring from OpenWRT routers
- Real-time network usage detection  
- SQM integration for advanced QoS control
- Dynamic bandwidth allocation based on actual network demand

### v2.1 - Enhanced Features
- Historical bandwidth data collection
- Web dashboard for monitoring and control
- Advanced notification system
- Support for additional router types

## 📝 Feedback Requested

We're looking for feedback on:

1. **Installation Process**: How easy was setup and configuration?
2. **Documentation**: Is the README clear and complete?
3. **Algorithm Performance**: How well do the different allocation methods work for your use case?
4. **Stability**: Any crashes, errors, or unexpected behavior?
5. **Feature Requests**: What additional functionality would be valuable?

## 📞 Support & Contributing

- **Issues**: Report bugs and feature requests through GitHub issues
- **Testing**: Document your testing setup and results
- **Documentation**: Suggest improvements to setup guides and documentation
- **Code**: Contributions welcome for bug fixes and new features

---

**Version**: 1.0 Public Beta  
**Release Date**: August 20, 2025  
**Target Audience**: Public testing and feedback  
**Next Milestone**: Router integration (v2.0)

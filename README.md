# JellyDemon - Intelligent Jellyfin Bandwidth Management

## 🧪 **Early Beta - Seeking Testers!**

**We need your help testing JellyDemon across different systems and configurations!**

This is an **early beta release** and we're looking for testers to help validate the daemon's performance across various:
- Operating systems
- Jellyfin server configurations and versions  
- Network environments and hardware setups
- Different bandwidth management scenarios

**🔬 What we need from testers:**
- Regular feedback on daemon performance and stability
- Report any issues, crashes, or unexpected behavior
- Share your experience with installation and configuration
- Submit logs when experiencing problems or unusual behavior

**📤 Easy Log Sharing:**
JellyDemon includes a built-in log sharing feature that automatically uploads anonymized logs to help with support:
```bash
jellydemon share-logs  # Or: python jellydemon.py --share-logs
```
This generates a shareable URL with your sanitized logs (all usernames, IPs, and API keys are automatically removed for privacy). **Please include this URL with any feedback or issue reports** - it helps us diagnose problems much faster!

---

A Python daemon that automatically manages Jellyfin user bandwidth limits for external streamers based on configurable bandwidth allocation algorithms.

## Current Status: Public Beta v1.0

🎯 **Ready for testing!** This version focuses on Jellyfin user bandwidth management without router integration.

⚡ **Router integration coming soon** - Automatic bandwidth monitoring and dynamic allocation will be added in v2.0.

## Project Scope

JellyDemon currently provides:

1. **External User Detection**: Identifies Jellyfin users streaming from outside your configured IP ranges
2. **Smart Bandwidth Allocation**: Calculates and applies appropriate bandwidth limits per user using configurable algorithms
3. **Automatic Management**: Runs as a daemon with configurable intervals and safety features
4. **Multiple Algorithms**: Choose from equal split, priority-based, or demand-based allocation

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Manual        │    │   JellyDemon    │    │   Jellyfin      │
│   Configuration │◄──►│   Daemon        │◄──►│   Server        │
│                 │    │                 │    │                 │
│ • Bandwidth     │    │ • Monitor       │    │ • Active        │
│   limits        │    │ • Calculate     │    │   sessions      │
│ • IP ranges     │    │ • Apply limits  │    │ • User limits   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Features

- **Real-time Monitoring**: Continuously monitors Jellyfin streaming activity
- **External User Detection**: Identifies users streaming from outside configured IP ranges
- **Dynamic Bandwidth Management**: Automatically adjusts user limits based on available bandwidth
- **Configurable Algorithms**: Three bandwidth calculation methods available
- **Comprehensive Logging**: Detailed logs for monitoring and debugging
- **Safe Operation**: Dry-run mode and backup/restore functionality
- **Easy Configuration**: Simple YAML configuration file
- **Privacy Protection**: Log anonymization for safe public testing and bug reporting

## Requirements

- Jellyfin server with API access
- Python 3.8+ environment (can run on the same machine as Jellyfin)
- Network access to monitor external streaming sessions

## Installation

### 🚀 **One-Line Installation (Recommended)**

#### **Linux/macOS:**
```bash
curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/install.sh | bash
```

#### **Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/freaked1234/jellydemon/main/install.ps1 | iex
```

#### **Python Package (pip) - Coming Soon:**
```bash
pip install jellydemon
jellydemon --setup  # Interactive setup wizard
```

#### **Docker (Any Platform):**
```bash
# Quick start with Docker Compose
git clone https://github.com/freaked1234/jellydemon.git
cd jellydemon
mkdir config logs
cp config.example.yml config/config.yml
# Edit config/config.yml with your settings
docker-compose up -d
```

### 🎯 **What the Installer Does**
- ✅ **Detects and installs Python** automatically if missing (3.8+)
- ✅ **Installs all dependencies** automatically
- ✅ **Creates system user** and proper permissions
- ✅ **Sets up systemd service** (Linux) or Windows service
- ✅ **Interactive configuration wizard** - no manual editing needed!
- ✅ **Guides you through all settings** with explanations
- ✅ **Tests your Jellyfin connection** automatically
- ✅ **Creates management commands** (`jellydemon start/stop/status`)
- ✅ **Configures logging** and security settings
- ✅ **Enables dry-run mode** by default for safe testing

### 📱 **Super Easy Setup**

The installer includes an **interactive configuration wizard** that guides you through:

✅ **Jellyfin Connection** - Server address and API key setup  
✅ **Bandwidth Settings** - Speed test guidance and bandwidth allocation  
✅ **Network Configuration** - Automatic detection of your local network  
✅ **Privacy Settings** - Log anonymization for safe sharing  
✅ **Testing Mode** - Dry-run enabled by default for safety

**No more manual config file editing!** Just answer a few questions and you're ready to go.

After installation, just three commands:

```bash
# 1. Test your settings (automatic if you used the wizard)
jellydemon test

# 2. Start the service (dry-run mode enabled for safety)
jellydemon start

# 3. Monitor and verify it's working
jellydemon logs
```

### 🔧 **Management Commands**

After installation, you get simple commands:

```bash
jellydemon start         # Start the service
jellydemon stop          # Stop the service  
jellydemon restart       # Restart the service
jellydemon status        # Check if running
jellydemon logs          # View live logs
jellydemon test          # Test configuration
jellydemon share-logs    # Upload logs to pastebin for support
jellydemon config        # Show configuration options
jellydemon reconfigure   # Run configuration wizard again
jellydemon enable        # Auto-start on boot
jellydemon disable       # Don't auto-start
```

### 📤 **Easy Log Sharing for Support**

When you need help, sharing logs is now effortless:

```bash
# One command uploads anonymized logs and gives you a shareable URL
jellydemon share-logs

# Output:
# 🔍 Collecting logs and system information...
# 📦 Collected 2,156 words of log data
# 🌐 Uploading to pastebin service...
# ✅ Logs shared successfully!
# 🔗 Share this URL: https://ix.io/abc123
# 💡 Include this URL when reporting issues or asking for help
```

**What gets shared:**
- ✅ **Recent logs** (last 24 hours, anonymized)
- ✅ **System information** (OS, Python version, JellyDemon version)
- ✅ **Sanitized configuration** (API keys redacted)
- ✅ **Basic diagnostics** (file checks, connectivity status)

**Privacy protected:**
- ✅ **Automatic anonymization** (usernames, IPs, session IDs replaced)
- ✅ **API keys redacted** from configuration
- ✅ **Expires automatically** (7 days max)
- ✅ **No personal data** exposed

### 🔄 **Easy Reconfiguration**

Need to change settings? No problem:

```bash
# Run the interactive wizard again
jellydemon reconfigure

# Or edit manually  
jellydemon config
```

### 🐳 **Docker Quick Start**

For the easiest possible setup:

```bash
# Download and start in one command
curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/docker-compose.yml -o docker-compose.yml
mkdir config logs
curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/config.example.yml -o config/config.yml

# Edit config/config.yml with your Jellyfin details, then:
docker-compose up -d
```

### 🔑 **Getting Your Jellyfin API Key**

1. Open Jellyfin Admin Dashboard
2. Go to **Advanced** → **API Keys**  
3. Click **"+"** to create new key
4. Name it "JellyDemon"
5. Copy the generated key to your config file

### Testing & Validation

```bash
# Test all components
python test_jellydemon.py

# Test specific components
python test_jellydemon.py --test jellyfin
python test_jellydemon.py --test network
python test_jellydemon.py --test bandwidth

# Test with the main daemon
python jellydemon.py --test
```

## Configuration

Key configuration options in `config.yml`:

- **Jellyfin settings**: URL, API key, user management
- **Network ranges**: Define internal/external IP ranges  
- **Bandwidth settings**: Set total upload bandwidth and allocation algorithms
- **Daemon settings**: Update intervals, logging level

## Bandwidth Allocation Algorithms

Choose from three allocation methods:

1. **Equal Split**: Divides available bandwidth equally among external users
2. **Priority Based**: Allocates more bandwidth to admin users and premium accounts
3. **Demand Based**: Allocates bandwidth based on actual stream requirements and quality

## Privacy & Testing

### Log Anonymization

For public testing and bug reporting, JellyDemon includes comprehensive log anonymization:

```yaml
daemon:
  anonymize_logs: true  # Enable privacy protection
  save_anonymization_map: true  # Save mapping for developers
  anonymization_map_file: "anonymization_map.json"
```

**What gets anonymized:**
- ✅ Usernames → `User-001`, `User-002`, etc.
- ✅ IP addresses → `192.168.xxx.1`, `External-IP-001`, etc.  
- ✅ Session IDs → `Session-001`, `Session-002`, etc.
- ✅ API keys → `[API-KEY-abc123...]`

**What stays intact:**
- ✅ Network structure (internal vs external classification)
- ✅ Bandwidth numbers and calculations
- ✅ Error messages and debugging information
- ✅ Timestamps and log levels

**Example anonymized log:**
```
2025-08-20 10:30:15 - INFO - Set user User-003 bandwidth limit to 25.50 Mbps
2025-08-20 10:30:16 - DEBUG - External streamer found: User-003 from External-IP-002
```

Users can safely share log files for support without exposing sensitive information!

## Safety Features

- **Dry-run mode**: Test without applying changes
- **Backup/restore**: Save and restore user settings
- **Validation**: Verify API connectivity before operation
- **Graceful shutdown**: Clean exit with settings restoration

## Usage

### Running the Daemon

```bash
# Test connectivity first
python jellydemon.py --test

# Dry run (no changes applied)
python jellydemon.py --dry-run

# Normal operation
python jellydemon.py

# Custom config file
python jellydemon.py --config /path/to/config.yml

# Run as systemd service
sudo systemctl start jellydemon
sudo systemctl enable jellydemon  # Auto-start on boot
```

### Testing and Development

```bash
# Run comprehensive tests
python test_jellydemon.py

# Test specific components
python test_jellydemon.py --test network     # IP range detection
python test_jellydemon.py --test jellyfin    # Jellyfin API
python test_jellydemon.py --test bandwidth   # Algorithm testing
python test_jellydemon.py --test integration # Full integration

# Test log anonymization
python test_anonymization.py

# Check logs
tail -f jellydemon.log
```

### Sharing Logs for Support

When reporting issues during public testing:

1. **Anonymization is enabled by default** in the example config
2. **Log files are safe to share** - no personal information exposed
3. **Include the anonymization mapping** (`anonymization_map.json`) if requested by developers
4. **Mapping file helps developers** decode logs while protecting your privacy

## Roadmap: Upcoming Features

### v2.0 - Router Integration
- **Automatic bandwidth monitoring** from OpenWRT routers
- **Real-time network usage** detection
- **SQM integration** for advanced QoS control
- **Dynamic bandwidth allocation** based on actual network demand

### v2.1 - Enhanced Features
- **Historical bandwidth data** collection and analysis
- **Web dashboard** for monitoring and control  
- **Advanced notification system** for bandwidth events
- **Support for additional router types** beyond OpenWRT

## Current Limitations

- **Manual bandwidth configuration required** - You must set your total upload bandwidth in the config
- **No real-time network monitoring** - Bandwidth usage is estimated from Jellyfin sessions
- **Jellyfin-only bandwidth management** - Cannot control non-Jellyfin traffic

These limitations will be addressed in the router integration update (v2.0).

## Uninstallation

### 🗑️ **Easy Removal**

#### **Linux/macOS:**
```bash
curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/uninstall.sh | bash
```

#### **Windows:**
```powershell
# Remove installation directory (adjust path if different)
Remove-Item -Path "$env:ProgramFiles\JellyDemon" -Recurse -Force
```

#### **Docker:**
```bash
docker-compose down
docker rmi jellydemon_jellydemon  # Remove image
rm -rf config logs  # Remove data (optional)
```

The uninstaller will:
- ✅ Stop and remove the service
- ✅ Back up your configuration 
- ✅ Remove all files and user accounts
- ✅ Clean up system integration

## Getting Help & Troubleshooting

### 🆘 **Need Support?**

**The easiest way to get help:**

```bash
# Share your logs instantly for support
jellydemon share-logs

# Docker users:
docker exec jellydemon python jellydemon.py --share-logs
```

This uploads **anonymized logs** and gives you a URL to include when asking for help on:
- **GitHub Issues**: https://github.com/freaked1234/jellydemon/issues
- **Reddit**: r/jellyfin community
- **Discord**: Jellyfin support servers  
- **Email**: Direct support

**What gets shared:** Recent logs, system info, sanitized config, diagnostics  
**Privacy:** All usernames, IPs, and API keys are automatically anonymized

### Common Issues

1. **Connection failures:**
   ```bash   
   # Test Jellyfin API
   curl -H "Authorization: MediaBrowser Token=YOUR_API_KEY" \
        http://your-jellyfin:8096/System/Info
   ```

2. **Permission errors:**
   ```bash
   # Ensure proper permissions
   chmod +x jellydemon.py
   chmod +x setup.py
   ```

3. **Module import errors:**
   ```bash
   # Check Python path
   python -c "import sys; print(sys.path)"
   
   # Install missing dependencies
   pip install -r requirements.txt
   ```

4. **Configuration issues:**
   - Verify your Jellyfin API key is valid
   - Check that internal IP ranges are configured correctly
   - Ensure total_upload_mbps is set to your actual upload speed

### Debugging

Enable debug logging in `config.yml`:
```yaml
daemon:
  log_level: "DEBUG"
```

Check specific component logs:
```bash
grep "jellydemon.jellyfin" jellydemon.log    # Jellyfin API calls  
grep "jellydemon.bandwidth" jellydemon.log   # Algorithm calculations
grep "jellydemon.network" jellydemon.log     # IP range detection
```

## Development Status

This project is ready for public testing and feedback! Current implementation provides:
- ✅ Complete Jellyfin API integration with session monitoring
- ✅ Three bandwidth allocation algorithms (equal, priority, demand-based)  
- ✅ Configurable IP range detection for external users
- ✅ Comprehensive logging and error handling
- ✅ Dry-run mode for safe testing
- ✅ Test suite for validation and debugging
- ✅ User bandwidth limit backup/restore functionality

### Contributing

Feedback and contributions are welcome! Areas of interest:
- Testing with different Jellyfin configurations
- Algorithm improvements and new allocation methods
- Cross-platform compatibility testing
- Documentation improvements

## License

MIT License - See LICENSE file for details 
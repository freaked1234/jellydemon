#!/bin/bash

# JellyDemon One-Line Installer
# Usage: curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/jellydemon"
SERVICE_USER="jellydemon"
REPO_URL="https://github.com/freaked1234/jellydemon.git"

echo -e "${BLUE}🎬 JellyDemon Installer${NC}"
echo -e "${BLUE}=====================${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}❌ Don't run this script as root!${NC}"
    echo "Run as a regular user with sudo access."
    exit 1
fi

# Check for required commands
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is required but not installed.${NC}"
        echo "Please install $1 and try again."
        exit 1
    fi
}

echo "🔍 Checking prerequisites..."
check_command python3
check_command pip3
check_command git
check_command sudo

# Check Python version
python_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
if python3 -c 'import sys; exit(0 if sys.version_info >= (3,8) else 1)'; then
    echo -e "${GREEN}✅ Python $python_version (compatible)${NC}"
else
    echo -e "${RED}❌ Python 3.8+ required (found $python_version)${NC}"
    exit 1
fi

# Create jellydemon user if it doesn't exist
echo "👤 Setting up jellydemon user..."
if ! id "$SERVICE_USER" &>/dev/null; then
    sudo useradd --system --shell /bin/false --home-dir "$INSTALL_DIR" --create-home "$SERVICE_USER"
    echo -e "${GREEN}✅ Created jellydemon user${NC}"
else
    echo -e "${YELLOW}⚠️  jellydemon user already exists${NC}"
fi

# Create installation directory
echo "📁 Creating installation directory..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Clone repository
echo "📥 Downloading JellyDemon..."
if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "${YELLOW}⚠️  Updating existing installation...${NC}"
    sudo -u "$SERVICE_USER" git -C "$INSTALL_DIR" pull
else
    sudo -u "$SERVICE_USER" git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
sudo -u "$SERVICE_USER" python3 -m pip install --user -r "$INSTALL_DIR/requirements.txt"

# Interactive configuration setup
echo "⚙️  Setting up configuration..."
if [ ! -f "$INSTALL_DIR/config.yml" ]; then
    echo ""
    echo -e "${BLUE}🎯 Interactive Configuration Setup${NC}"
    echo "We'll now configure JellyDemon for your Jellyfin server."
    echo "This will only take a few minutes and you can change everything later."
    echo ""
    read -p "Would you like to configure JellyDemon now? [Y/n]: " configure_now
    configure_now=${configure_now:-Y}
    
    if [[ $configure_now =~ ^[Yy]$ ]]; then
        # Run interactive configuration as the jellydemon user
        sudo -u "$SERVICE_USER" bash "$INSTALL_DIR/configure.sh" "$INSTALL_DIR/config.yml"
    else
        # Create from example for manual configuration
        sudo -u "$SERVICE_USER" cp "$INSTALL_DIR/config.example.yml" "$INSTALL_DIR/config.yml"
        echo -e "${YELLOW}⚠️  Created config.yml from example - you'll need to edit it manually${NC}"
        echo "Edit with: sudo nano $INSTALL_DIR/config.yml"
    fi
else
    echo -e "${YELLOW}⚠️  config.yml already exists, skipping configuration${NC}"
fi

# Create systemd service
echo "🔧 Setting up systemd service..."
sudo tee /etc/systemd/system/jellydemon.service > /dev/null <<EOF
[Unit]
Description=JellyDemon - Jellyfin Bandwidth Management Daemon
After=network.target
Wants=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/jellydemon.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload
echo -e "${GREEN}✅ Systemd service created${NC}"

# Create management scripts
echo "🛠️  Creating management scripts..."

# Create jellydemon command
sudo tee /usr/local/bin/jellydemon > /dev/null <<EOF
#!/bin/bash
# JellyDemon management script

case "\$1" in
    start)
        sudo systemctl start jellydemon
        echo "Started JellyDemon"
        ;;
    stop)
        sudo systemctl stop jellydemon
        echo "Stopped JellyDemon"
        ;;
    restart)
        sudo systemctl restart jellydemon
        echo "Restarted JellyDemon"
        ;;
    status)
        sudo systemctl status jellydemon
        ;;
    logs)
        sudo journalctl -u jellydemon -f
        ;;
    test)
        sudo -u $SERVICE_USER python3 $INSTALL_DIR/jellydemon.py --test
        ;;
    health)
        echo "🏥 Running JellyDemon health check..."
        sudo -u $SERVICE_USER python3 $INSTALL_DIR/health_check.py
        ;;
    share-logs)
        echo "📤 Sharing recent logs for support..."
        sudo -u $SERVICE_USER python3 $INSTALL_DIR/jellydemon.py --share-logs
        ;;
    config)
        echo "Configuration file: $INSTALL_DIR/config.yml"
        echo ""
        echo "Options:"
        echo "  1. Run configuration wizard: sudo -u $SERVICE_USER bash $INSTALL_DIR/configure.sh $INSTALL_DIR/config.yml"
        echo "  2. Edit manually: sudo nano $INSTALL_DIR/config.yml"
        ;;
    reconfigure)
        echo "Running configuration wizard..."
        sudo -u $SERVICE_USER bash $INSTALL_DIR/configure.sh $INSTALL_DIR/config.yml
        echo ""
        echo "Configuration updated. Restart JellyDemon to apply changes:"
        echo "  jellydemon restart"
        ;;
    enable)
        sudo systemctl enable jellydemon
        echo "JellyDemon will start automatically on boot"
        ;;
    disable)
        sudo systemctl disable jellydemon
        echo "JellyDemon will not start automatically on boot"
        ;;
    uninstall)
        echo "To uninstall JellyDemon, run: curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/uninstall.sh | bash"
        ;;
    *)
        echo "Usage: jellydemon {start|stop|restart|status|logs|test|health|share-logs|config|reconfigure|enable|disable|uninstall}"
        echo ""
        echo "Commands:"
        echo "  start       - Start the JellyDemon service"
        echo "  stop        - Stop the JellyDemon service"
        echo "  restart     - Restart the JellyDemon service"
        echo "  status      - Show service status"
        echo "  logs        - Show live logs"
        echo "  test        - Test configuration and connectivity"
        echo "  health      - Run system health check"
        echo "  share-logs  - Upload recent logs to pastebin for support"
        echo "  config      - Show configuration options"
        echo "  reconfigure - Run interactive configuration wizard"
        echo "  enable      - Enable auto-start on boot"
        echo "  disable     - Disable auto-start on boot"
        echo "  uninstall   - Show uninstall instructions"
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/jellydemon

echo ""
echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
echo ""

# Show different next steps based on whether configuration was completed
if [ -f "$INSTALL_DIR/config.yml" ]; then
    # Check if it looks like it was configured (not just copied from example)
    if grep -q "your_jellyfin_api_key_here" "$INSTALL_DIR/config.yml"; then
        echo -e "${BLUE}📋 Next steps (Manual Configuration):${NC}"
        echo "1. Complete your configuration:"
        echo "   sudo nano $INSTALL_DIR/config.yml"
        echo ""
        echo "2. Test the configuration:"
        echo "   jellydemon test"
        echo ""
        echo "3. Start JellyDemon:"
        echo "   jellydemon start"
        echo ""
        echo "4. Enable auto-start on boot:"
        echo "   jellydemon enable"
        echo ""
        echo -e "${YELLOW}⚠️  Important: You must edit the configuration file before starting!${NC}"
        echo "Add your Jellyfin API key and adjust bandwidth settings."
    else
        echo -e "${BLUE}📋 Next steps (Configuration Complete):${NC}"
        echo "1. Test the configuration:"
        echo "   jellydemon test"
        echo ""
        echo "2. Start JellyDemon (dry-run mode enabled by default):"
        echo "   jellydemon start"
        echo ""
        echo "3. Monitor the logs to ensure everything works:"
        echo "   jellydemon logs"
        echo ""
        echo "4. Once satisfied, disable dry-run mode:"
        echo "   Edit config.yml and set 'dry_run: false'"
        echo "   jellydemon restart"
        echo ""
        echo "5. Enable auto-start on boot:"
        echo "   jellydemon enable"
        echo ""
        echo -e "${GREEN}🎯 Your configuration is complete and ready for testing!${NC}"
    fi
else
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Configure JellyDemon:"
    echo "   Run the configuration wizard: sudo -u $SERVICE_USER bash $INSTALL_DIR/configure.sh $INSTALL_DIR/config.yml"
    echo "   OR edit manually: sudo nano $INSTALL_DIR/config.yml"
    echo ""
    echo "2. Test and start as described above"
fi
echo ""
echo -e "${GREEN}📚 Documentation: https://github.com/freaked1234/jellydemon${NC}"

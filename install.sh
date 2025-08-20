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

# Check for required commands
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is required but not installed.${NC}"
        return 1
    fi
    return 0
}

# Install Python function
install_python() {
    echo ""
    echo -e "${BLUE}🐍 Python Installation${NC}"
    echo "Python 3.8+ is required for JellyDemon."
    echo ""
    read -p "Would you like to install Python automatically? [Y/n]: " install_python
    install_python=${install_python:-Y}
    
    if [[ $install_python =~ ^[Yy]$ ]]; then
        echo "🔧 Installing Python..."
        
        # Detect package manager and install Python
        if command -v apt &> /dev/null; then
            echo "📦 Using apt package manager..."
            sudo apt update
            sudo apt install -y python3 python3-pip python3-venv git curl
        elif command -v yum &> /dev/null; then
            echo "📦 Using yum package manager..."
            sudo yum install -y python3 python3-pip git curl
        elif command -v dnf &> /dev/null; then
            echo "📦 Using dnf package manager..."
            sudo dnf install -y python3 python3-pip git curl
        elif command -v pacman &> /dev/null; then
            echo "📦 Using pacman package manager..."
            sudo pacman -S --noconfirm python python-pip git curl
        elif command -v zypper &> /dev/null; then
            echo "📦 Using zypper package manager..."
            sudo zypper install -y python3 python3-pip git curl
        elif command -v apk &> /dev/null; then
            echo "📦 Using apk package manager..."
            sudo apk add --no-cache python3 py3-pip git curl
        else
            echo -e "${RED}❌ Could not detect package manager.${NC}"
            echo "Please install Python 3.8+ manually and re-run this installer."
            echo ""
            echo "Installation commands for common distributions:"
            echo "  Ubuntu/Debian: sudo apt install python3 python3-pip git curl"
            echo "  CentOS/RHEL:   sudo yum install python3 python3-pip git curl"
            echo "  Fedora:        sudo dnf install python3 python3-pip git curl"
            echo "  Arch Linux:    sudo pacman -S python python-pip git curl"
            echo "  Alpine:        sudo apk add python3 py3-pip git curl"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Python installation completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Please install Python 3.8+ manually and re-run this installer.${NC}"
        echo ""
        echo "Installation commands for common distributions:"
        echo "  Ubuntu/Debian: sudo apt install python3 python3-pip git curl"
        echo "  CentOS/RHEL:   sudo yum install python3 python3-pip git curl"
        echo "  Fedora:        sudo dnf install python3 python3-pip git curl"
        echo "  Arch Linux:    sudo pacman -S python python-pip git curl"
        echo "  Alpine:        sudo apk add python3 py3-pip git curl"
        exit 1
    fi
}

echo "🔍 Checking prerequisites..."

# Check for basic tools first
missing_tools=()
if ! check_command git; then
    missing_tools+=("git")
fi
if ! check_command curl; then
    missing_tools+=("curl")
fi
if ! check_command sudo; then
    missing_tools+=("sudo")
fi

# Install missing basic tools
if [ ${#missing_tools[@]} -gt 0 ]; then
    echo ""
    echo -e "${BLUE}🔧 Missing Tools Detection${NC}"
    echo "The following required tools are missing: ${missing_tools[*]}"
    echo ""
    read -p "Would you like to install these tools automatically? [Y/n]: " install_tools
    install_tools=${install_tools:-Y}
    
    if [[ $install_tools =~ ^[Yy]$ ]]; then
        echo "🔧 Installing missing tools..."
        
        # Detect package manager and install tools
        if command -v apt &> /dev/null; then
            sudo apt update
            sudo apt install -y ${missing_tools[*]}
        elif command -v yum &> /dev/null; then
            sudo yum install -y ${missing_tools[*]}
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y ${missing_tools[*]}
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm ${missing_tools[*]}
        elif command -v zypper &> /dev/null; then
            sudo zypper install -y ${missing_tools[*]}
        elif command -v apk &> /dev/null; then
            sudo apk add --no-cache ${missing_tools[*]}
        else
            echo -e "${RED}❌ Could not detect package manager.${NC}"
            echo "Please install these tools manually: ${missing_tools[*]}"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Tools installation completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Please install these tools manually: ${missing_tools[*]}${NC}"
        exit 1
    fi
fi

# Check for Python
if ! check_command python3; then
    install_python
fi

# Check for pip (might be separate package on some systems)
if ! check_command pip3 && ! python3 -m pip --version &>/dev/null; then
    echo -e "${YELLOW}⚠️  pip not found, installing...${NC}"
    if command -v apt &> /dev/null; then
        sudo apt install -y python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-pip
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3-pip
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm python-pip
    elif command -v zypper &> /dev/null; then
        sudo zypper install -y python3-pip
    elif command -v apk &> /dev/null; then
        sudo apk add --no-cache py3-pip
    else
        echo -e "${RED}❌ Could not install pip automatically.${NC}"
        echo "Please install pip manually and re-run this installer."
        exit 1
    fi
fi

# Check Python version
echo "🐍 Checking Python version..."
if python3 -c 'import sys; exit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    python_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✅ Python $python_version (compatible)${NC}"
else
    python_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "unknown")
    echo -e "${RED}❌ Python 3.8+ required (found $python_version)${NC}"
    echo ""
    echo "Your system has an older version of Python."
    echo "JellyDemon requires Python 3.8 or newer."
    echo ""
    read -p "Would you like to try installing a newer Python version? [Y/n]: " upgrade_python
    upgrade_python=${upgrade_python:-Y}
    
    if [[ $upgrade_python =~ ^[Yy]$ ]]; then
        install_python
        # Re-check after installation
        if python3 -c 'import sys; exit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
            python_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
            echo -e "${GREEN}✅ Python $python_version (compatible)${NC}"
        else
            echo -e "${RED}❌ Python version still incompatible after installation.${NC}"
            echo "You may need to install Python 3.8+ from source or use a different method."
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  Please upgrade Python to 3.8+ and re-run this installer.${NC}"
        exit 1
    fi
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

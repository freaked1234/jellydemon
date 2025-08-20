#!/bin/bash

# JellyDemon Uninstaller
# Usage: curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/uninstall.sh | bash

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

echo -e "${RED}🗑️  JellyDemon Uninstaller${NC}"
echo -e "${RED}========================${NC}"
echo ""

# Detect if running in pipe mode
if [ ! -t 0 ]; then
    echo -e "${YELLOW}⚠️  Detected non-interactive mode (piped from curl)${NC}"
    PIPE_MODE=true
else
    PIPE_MODE=false
fi

# Confirmation
echo -e "${YELLOW}⚠️  This will completely remove JellyDemon from your system.${NC}"
echo "This includes:"
echo "  - JellyDemon service and files"
echo "  - Configuration files (including your config.yml)"
echo "  - Log files"
echo "  - jellydemon user account"
echo ""

if [ "$PIPE_MODE" = true ]; then
    echo -e "${BLUE}🔄 Non-interactive mode: proceeding with uninstall${NC}"
    REPLY="y"
else
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
fi

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "🛑 Removing JellyDemon..."

# Stop and disable service (only if systemd is available)
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet jellydemon 2>/dev/null; then
        echo "🔄 Stopping JellyDemon service..."
        sudo systemctl stop jellydemon
    fi

    if systemctl is-enabled --quiet jellydemon 2>/dev/null; then
        echo "🔄 Disabling JellyDemon service..."
        sudo systemctl disable jellydemon
    fi

    # Remove systemd service file
    if [ -f "/etc/systemd/system/jellydemon.service" ]; then
        echo "🗂️  Removing systemd service..."
        sudo rm /etc/systemd/system/jellydemon.service
        sudo systemctl daemon-reload
    fi
else
    echo "⚠️  Systemd not available - skipping service management"
fi

# Remove management script
if [ -f "/usr/local/bin/jellydemon" ]; then
    echo "🗂️  Removing management script..."
    sudo rm /usr/local/bin/jellydemon
fi

# Backup configuration before removal
if [ -f "$INSTALL_DIR/config.yml" ]; then
    backup_file="$HOME/jellydemon-config-backup-$(date +%Y%m%d-%H%M%S).yml"
    echo "💾 Backing up configuration to $backup_file"
    cp "$INSTALL_DIR/config.yml" "$backup_file"
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo "📁 Removing installation directory..."
    sudo rm -rf "$INSTALL_DIR"
fi

# Remove user account
if id "$SERVICE_USER" &>/dev/null; then
    echo "👤 Removing jellydemon user..."
    sudo userdel "$SERVICE_USER"
fi

# Remove any remaining log files
if [ -f "/var/log/jellydemon.log" ]; then
    echo "📋 Removing log files..."
    sudo rm -f /var/log/jellydemon.log*
fi

echo ""
echo -e "${GREEN}✅ JellyDemon has been completely removed from your system.${NC}"
echo ""
if [ -f "$backup_file" ]; then
    echo -e "${BLUE}💾 Your configuration has been backed up to:${NC}"
    echo "   $backup_file"
    echo ""
fi
echo -e "${BLUE}🔄 To reinstall JellyDemon in the future:${NC}"
echo "   curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/install.sh | bash"
echo ""
echo "Thank you for using JellyDemon! 🎬"

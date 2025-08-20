#!/bin/bash

# Docker Quick Start Script for JellyDemon

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 JellyDemon Docker Quick Start${NC}"
echo -e "${BLUE}===============================${NC}"
echo ""

# Check for Docker and Docker Compose
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
    echo "Please install Docker from https://docker.com and try again."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed or not in PATH${NC}"
    echo "Please install Docker Compose and try again."
    exit 1
fi

echo -e "${GREEN}✅ Docker environment ready${NC}"

# Create directories
echo "📁 Creating directories..."
mkdir -p config logs data

# Download configuration files if they don't exist
if [ ! -f "docker-compose.yml" ]; then
    echo "📥 Downloading docker-compose.yml..."
    curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/docker-compose.yml -o docker-compose.yml
fi

if [ ! -f "config/config.yml" ]; then
    echo "📥 Downloading configuration template..."
    curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/config.example.yml -o config/config.yml
    
    echo ""
    echo -e "${BLUE}🎯 Configuration Setup${NC}"
    echo "We need to configure JellyDemon for your Jellyfin server."
    echo ""
    read -p "Would you like to configure JellyDemon interactively? [Y/n]: " configure_now
    configure_now=${configure_now:-Y}
    
    if [[ $configure_now =~ ^[Yy]$ ]]; then
        # Download and run configuration script
        echo "📥 Downloading configuration script..."
        curl -sSL https://raw.githubusercontent.com/freaked1234/jellydemon/main/configure.sh -o configure.sh
        chmod +x configure.sh
        
        echo "⚙️  Running interactive configuration..."
        bash configure.sh config/config.yml
        
        # Clean up
        rm configure.sh
    else
        echo -e "${YELLOW}⚠️  Please edit config/config.yml manually before starting${NC}"
        echo "Key settings to change:"
        echo "  - jellyfin.api_key: Your Jellyfin API key"
        echo "  - bandwidth.total_upload_mbps: Your upload bandwidth"
        echo "  - network.internal_ranges: Your local network ranges"
    fi
else
    echo -e "${YELLOW}⚠️  config/config.yml already exists${NC}"
fi

echo ""
echo -e "${GREEN}🚀 Starting JellyDemon with Docker Compose...${NC}"

# Start the containers
docker-compose up -d

echo ""
echo -e "${GREEN}🎉 JellyDemon is now running!${NC}"
echo ""
echo -e "${BLUE}💡 Useful commands:${NC}"
echo "  docker-compose logs -f      - View live logs"
echo "  docker-compose restart      - Restart JellyDemon"
echo "  docker-compose stop         - Stop JellyDemon"
echo "  docker-compose down         - Stop and remove containers"
echo ""
echo -e "${BLUE}📁 Directory structure:${NC}"
echo "  config/config.yml           - Configuration file"
echo "  logs/                       - Log files"
echo "  data/                       - Persistent data"
echo ""
echo -e "${BLUE}🔧 Configuration:${NC}"
echo "  Edit: config/config.yml"
echo "  Restart after changes: docker-compose restart"
echo ""

# Show logs
echo -e "${BLUE}📋 Recent logs:${NC}"
docker-compose logs --tail=10

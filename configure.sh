#!/bin/bash

# JellyDemon Interactive Configuration Setup
# Called by the main installer or can be run standalone

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ]; then
    CONFIG_FILE="config.yml"
fi

echo -e "${BLUE}⚙️  JellyDemon Configuration Setup${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""
echo "This setup will guide you through configuring JellyDemon for your Jellyfin server."
echo "You can always edit the configuration later by running: jellydemon config"
echo ""

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local explanation="$3"
    
    # Print explanation to stderr so it doesn't get captured
    echo -e "${CYAN}$explanation${NC}" >&2
    echo "" >&2
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        # Return only the clean value without any color codes
        printf "%s" "${value:-$default}"
    else
        read -p "$prompt: " value
        # Return only the clean value without any color codes
        printf "%s" "$value"
    fi
}

# Function to prompt for yes/no with default
prompt_yes_no() {
    local prompt="$1"
    local default="$2"
    local explanation="$3"
    
    echo -e "${CYAN}$explanation${NC}"
    echo ""
    
    while true; do
        if [ "$default" = "true" ]; then
            read -p "$prompt [Y/n]: " yn
            yn=${yn:-Y}
        else
            read -p "$prompt [y/N]: " yn
            yn=${yn:-N}
        fi
        
        case $yn in
            [Yy]* ) echo "true"; break;;
            [Nn]* ) echo "false"; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

echo -e "${YELLOW}📊 Step 1: Jellyfin Server Configuration${NC}"
echo "========================================"

JELLYFIN_HOST=$(prompt_with_default "Jellyfin Server IP/Hostname" "localhost" \
"Enter the IP address or hostname of your Jellyfin server.
If JellyDemon is running on the same machine as Jellyfin, use 'localhost'.
Examples: localhost, 192.168.1.100, jellyfin.mydomain.com")

JELLYFIN_PORT=$(prompt_with_default "Jellyfin Server Port" "8096" \
"Enter the port number your Jellyfin server is running on.
The default Jellyfin port is 8096. Only change this if you've customized your Jellyfin installation.")

echo ""
echo -e "${YELLOW}🔑 Step 2: Jellyfin API Key${NC}"
echo "============================="
echo -e "${CYAN}You need to create an API key in Jellyfin for JellyDemon to access your server.

How to get your API key:
1. Open your Jellyfin web interface
2. Go to Admin Dashboard → Advanced → API Keys
3. Click the '+' button to create a new API key
4. Name it 'JellyDemon' 
5. Copy the generated key and paste it below

The API key looks like: 1234567890abcdef1234567890abcdef${NC}"
echo ""

JELLYFIN_API_KEY=$(prompt_with_default "Jellyfin API Key" "" \
"Paste your Jellyfin API key here (required for JellyDemon to work)")

while [ -z "$JELLYFIN_API_KEY" ]; do
    echo -e "${RED}API key is required! Please create one in Jellyfin and enter it here.${NC}"
    JELLYFIN_API_KEY=$(prompt_with_default "Jellyfin API Key" "" "")
done

echo ""
echo -e "${YELLOW}🌐 Step 3: Network Configuration${NC}"
echo "=================================="

INTERNAL_RANGES=$(prompt_with_default "Internal IP Ranges" "192.168.0.0/16,10.0.0.0/8,172.16.0.0/12" \
"Define your internal/local network IP ranges. Users streaming from these IPs will NOT have bandwidth limits applied.
JellyDemon only manages bandwidth for EXTERNAL users (outside your home network).

Common home network ranges:
- 192.168.x.x networks (most home routers)
- 10.x.x.x networks (some routers) 
- 172.16-31.x.x networks (less common)

You can usually keep the default unless you have a custom network setup.")

echo ""
echo -e "${YELLOW}📶 Step 4: Bandwidth Configuration${NC}"
echo "==================================="

echo -e "${CYAN}🚀 IMPORTANT: Maximum Upload Bandwidth

Do a speed test (e.g., speedtest.net or fast.com) to check your maximum available UPLOAD bandwidth.
Subtract a reasonable amount for your other services and enter the remaining bandwidth in Mbps.

For example:
- If your upload speed is 50 Mbps, you might set this to 40 Mbps
- If your upload speed is 20 Mbps, you might set this to 15 Mbps

JellyDemon will dynamically allocate this bandwidth among all users currently streaming from outside your network.${NC}"
echo ""

TOTAL_UPLOAD_MBPS=$(prompt_with_default "Maximum Upload Bandwidth (Mbps)" "" \
"Enter your maximum upload bandwidth in Mbps (check with speedtest.net)")

# Simple validation - just check if it's a number and reasonable range
while true; do
    # Check if empty
    if [ -z "$TOTAL_UPLOAD_MBPS" ]; then
        echo -e "${RED}Please enter a number${NC}"
        TOTAL_UPLOAD_MBPS=$(prompt_with_default "Maximum Upload Bandwidth (Mbps)" "" "")
        continue
    fi
    
    # Simple check: is it a number?
    case "$TOTAL_UPLOAD_MBPS" in
        ''|*[!0-9.]*) 
            echo -e "${RED}Please enter a valid number (e.g., 25 or 25.5)${NC}"
            TOTAL_UPLOAD_MBPS=$(prompt_with_default "Maximum Upload Bandwidth (Mbps)" "" "")
            continue
            ;;
        *.*.*) 
            echo -e "${RED}Please enter a valid number (e.g., 25 or 25.5)${NC}"
            TOTAL_UPLOAD_MBPS=$(prompt_with_default "Maximum Upload Bandwidth (Mbps)" "" "")
            continue
            ;;
        *) 
            # It's a valid number format, accept it
            break
            ;;
    esac
done

BANDWIDTH_ALGORITHM=$(prompt_with_default "Bandwidth Algorithm" "equal_split" \
"Choose how to distribute bandwidth among external users:

1. 'equal_split' - Divide bandwidth equally among all external streamers
2. 'priority_based' - Give more bandwidth to admin users and premium accounts  
3. 'demand_based' - Allocate based on actual stream quality requirements

For most users, 'equal_split' works well and is the simplest option.

NOTE: Currently only 'equal_split' is fully supported. Other algorithms are planned for future releases.")

echo ""
echo -e "${YELLOW}⚙️  Step 5: Daemon Settings${NC}"
echo "============================"

DRY_RUN=$(prompt_yes_no "Enable Dry-Run Mode initially?" "true" \
"Dry-run mode lets you test JellyDemon without actually applying bandwidth limits to users.
Instead of making real changes, the daemon will log what changes it WOULD make to the log file.
This is recommended for first-time setup to verify everything works correctly and see what
actions would be taken before enabling live bandwidth management.
You can disable this later once you're confident it's working properly.")

ANONYMIZE_LOGS=$(prompt_yes_no "Enable Log Anonymization?" "true" \
"Log anonymization replaces usernames, IP addresses, and session IDs with anonymous identifiers.
This protects privacy when sharing logs for support or debugging.
Recommended: Keep enabled unless you specifically need real usernames in logs.")

echo ""
echo -e "${GREEN}✍️  Creating configuration file...${NC}"

# Create the configuration file
cat > "$CONFIG_FILE" << EOF
# JellyDemon Configuration
# Generated by interactive setup on $(date)

jellyfin:
  host: "$JELLYFIN_HOST"
  port: $JELLYFIN_PORT
  api_key: "$JELLYFIN_API_KEY"
  use_https: false

network:
  internal_ranges:
$(echo "$INTERNAL_RANGES" | sed 's/,/\n/g' | sed 's/^/    - "/' | sed 's/$/"/')

bandwidth:
  total_upload_mbps: $TOTAL_UPLOAD_MBPS
  algorithm: "$BANDWIDTH_ALGORITHM"
  
  # Algorithm-specific settings
  equal_split:
    min_per_user_mbps: 1.0
    
  priority_based:
    admin_multiplier: 2.0
    premium_multiplier: 1.5
    default_mbps: 3.0
    
  demand_based:
    quality_limits:
      "4K": 25.0
      "1080p": 8.0 
      "720p": 4.0
      "480p": 2.0

daemon:
  update_interval_seconds: 15
  dry_run: $DRY_RUN
  log_level: "INFO"
  log_file: "jellydemon.log"
  pid_file: "jellydemon.pid"
  
  # Privacy settings
  anonymize_logs: $ANONYMIZE_LOGS
  save_anonymization_map: true
  anonymization_map_file: "anonymization_map.json"
EOF

echo -e "${GREEN}✅ Configuration file created: $CONFIG_FILE${NC}"
echo ""
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo "  Jellyfin Server: $JELLYFIN_HOST:$JELLYFIN_PORT"
echo "  Max Bandwidth: $TOTAL_UPLOAD_MBPS Mbps"
echo "  Algorithm: $BANDWIDTH_ALGORITHM"
echo "  Update Interval: 15 seconds (fixed)"
echo "  Dry Run: $DRY_RUN"
echo "  Log Anonymization: $ANONYMIZE_LOGS"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
if [ "$DRY_RUN" = "true" ]; then
    echo "• Dry-run mode is ENABLED - no actual bandwidth limits will be applied"
    echo "• Test thoroughly, then edit config.yml and set 'dry_run: false'"
fi
echo "• You can edit the configuration anytime: jellydemon config"
echo "• Test your setup with: jellydemon test"
echo ""
echo -e "${GREEN}🎉 Configuration complete!${NC}"

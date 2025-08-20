#!/bin/bash

# JellyDemon Interactive Configuration Setup
# Called by the main installer or can be run standalone

set -euo pipefail
IFS=$'\n\t'

# Colors for output (TTY only)
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; NC=''
fi

CONFIG_FILE="${1:-config.yml}"

echo -e "${BLUE}⚙️  JellyDemon Configuration Setup${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""
echo "This setup will guide you through configuring JellyDemon for your Jellyfin server."
echo "You can always edit the configuration later by running: jellydemon config"
echo ""

# --- Helpers ---------------------------------------------------------------

strip_ansi_and_ctrl() {
  # strips ANSI escapes and trims CR/LF from a single line
  # stdin -> stdout
  sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' -e 's/[\x00-\x08\x0B\x0C\x0E-\x1F]//g'
}

prompt_with_default() {
  local prompt="$1" default="${2-}" explanation="${3-}" value=""
  # Print explanation to stderr so it doesn't get captured
  if [ -n "$explanation" ]; then
    echo -e "${CYAN}$explanation${NC}" >&2
    echo "" >&2
  fi
  if [ -n "$default" ]; then
    read -r -p "$prompt [$default]: " value
    printf "%s" "${value:-$default}" | strip_ansi_and_ctrl
  else
    read -r -p "$prompt: " value
    printf "%s" "$value" | strip_ansi_and_ctrl
  fi
}

prompt_yes_no() {
  local prompt="$1" default="${2-}" explanation="${3-}" yn=""
  if [ -n "$explanation" ]; then
    echo -e "${CYAN}$explanation${NC}" >&2
    echo "" >&2
  fi
  while true; do
    if [ "${default,,}" = "true" ]; then
      read -r -p "$prompt [Y/n]: " yn; yn=${yn:-Y}
    else
      read -r -p "$prompt [y/N]: " yn; yn=${yn:-N}
    fi
    case "$yn" in
      [Yy]* ) printf "true"; break;;
      [Nn]* ) printf "false"; break;;
      * ) echo "Please answer yes or no." >&2;;
    esac
  done
}

sanitize_file_inplace() {
  local f="$1"
  # Prefer dos2unix if available
  if command -v dos2unix >/dev/null 2>&1; then
    dos2unix -q "$f" || true
  else
    # Strip CR at EOL
    sed -i 's/\r$//' "$f"
  fi
  # Remove BOM, zero-width spaces, NBSP; keep ASCII printable + TAB + LF
  # If perl exists, do a precise sweep:
  if command -v perl >/dev/null 2>&1; then
    perl -CS -i -pe 's/\x{FEFF}//g; s/\x{200B}//g; s/\x{200C}//g; s/\x{200D}//g; s/\x{00A0}/ /g' "$f"
  fi
  # Final ASCII keep-filter (TAB 0x09, LF 0x0A, space..tilde):
  LC_ALL=C tr -cd '\11\12\40-\176' < "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
}

# --- Prompts ---------------------------------------------------------------

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

# Validation
while true; do
  if [ -z "$TOTAL_UPLOAD_MBPS" ]; then
    echo -e "${RED}Please enter a number${NC}"
    TOTAL_UPLOAD_MBPS=$(prompt_with_default "Maximum Upload Bandwidth (Mbps)" "" "")
    continue
  fi
  case "$TOTAL_UPLOAD_MBPS" in
    ''|*[!0-9.]*|*.*.*) 
      echo -e "${RED}Please enter a valid number (e.g., 25 or 25.5)${NC}"
      TOTAL_UPLOAD_MBPS=$(prompt_with_default "Maximum Upload Bandwidth (Mbps)" "" "")
      ;;
    *) break ;;
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

# Clean variables (defensive)
CLEAN_JELLYFIN_HOST=$(printf "%s" "$JELLYFIN_HOST" | strip_ansi_and_ctrl)
CLEAN_JELLYFIN_PORT=$(printf "%s" "$JELLYFIN_PORT" | strip_ansi_and_ctrl)
CLEAN_JELLYFIN_API_KEY=$(printf "%s" "$JELLYFIN_API_KEY" | strip_ansi_and_ctrl)
CLEAN_INTERNAL_RANGES=$(printf "%s" "$INTERNAL_RANGES" | strip_ansi_and_ctrl)
CLEAN_TOTAL_UPLOAD_MBPS=$(printf "%s" "$TOTAL_UPLOAD_MBPS" | strip_ansi_and_ctrl)
CLEAN_BANDWIDTH_ALGORITHM=$(printf "%s" "$BANDWIDTH_ALGORITHM" | strip_ansi_and_ctrl)
CLEAN_DRY_RUN=$(printf "%s" "$DRY_RUN" | strip_ansi_and_ctrl)
CLEAN_ANONYMIZE_LOGS=$(printf "%s" "$ANONYMIZE_LOGS" | strip_ansi_and_ctrl)

# Build internal_ranges block safely
build_ranges() {
  local csv="$1" IFS=','; read -r -a arr <<< "$csv"
  for net in "${arr[@]}"; do
    # trim spaces
    net="${net#"${net%%[![:space:]]*}"}"; net="${net%"${net##*[![:space:]]}"}"
    printf '    - "%s"\n' "$net"
  done
}

# Write YAML through a sanitizing pipe:
{
cat <<EOF
# JellyDemon Configuration
# Generated by interactive setup on $(date)

jellyfin:
  host: "$CLEAN_JELLYFIN_HOST"
  port: $CLEAN_JELLYFIN_PORT
  api_key: "$CLEAN_JELLYFIN_API_KEY"
  use_https: false

network:
  internal_ranges:
$(build_ranges "$CLEAN_INTERNAL_RANGES")
bandwidth:
  total_upload_mbps: $CLEAN_TOTAL_UPLOAD_MBPS
  algorithm: "$CLEAN_BANDWIDTH_ALGORITHM"

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
  dry_run: $CLEAN_DRY_RUN
  log_level: "INFO"
  log_file: "jellydemon.log"
  pid_file: "jellydemon.pid"

  # Privacy settings
  anonymize_logs: $CLEAN_ANONYMIZE_LOGS
  save_anonymization_map: true
  anonymization_map_file: "anonymization_map.json"
EOF
} | tr -d '\r' > "$CONFIG_FILE"

# Final sweep to nuke any weird bytes
sanitize_file_inplace "$CONFIG_FILE"

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

# Service management
echo -e "${YELLOW}🚀 Step 6: Service Management${NC}"
echo "============================="

if command -v systemctl >/dev/null 2>&1; then
  ENABLE_AUTOSTART=$(prompt_yes_no "Enable JellyDemon to start automatically on boot?" "true" \
"This will enable the JellyDemon systemd service to start automatically when your system boots.
Recommended for production setups where you want JellyDemon running continuously.")
  if [ "$ENABLE_AUTOSTART" = "true" ]; then
    echo "🔧 Enabling JellyDemon service for autostart..."
    if sudo systemctl enable jellydemon >/dev/null 2>&1; then
      echo -e "${GREEN}✅ JellyDemon will start automatically on boot${NC}"
    else
      echo -e "${YELLOW}⚠️  Could not enable autostart (may need to run: sudo systemctl enable jellydemon)${NC}"
    fi
  fi

  echo ""
  START_NOW=$(prompt_yes_no "Start JellyDemon service now?" "true" \
"This will start the JellyDemon service immediately so you can test your configuration.
You can always start/stop it later with: jellydemon start/stop")
  if [ "$START_NOW" = "true" ]; then
    echo "🚀 Starting JellyDemon service..."
    if sudo systemctl start jellydemon >/dev/null 2>&1; then
      echo -e "${GREEN}✅ JellyDemon service started successfully${NC}"
      echo ""
      echo "🔍 Service status:"
      sudo systemctl --no-pager status jellydemon
    else
      echo -e "${RED}❌ Failed to start JellyDemon service${NC}"
      echo "You can try starting it manually with: sudo systemctl start jellydemon"
      echo "Check logs with: sudo journalctl -u jellydemon -f"
    fi
  fi
else
  echo -e "${YELLOW}⚠️  Systemd not available - service management not supported${NC}"
  echo "To start JellyDemon manually, run: jellydemon start"
fi

echo ""
echo -e "${GREEN}🎉 Configuration complete!${NC}"

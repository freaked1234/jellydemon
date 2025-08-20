# JellyDemon Interactive Configuration Setup for Windows
# Called by the main installer or can be run standalone

param(
    [string]$ConfigFile = "config.yml"
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Cyan = "`e[36m"
$Reset = "`e[0m"

Write-Host "${Blue}⚙️  JellyDemon Configuration Setup${Reset}"
Write-Host "${Blue}===================================${Reset}"
Write-Host ""
Write-Host "This setup will guide you through configuring JellyDemon for your Jellyfin server."
Write-Host "You can always edit the configuration later."
Write-Host ""

# Function to prompt for input with default
function Prompt-WithDefault {
    param(
        [string]$Prompt,
        [string]$Default,
        [string]$Explanation
    )
    
    Write-Host "${Cyan}$Explanation${Reset}"
    Write-Host ""
    
    if ($Default) {
        $input = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($input)) {
            return $Default
        }
        return $input
    } else {
        do {
            $input = Read-Host $Prompt
        } while ([string]::IsNullOrWhiteSpace($input))
        return $input
    }
}

# Function to prompt for yes/no with default
function Prompt-YesNo {
    param(
        [string]$Prompt,
        [bool]$Default,
        [string]$Explanation
    )
    
    Write-Host "${Cyan}$Explanation${Reset}"
    Write-Host ""
    
    do {
        if ($Default) {
            $input = Read-Host "$Prompt [Y/n]"
            if ([string]::IsNullOrWhiteSpace($input)) { $input = "Y" }
        } else {
            $input = Read-Host "$Prompt [y/N]"
            if ([string]::IsNullOrWhiteSpace($input)) { $input = "N" }
        }
        
        switch ($input.ToUpper()) {
            "Y" { return $true }
            "YES" { return $true }
            "N" { return $false }
            "NO" { return $false }
            default { Write-Host "Please answer yes or no." }
        }
    } while ($true)
}

Write-Host "${Yellow}📊 Step 1: Jellyfin Server Configuration${Reset}"
Write-Host "========================================"

$jellyfinHost = Prompt-WithDefault -Prompt "Jellyfin Server IP/Hostname" -Default "localhost" -Explanation @"
Enter the IP address or hostname of your Jellyfin server.
If JellyDemon is running on the same machine as Jellyfin, use 'localhost'.
Examples: localhost, 192.168.1.100, jellyfin.mydomain.com
"@

$jellyfinPort = Prompt-WithDefault -Prompt "Jellyfin Server Port" -Default "8096" -Explanation @"
Enter the port number your Jellyfin server is running on.
The default Jellyfin port is 8096. Only change this if you've customized your Jellyfin installation.
"@

Write-Host ""
Write-Host "${Yellow}🔑 Step 2: Jellyfin API Key${Reset}"
Write-Host "============================="

Write-Host "${Cyan}You need to create an API key in Jellyfin for JellyDemon to access your server.

How to get your API key:
1. Open your Jellyfin web interface
2. Go to Admin Dashboard → Advanced → API Keys
3. Click the '+' button to create a new API key
4. Name it 'JellyDemon' 
5. Copy the generated key and paste it below

The API key looks like: 1234567890abcdef1234567890abcdef${Reset}"
Write-Host ""

do {
    $jellyfinApiKey = Read-Host "Jellyfin API Key"
    if ([string]::IsNullOrWhiteSpace($jellyfinApiKey)) {
        Write-Host "${Red}API key is required! Please create one in Jellyfin and enter it here.${Reset}"
    }
} while ([string]::IsNullOrWhiteSpace($jellyfinApiKey))

Write-Host ""
Write-Host "${Yellow}🌐 Step 3: Network Configuration${Reset}"
Write-Host "=================================="

$internalRanges = Prompt-WithDefault -Prompt "Internal IP Ranges" -Default "192.168.0.0/16,10.0.0.0/8,172.16.0.0/12" -Explanation @"
Define your internal/local network IP ranges. Users streaming from these IPs will NOT have bandwidth limits applied.
JellyDemon only manages bandwidth for EXTERNAL users (outside your home network).

Common home network ranges:
- 192.168.x.x networks (most home routers)
- 10.x.x.x networks (some routers) 
- 172.16-31.x.x networks (less common)

You can usually keep the default unless you have a custom network setup.
"@

Write-Host ""
Write-Host "${Yellow}📶 Step 4: Bandwidth Configuration${Reset}"
Write-Host "==================================="

$totalUploadMbps = ""
do {
    $totalUploadMbps = Prompt-WithDefault -Prompt "Maximum Upload Bandwidth (Mbps)" -Default "" -Explanation @"
🚀 IMPORTANT: Maximum Upload Bandwidth

Do a speed test (e.g., speedtest.net or fast.com) to check your maximum available UPLOAD bandwidth.
Subtract a reasonable amount for your other services and enter the remaining bandwidth in Mbps.

For example:
- If your upload speed is 50 Mbps, you might set this to 40 Mbps
- If your upload speed is 20 Mbps, you might set this to 15 Mbps

JellyDemon will dynamically allocate this bandwidth among all users currently streaming from outside your network.
"@
    
    if (-not ($totalUploadMbps -match '^\d+(\.\d+)?$')) {
        Write-Host "${Red}Please enter a valid number for bandwidth (e.g., 25 or 25.5)${Reset}"
        $totalUploadMbps = ""
    }
} while ([string]::IsNullOrWhiteSpace($totalUploadMbps))

$bandwidthAlgorithm = Prompt-WithDefault -Prompt "Bandwidth Algorithm" -Default "equal_split" -Explanation @"
Choose how to distribute bandwidth among external users:

1. 'equal_split' - Divide bandwidth equally among all external streamers
2. 'priority_based' - Give more bandwidth to admin users and premium accounts  
3. 'demand_based' - Allocate based on actual stream quality requirements

For most users, 'equal_split' works well and is the simplest option.

NOTE: Currently only 'equal_split' is fully supported. Other algorithms are planned for future releases.
"@

Write-Host ""
Write-Host "${Yellow}⚙️  Step 5: Daemon Settings${Reset}"
Write-Host "============================"

$dryRun = Prompt-YesNo -Prompt "Enable Dry-Run Mode initially?" -Default $true -Explanation @"
Dry-run mode lets you test JellyDemon without actually applying bandwidth limits to users.
Instead of making real changes, the daemon will log what changes it WOULD make to the log file.
This is recommended for first-time setup to verify everything works correctly and see what
actions would be taken before enabling live bandwidth management.
You can disable this later once you're confident it's working properly.
"@

$anonymizeLogs = Prompt-YesNo -Prompt "Enable Log Anonymization?" -Default $true -Explanation @"
Log anonymization replaces usernames, IP addresses, and session IDs with anonymous identifiers.
This protects privacy when sharing logs for support or debugging.
Recommended: Keep enabled unless you specifically need real usernames in logs.
"@

Write-Host ""
Write-Host "${Green}✍️  Creating configuration file...${Reset}"

# Create the configuration file
$configContent = @"
# JellyDemon Configuration
# Generated by interactive setup on $(Get-Date)

jellyfin:
  host: "$jellyfinHost"
  port: $jellyfinPort
  api_key: "$jellyfinApiKey"
  use_https: false

network:
  internal_ranges:
$($internalRanges -split ',' | ForEach-Object { "    - `"$($_.Trim())`"" } | Out-String)

bandwidth:
  total_upload_mbps: $totalUploadMbps
  algorithm: "$bandwidthAlgorithm"
  
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
  dry_run: $($dryRun.ToString().ToLower())
  log_level: "INFO"
  log_file: "jellydemon.log"
  pid_file: "jellydemon.pid"
  
  # Privacy settings
  anonymize_logs: $($anonymizeLogs.ToString().ToLower())
  save_anonymization_map: true
  anonymization_map_file: "anonymization_map.json"
"@

$configContent | Out-File -FilePath $ConfigFile -Encoding UTF8

Write-Host "${Green}✅ Configuration file created: $ConfigFile${Reset}"
Write-Host ""
Write-Host "${Blue}📋 Configuration Summary:${Reset}"
Write-Host "  Jellyfin Server: $jellyfinHost`:$jellyfinPort"
Write-Host "  Max Bandwidth: $totalUploadMbps Mbps"
Write-Host "  Algorithm: $bandwidthAlgorithm"
Write-Host "  Update Interval: 15 seconds (fixed)"
Write-Host "  Dry Run: $dryRun"
Write-Host "  Log Anonymization: $anonymizeLogs"
Write-Host ""
Write-Host "${Yellow}⚠️  Important Notes:${Reset}"
if ($dryRun) {
    Write-Host "• Dry-run mode is ENABLED - no actual bandwidth limits will be applied"
    Write-Host "• Test thoroughly, then edit config.yml and set 'dry_run: false'"
}
Write-Host "• You can edit the configuration anytime with notepad $ConfigFile"
Write-Host "• Test your setup with the test batch file"
Write-Host ""
Write-Host "${Green}🎉 Configuration complete!${Reset}"

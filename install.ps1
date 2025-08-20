# JellyDemon Windows Installer
# Usage: iwr -useb https://raw.githubusercontent.com/freaked1234/jellydemon/main/install.ps1 | iex

param(
    [string]$InstallPath = "$env:ProgramFiles\JellyDemon",
    [switch]$Force
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

Write-Host "${Blue}🎬 JellyDemon Windows Installer${Reset}"
Write-Host "${Blue}===============================${Reset}"
Write-Host ""

# Function to install Python
function Install-Python {
    Write-Host ""
    Write-Host "${Blue}🐍 Python Installation${Reset}"
    Write-Host "Python 3.8+ is required for JellyDemon."
    Write-Host ""
    
    # Check if winget is available
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $installChoice = Read-Host "Would you like to install Python automatically using winget? [Y/n]"
        if ($installChoice -eq "" -or $installChoice -match "^[Yy]") {
            Write-Host "🔧 Installing Python using winget..."
            try {
                winget install Python.Python.3.11 --accept-package-agreements --accept-source-agreements
                Write-Host "${Green}✅ Python installation completed${Reset}"
                Write-Host "Please restart PowerShell and re-run this installer."
                Write-Host "The PATH may need to be refreshed for Python to be available."
                exit 0
            } catch {
                Write-Host "${Red}❌ Failed to install Python with winget${Reset}"
                Show-ManualInstallInstructions
            }
        } else {
            Show-ManualInstallInstructions
        }
    } else {
        Write-Host "${Yellow}⚠️  winget not available for automatic installation${Reset}"
        Show-ManualInstallInstructions
    }
}

function Show-ManualInstallInstructions {
    Write-Host ""
    Write-Host "${Yellow}📥 Manual Python Installation${Reset}"
    Write-Host "Please install Python manually:"
    Write-Host "1. Visit: https://python.org/downloads/"
    Write-Host "2. Download Python 3.8 or newer"
    Write-Host "3. Run the installer and check 'Add Python to PATH'"
    Write-Host "4. Restart PowerShell and re-run this installer"
    Write-Host ""
    Write-Host "Alternative methods:"
    Write-Host "- Chocolatey: choco install python"
    Write-Host "- Scoop: scoop install python"
    Write-Host "- Microsoft Store: Search for 'Python 3.11'"
    exit 1
}

# Check for Python
Write-Host "🔍 Checking prerequisites..."
try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python (\d+)\.(\d+)") {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        if ($major -ge 3 -and $minor -ge 8) {
            Write-Host "${Green}✅ $pythonVersion (compatible)${Reset}"
        } else {
            Write-Host "${Red}❌ Python 3.8+ required (found $pythonVersion)${Reset}"
            Write-Host ""
            $upgradeChoice = Read-Host "Would you like to upgrade Python? [Y/n]"
            if ($upgradeChoice -eq "" -or $upgradeChoice -match "^[Yy]") {
                Install-Python
            } else {
                Show-ManualInstallInstructions
            }
        }
    } else {
        Write-Host "${Red}❌ Could not determine Python version${Reset}"
        Install-Python
    }
} catch {
    Write-Host "${Red}❌ Python not found${Reset}"
    Install-Python
}

# Check for pip
Write-Host "🔍 Checking pip..."
try {
    $pipVersion = python -m pip --version 2>&1
    if ($pipVersion -match "pip") {
        Write-Host "${Green}✅ pip available${Reset}"
    } else {
        Write-Host "${Yellow}⚠️  Installing pip...${Reset}"
        python -m ensurepip --upgrade
    }
} catch {
    Write-Host "${Yellow}⚠️  pip not found, trying to install...${Reset}"
    try {
        python -m ensurepip --upgrade
        Write-Host "${Green}✅ pip installed${Reset}"
    } catch {
        Write-Host "${Red}❌ Could not install pip${Reset}"
        Write-Host "Please install pip manually and re-run this installer."
        exit 1
    }
}

# Check for Git
try {
    git --version | Out-Null
    Write-Host "${Green}✅ Git found${Reset}"
} catch {
    Write-Host "${Red}❌ Git not found${Reset}"
    Write-Host "Please install Git from https://git-scm.com"
    exit 1
}

# Create installation directory
Write-Host "📁 Creating installation directory..."
if (Test-Path $InstallPath) {
    if ($Force) {
        Remove-Item -Path $InstallPath -Recurse -Force
    } else {
        Write-Host "${Yellow}⚠️  Installation directory already exists${Reset}"
        $response = Read-Host "Remove existing installation? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Remove-Item -Path $InstallPath -Recurse -Force
        } else {
            Write-Host "Installation cancelled."
            exit 1
        }
    }
}

New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null

# Clone repository
Write-Host "📥 Downloading JellyDemon..."
git clone https://github.com/freaked1234/jellydemon.git $InstallPath

# Install Python dependencies
Write-Host "📦 Installing Python dependencies..."
Set-Location $InstallPath
python -m pip install -r requirements.txt

# Interactive configuration setup
Write-Host "⚙️  Setting up configuration..."
if (-not (Test-Path "config.yml")) {
    Write-Host ""
    Write-Host "${Blue}🎯 Interactive Configuration Setup${Reset}"
    Write-Host "We'll now configure JellyDemon for your Jellyfin server."
    Write-Host "This will only take a few minutes and you can change everything later."
    Write-Host ""
    
    $configureNow = Read-Host "Would you like to configure JellyDemon now? [Y/n]"
    if ([string]::IsNullOrWhiteSpace($configureNow)) { $configureNow = "Y" }
    
    if ($configureNow -match '^[Yy]') {
        # Run interactive configuration
        & "$InstallPath\configure.ps1" -ConfigFile "$InstallPath\config.yml"
    } else {
        # Create from example for manual configuration
        Copy-Item "config.example.yml" "config.yml"
        Write-Host "${Yellow}⚠️  Created config.yml from example - you'll need to edit it manually${Reset}"
        Write-Host "Edit with: notepad `"$InstallPath\config.yml`""
    }
} else {
    Write-Host "${Yellow}⚠️  config.yml already exists, skipping configuration${Reset}"
}

# Create Windows service wrapper
Write-Host "🔧 Setting up Windows service..."
$serviceScript = @"
import sys
import os
import subprocess
from pathlib import Path

# Change to JellyDemon directory
os.chdir(r'$InstallPath')

# Run JellyDemon
subprocess.run([sys.executable, 'jellydemon.py'])
"@

$serviceScript | Out-File -FilePath "$InstallPath\jellydemon_service.py" -Encoding UTF8

# Create batch files for management
$startScript = @"
@echo off
cd /d "$InstallPath"
python jellydemon.py
pause
"@

$startScript | Out-File -FilePath "$InstallPath\start_jellydemon.bat" -Encoding ASCII

$testScript = @"
@echo off
cd /d "$InstallPath"
python jellydemon.py --test
pause
"@

$testScript | Out-File -FilePath "$InstallPath\test_jellydemon.bat" -Encoding ASCII

$shareLogsScript = @"
@echo off
cd /d "$InstallPath"
echo Sharing recent logs for support...
python jellydemon.py --share-logs
pause
"@

$shareLogsScript | Out-File -FilePath "$InstallPath\share_logs.bat" -Encoding ASCII

# Create PowerShell management script
$psScript = @"
# JellyDemon Management Script for Windows
param([string]`$Action)

`$InstallPath = "$InstallPath"
Set-Location `$InstallPath

switch (`$Action) {
    "start" {
        Write-Host "Starting JellyDemon..."
        python jellydemon.py
    }
    "test" {
        Write-Host "Testing JellyDemon configuration..."
        python jellydemon.py --test
    }
    "health" {
        Write-Host "🏥 Running JellyDemon health check..."
        python health_check.py
    }
    "share-logs" {
        Write-Host "📤 Sharing recent logs for support..."
        python jellydemon.py --share-logs
    }
    "config" {
        Write-Host "Opening configuration file..."
        notepad config.yml
    }
    default {
        Write-Host "Usage: jellydemon.ps1 {start|test|health|share-logs|config}"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  start       - Start JellyDemon service"
        Write-Host "  test        - Test configuration"
        Write-Host "  health      - Run system health check"
        Write-Host "  share-logs  - Share logs for support"
        Write-Host "  config      - Edit configuration"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  start      - Start JellyDemon"
        Write-Host "  test       - Test configuration"
        Write-Host "  share-logs - Upload recent logs to pastebin for support"
        Write-Host "  config     - Edit configuration"
    }
}
"@

$psScript | Out-File -FilePath "$InstallPath\jellydemon.ps1" -Encoding UTF8

# Add to PATH (optional)
Write-Host "🛠️  Setting up management tools..."
$pathToAdd = $InstallPath
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($currentPath -notlike "*$pathToAdd*") {
    $newPath = $currentPath + ";" + $pathToAdd
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
    Write-Host "${Green}✅ Added JellyDemon to system PATH${Reset}"
}

# Create desktop shortcut (optional)
$response = Read-Host "Create desktop shortcut? (Y/n)"
if ($response -ne 'n' -and $response -ne 'N') {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\JellyDemon.lnk")
    $Shortcut.TargetPath = "$InstallPath\start_jellydemon.bat"
    $Shortcut.WorkingDirectory = $InstallPath
    $Shortcut.Description = "JellyDemon - Jellyfin Bandwidth Management"
    $Shortcut.Save()
    Write-Host "${Green}✅ Desktop shortcut created${Reset}"
}

Write-Host ""
Write-Host "${Green}🎉 Installation completed successfully!${Reset}"
Write-Host ""

# Show different next steps based on whether configuration was completed
if (Test-Path "$InstallPath\config.yml") {
    # Check if it looks like it was configured (not just copied from example)
    $configContent = Get-Content "$InstallPath\config.yml" -Raw
    if ($configContent -match "your_jellyfin_api_key_here") {
        Write-Host "${Blue}📋 Next steps (Manual Configuration):${Reset}"
        Write-Host "1. Complete your configuration:"
        Write-Host "   notepad `"$InstallPath\config.yml`""
        Write-Host ""
        Write-Host "2. Test the configuration:"
        Write-Host "   `"$InstallPath\test_jellydemon.bat`""
        Write-Host ""
        Write-Host "3. Start JellyDemon:"
        Write-Host "   `"$InstallPath\start_jellydemon.bat`""
        Write-Host ""
        Write-Host "${Yellow}⚠️  Important: You must edit the configuration file before starting!${Reset}"
        Write-Host "Add your Jellyfin API key and adjust bandwidth settings."
    } else {
        Write-Host "${Blue}📋 Next steps (Configuration Complete):${Reset}"
        Write-Host "1. Test the configuration:"
        Write-Host "   `"$InstallPath\test_jellydemon.bat`""
        Write-Host ""
        Write-Host "2. Start JellyDemon (dry-run mode enabled by default):"
        Write-Host "   `"$InstallPath\start_jellydemon.bat`""
        Write-Host ""
        Write-Host "3. Once satisfied, disable dry-run mode:"
        Write-Host "   Edit config.yml and set 'dry_run: false'"
        Write-Host ""
        Write-Host "${Green}🎯 Your configuration is complete and ready for testing!${Reset}"
    }
} else {
    Write-Host "${Blue}📋 Next steps:${Reset}"
    Write-Host "1. Configure JellyDemon:"
    Write-Host "   Run: PowerShell -File `"$InstallPath\configure.ps1`" -ConfigFile `"$InstallPath\config.yml`""
    Write-Host "   OR edit manually: notepad `"$InstallPath\config.yml`""
    Write-Host ""
    Write-Host "2. Test and start as described above"
}
Write-Host ""
Write-Host "${Green}📚 Documentation: https://github.com/freaked1234/jellydemon${Reset}"

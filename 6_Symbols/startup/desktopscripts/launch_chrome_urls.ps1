# PowerShell Script to Launch Chrome with Specific Profile and Open URLs
# Purpose: Open Chrome with a specific profile and navigate to Telegram and Gemini URLs
# Date: $(Get-Date -Format "yyyy-MM-dd")
# Version: 1.0

# Set error handling
$ErrorActionPreference = "Continue"

# Configuration
$Config = @{
    ChromePath    = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    ChromeProfile = "--profile-directory=`"Profile 21`""  # Adjust profile number as needed
    LogFile       = "$env:USERPROFILE\Desktop\StartupLog\TelegramGemini_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    URLs          = @(
        "https://web.telegram.org/a/#-1002793496878",
        "https://gemini.google.com/u/1/app/ce5464009e31da55?pageId=none",
        "https://accounts.intuit.com/app/sign-in?app_group=QBO&asset_alias=Intuit.accounting.core.qbowebapp&app_environment=prod",
        "https://mail.google.com/mail/u/0/#inbox",
        "https://www.linkedin.com/messaging/thread/2-YmYyNzM1Y2EtY2M0Yy00OTg2LWJkMzgtNGI4NjhhNTc1MDIyXzEwMA==/",
        "https://x.com/i/grok",
        "https://fal.ai/dashboard",
        "https://calendar.google.com/calendar/u/0/r",
        "https://deliverypilot.net/5_Symbols/pricing.html",
        "https://n8n.rifaterdemsahin.com/settings/mcp",
        "https://colab.research.google.com/github/rifaterdemsahin/The-Complete-Security-Lifecycle/blob/main/5_Symbols/lifecycle_demo.ipynb?authuser=1#scrollTo=FTz2C56iaG5S",
        "https://claude.ai/chat/3ee0d1d7-34e8-47e0-ba45-74c1a3346ac9",
        "https://elevenlabs.io/app/studio/p7m9RUs7xmlphEslgAnV?chapterId=awT2lWRjfjFutjuPzMuU",
        "https://select-tech.evertime.co.uk/Account/Login?ReturnUrl=%2FTimesheet#undefined",
        "https://www.coursera.org/instructor/~184662540",
        "https://grok.com/share/c2hhcmQtNA_952b9c41-f150-4a7a-a204-7312dd40b25f?rid=64990627-645a-4195-ac63-22eba710332c",
        "https://openrouter.ai/models",
        "https://huggingface.co/models",
        "https://www.speedtest.net/result/18645473959",
        "https://calendly.com/rifaterdemsahin",
        "https://192.168.3.1/#Security/Firewall/Policies"
    )
}

# Ensure log directory exists
try {
    $logDir = Split-Path -Parent $Config.LogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        Write-Host "Created log directory: $logDir" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error creating log directory: $_" -ForegroundColor Red
    $Config.LogFile = "$env:TEMP\TelegramGemini_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
}

# Logging function
function Write-Log {
    param ([string]$Message)
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $Config.LogFile -Append -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
    }
    Write-Host $Message
}

# Function to launch Chrome with specific profile and URLs
function Launch-ChromeWithProfile {
    try {
        Write-Log "Starting Chrome launch process..."
        
        # Check if Chrome exists
        if (-not (Test-Path $Config.ChromePath)) {
            Write-Log "Chrome not found at: $($Config.ChromePath)"
            
            # Try alternative Chrome paths
            $possiblePaths = @(
                "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
            )
            
            foreach ($path in $possiblePaths) {
                if (Test-Path $path) {
                    Write-Log "Found Chrome at: $path"
                    $Config.ChromePath = $path
                    break
                }
            }
            
            if (-not (Test-Path $Config.ChromePath)) {
                Write-Log "Chrome not found in any standard location. Please install Chrome or update the path."
                return $false
            }
        }
        
        # Launch Chrome with profile and URLs
        Write-Log "Launching Chrome with profile: $($Config.ChromeProfile)"
        
        foreach ($url in $Config.URLs) {
            try {
                Write-Log "Opening URL: $url"
                
                # Launch Chrome with specific profile and URL
                $chromeArgs = @($Config.ChromeProfile, $url)
                Start-Process -FilePath $Config.ChromePath -ArgumentList $chromeArgs
                
                # Small delay between launches to prevent overwhelming the system
                Start-Sleep -Milliseconds 1000
                
                Write-Log "Successfully launched: $url"
            }
            catch {
                Write-Log "Failed to launch URL $url : $_"
            }
        }
        
        Write-Log "Chrome launch process completed successfully"
        return $true
        
    }
    catch {
        Write-Log "Error in Launch-ChromeWithProfile: $_"
        return $false
    }
}

# Function to verify Chrome profile exists
function Test-ChromeProfile {
    try {
        $profilePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\$($Config.ChromeProfile -replace '--profile-directory=`"', '' -replace '`"', '')"
        Write-Log "Checking for Chrome profile at: $profilePath"
        
        if (Test-Path $profilePath) {
            Write-Log "Chrome profile found: $profilePath"
            return $true
        }
        else {
            Write-Log "Chrome profile not found. Using default profile."
            $Config.ChromeProfile = ""
            return $false
        }
    }
    catch {
        Write-Log "Error checking Chrome profile: $_"
        return $false
    }
}

# Function to wait for Chrome to be ready
function Wait-ForChrome {
    param([int]$TimeoutSeconds = 30)
    
    try {
        Write-Log "Waiting for Chrome to be ready..."
        $timeout = (Get-Date).AddSeconds($TimeoutSeconds)
        
        while ((Get-Date) -lt $timeout) {
            $chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
            if ($chromeProcesses) {
                Write-Log "Chrome processes detected: $($chromeProcesses.Count)"
                return $true
            }
            Start-Sleep -Milliseconds 500
        }
        
        Write-Log "Timeout waiting for Chrome to start"
        return $false
    }
    catch {
        Write-Log "Error waiting for Chrome: $_"
        return $false
    }
}

# Main execution
try {
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "🚀 Telegram & Gemini Chrome Launcher" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Cyan
    
    Write-Log "Script started at $(Get-Date)"
    
    # Test Chrome profile
    Test-ChromeProfile
    
    # Launch Chrome with profile and URLs
    $success = Launch-ChromeWithProfile
    
    if ($success) {
        # Wait for Chrome to be ready
        Wait-ForChrome
        
        Write-Host "`n=======================================" -ForegroundColor Green
        Write-Host "✅ Chrome launched successfully!" -ForegroundColor Green
        Write-Host "✅ URLs opened:" -ForegroundColor Green
        foreach ($url in $Config.URLs) {
            Write-Host "   • $url" -ForegroundColor White
        }
        Write-Host "=======================================" -ForegroundColor Green
    }
    else {
        Write-Host "`n=======================================" -ForegroundColor Red
        Write-Host "❌ Failed to launch Chrome" -ForegroundColor Red
        Write-Host "=======================================" -ForegroundColor Red
    }
    
    Write-Log "Script completed at $(Get-Date)"
    
}
catch {
    Write-Host "`n=======================================" -ForegroundColor Red
    Write-Host "❌ Script encountered an error!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=======================================" -ForegroundColor Red
    Write-Log "Script error: $_"
}

# Keep window open for a moment to show results
Write-Host "`nPress Enter to close..." -ForegroundColor Yellow
Read-Host | Out-Null

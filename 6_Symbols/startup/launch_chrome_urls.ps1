# PowerShell Script to Launch Chrome with Specific Profile and Open URLs
# Purpose: Open Chrome with a specific profile and navigate to Telegram and Gemini URLs
# Date: $(Get-Date -Format "yyyy-MM-dd")
# Version: 1.0

# Set error handling
$ErrorActionPreference = "Continue"

# Configuration
$Config = @{
    ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    ChromeProfile = "--profile-directory=`"Profile 21`""  # Adjust profile number as needed
    LogFile = "$env:USERPROFILE\Desktop\StartupLog\TelegramGemini_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    URLs = @(
        "https://web.telegram.org/a/#-1002793496878",
        "https://gemini.google.com/app/a4012a0daa4ad70d"
    )
}

# Ensure log directory exists
try {
    $logDir = Split-Path -Parent $Config.LogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        Write-Host "Created log directory: $logDir" -ForegroundColor Green
    }
} catch {
    Write-Host "Error creating log directory: $_" -ForegroundColor Red
    $Config.LogFile = "$env:TEMP\TelegramGemini_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
}

# Logging function
function Write-Log {
    param ([string]$Message)
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $Config.LogFile -Append -ErrorAction SilentlyContinue
    } catch {
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
            } catch {
                Write-Log "Failed to launch URL $url : $_"
            }
        }
        
        Write-Log "Chrome launch process completed successfully"
        return $true
        
    } catch {
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
        } else {
            Write-Log "Chrome profile not found. Using default profile."
            $Config.ChromeProfile = ""
            return $false
        }
    } catch {
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
    } catch {
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
    } else {
        Write-Host "`n=======================================" -ForegroundColor Red
        Write-Host "❌ Failed to launch Chrome" -ForegroundColor Red
        Write-Host "=======================================" -ForegroundColor Red
    }
    
    Write-Log "Script completed at $(Get-Date)"
    
} catch {
    Write-Host "`n=======================================" -ForegroundColor Red
    Write-Host "❌ Script encountered an error!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=======================================" -ForegroundColor Red
    Write-Log "Script error: $_"
}

# Keep window open for a moment to show results
Write-Host "`nPress Enter to close..." -ForegroundColor Yellow
Read-Host | Out-Null

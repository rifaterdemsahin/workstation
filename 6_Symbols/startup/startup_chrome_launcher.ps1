# PowerShell Script for Windows Startup - Chrome URL Launcher
# Purpose: Run at Windows startup to launch Chrome with specific profile and URLs
# Date: $(Get-Date -Format "yyyy-MM-dd")
# Version: 1.0

# Set error handling
$ErrorActionPreference = "Continue"

# Configuration
$Config = @{
    ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    ChromeProfile = "--profile-directory=`"Profile 21`""  # Adjust profile number as needed
    LogFile = "$env:USERPROFILE\Desktop\StartupLog\ChromeLauncher_Startup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    URLs = @(
        "https://web.telegram.org/a/#-1002793496878",
        "https://gemini.google.com/app/a4012a0daa4ad70d"
    )
    StartupDelay = 30  # Wait 30 seconds after Windows startup
}

# Ensure log directory exists
try {
    $logDir = Split-Path -Parent $Config.LogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
} catch {
    $Config.LogFile = "$env:TEMP\ChromeLauncher_Startup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
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

# Function to wait for system to be ready
function Wait-ForSystemReady {
    try {
        Write-Log "Waiting for system to be ready after startup..."
        
        # Wait for network connectivity
        $networkReady = $false
        $attempts = 0
        $maxAttempts = 30
        
        while (-not $networkReady -and $attempts -lt $maxAttempts) {
            try {
                $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction Stop
                if ($ping) {
                    $networkReady = $true
                    Write-Log "Network connectivity confirmed"
                }
            } catch {
                Write-Log "Network not ready yet, attempt $($attempts + 1)/$maxAttempts"
            }
            Start-Sleep -Seconds 2
            $attempts++
        }
        
        # Additional startup delay
        Write-Log "Waiting additional $($Config.StartupDelay) seconds for system stability..."
        Start-Sleep -Seconds $Config.StartupDelay
        
        Write-Log "System ready check completed"
        return $true
    } catch {
        Write-Log "Error in Wait-ForSystemReady: $_"
        return $false
    }
}

# Function to check if Chrome exists
function Test-ChromeExists {
    try {
        if (Test-Path $Config.ChromePath) {
            Write-Log "Chrome found at: $($Config.ChromePath)"
            return $true
        }
        
        # Try alternative Chrome paths
        $possiblePaths = @(
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                Write-Log "Chrome found at alternative path: $path"
                $Config.ChromePath = $path
                return $true
            }
        }
        
        Write-Log "Chrome not found in any standard location"
        return $false
    } catch {
        Write-Log "Error checking Chrome: $_"
        return $false
    }
}

# Function to check Chrome profile
function Test-ChromeProfile {
    try {
        $profileName = $Config.ChromeProfile -replace '--profile-directory=`"', '' -replace '`"', ''
        $profilePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\$profileName"
        
        if (Test-Path $profilePath) {
            Write-Log "Chrome profile found: $profilePath"
            return $true
        } else {
            Write-Log "Chrome profile not found, using default profile"
            $Config.ChromeProfile = ""
            return $false
        }
    } catch {
        Write-Log "Error checking Chrome profile: $_"
        return $false
    }
}

# Function to launch Chrome with URLs
function Launch-ChromeWithURLs {
    try {
        Write-Log "Starting Chrome launch process..."
        
        if (-not (Test-ChromeExists)) {
            Write-Log "Chrome not found. Cannot launch URLs."
            return $false
        }
        
        Test-ChromeProfile
        
        foreach ($url in $Config.URLs) {
            try {
                Write-Log "Opening URL: $url"
                
                $chromeArgs = @()
                if ($Config.ChromeProfile) {
                    $chromeArgs += $Config.ChromeProfile
                }
                $chromeArgs += $url
                
                Start-Process -FilePath $Config.ChromePath -ArgumentList $chromeArgs
                Start-Sleep -Milliseconds 2000  # Delay between launches
                
                Write-Log "Successfully launched: $url"
            } catch {
                Write-Log "Failed to launch URL $url : $_"
            }
        }
        
        Write-Log "Chrome launch process completed"
        return $true
        
    } catch {
        Write-Log "Error in Launch-ChromeWithURLs: $_"
        return $false
    }
}

# Main execution
try {
    Write-Log "=== Chrome URL Launcher Startup Script Started ==="
    Write-Log "Script started at $(Get-Date)"
    
    # Wait for system to be ready
    Wait-ForSystemReady
    
    # Launch Chrome with URLs
    $success = Launch-ChromeWithURLs
    
    if ($success) {
        Write-Log "=== Chrome URL Launcher completed successfully ==="
        Write-Log "URLs launched: $($Config.URLs -join ', ')"
    } else {
        Write-Log "=== Chrome URL Launcher failed ==="
    }
    
    Write-Log "Script completed at $(Get-Date)"
    
} catch {
    Write-Log "=== Script encountered an error ==="
    Write-Log "Error: $_"
}

# Exit the script (don't keep window open for startup)
exit 0

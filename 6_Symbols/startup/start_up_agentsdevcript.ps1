# Set strict mode off to avoid strict variable checking
Set-StrictMode -Off
# Enable verbose output for troubleshooting
$VerbosePreference = "Continue"
$ErrorActionPreference = "Continue"


$monitors = @(
    @{
        Name       = 'Monitor 1'
        Index       = '0'
        Orientation = 'Horizontal'
        Brand      = 'LG'
    },
    @{
        Name       = 'Monitor 2'
        Index       = '1'
        Orientation = 'Vertical'
        Brand      = 'Asus'
    },
    @{
        Name       = 'Monitor 3'
        Index       = '2'
        Orientation = 'Horizontal'
        Brand      = 'Samsung'
    },
    @{
        Name       = 'Monitor 4'
        Index       = '3'
        Orientation = 'Vertical'
        Brand      = 'Hunion'
    }
)

#todo: mention the monitor name in the debug  when moving the windows

$Config = @{
    LogFile       = "$env:USERPROFILE\Desktop\StartupLog\Startup_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    ChromePath    = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    ChromeProfile = "--profile-directory=`"Profile 21`""
    StartAscii   = @"
  _,-._
 / \_/ \
>-(_)-<
 \_/ \_/
  `-'
"@
    EndAscii     = @"
 _______
<       >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
"@
}


# Add the new startup entries

# Run all AutoHotkey scripts in the specified directory
Get-ChildItem -Path "C:\projects\workstation\6_Symbols\ahk\" -Filter "*.ahk" | ForEach-Object {
    Start-Process -FilePath "C:\Program Files\AutoHotkey\AutoHotkey.exe" -ArgumentList $_.FullName
}

# Open alternative webpage
Start-Process "https://deepai.org/chat"

# Update Winget and Chocolatey packages
winget upgrade --all
choco upgrade all -y

# List all Chocolatey and Winget packages
choco list --localonly
winget list

# Add section to handle the locale error
try {
    $localeError = $false
    # Code to start OBS and monitor goes here
    @{ Path = "C:\Program Files\OBS-Studio\bin\64bit\obs64.exe"; Monitor = 1 }
    
} catch {
    Write-Host "[ERROR] Locale issue detected" -ForegroundColor Red
    $localeError = $true
}

# If locale error, open the directory for manual troubleshooting
if ($localeError) {
    Start-Process "explorer.exe" "C:\Program Files\OBS-Studio\bin\64bit"
}

$Applications = @(
    @{ Name = "LM Studio"; Path = "C:\Users\Pexabo\AppData\Local\Programs\LM Studio\LM Studio.exe"; RequiresAdmin = $true }
    @{ Name = "AnythingLLM"; Path = "C:\Users\Pexabo\AppData\Local\Programs\AnythingLLM\AnythingLLM.exe"; RequiresAdmin = $false }
    @{ Name = "Obsidian"; Path = "C:\Users\Pexabo\AppData\Local\Programs\Obsidian\Obsidian.exe"; RequiresAdmin = $false }
    @{ Name = "Stream Deck"; Path = "C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"; RequiresAdmin = $false }
    @{ Name = "Visual Studio Code"; Path = "C:\Program Files\Microsoft VS Code\Code.exe"; RequiresAdmin = $false }
    @{ Name = "Docker Desktop"; Path = "C:\Program Files\Docker\Docker\Docker Desktop.exe"; RequiresAdmin = $false }
)

$Urls = @(
    "https://chatgpt.com/?hints=search&ref=ext&model=auto"
    "https://claude.ai/new"
    "https://to-do.office.com/tasks/"
    "https://www.perplexity.ai/"
    "https://www.linkedin.com/"
    "https://www.gmail.com/"
    "https://vdo.ninja/?director=rifaterdemsahin"
    "https://calendly.com/app/scheduled_events/user/me"
    "https://github.com/n8n-io/n8n"
    "https://www.notion.so/"
    "https://x.com/i/grok"
    "https://rifaterdemsahinblog.wordpress.com/wp-admin/post-new.php?post_type=post&calypsoify=1&block-editor=1&frame-nonce=3e1e1b7b1b&origin=https%3A%"
    "https://github.com/rifaterdemsahin/workstation/edit/master/6_Symbols/startup/start_up_agentsdevcript.ps1"
    "https://mail.google.com/mail/u/0/#advanced-search/is_unread=true&query=label%3A1_borrow_followup&isrefinement=true"
    "https://petersfieldmansions.direct.quickconnect.to:5001/"
    "https://manus.im/"
    "https://go.starweaver.com/profile/instructor-dashboard/opportunity-management/details/679cd2b8941c837fde759519/comments"
    "https://aistudio.google.com/live"
)

$CommUrls = @(
    "https://x.com/messages"
    "https://www.linkedin.com/messaging/"
    "http://localhost:5678/"
)


# ... (rest of your script) ...

$WorkProfileurls = @(
    "https://teams.microsoft.com/v2/"
    "https://outlook.office.com/calendar/view/week"
    "https://outlook.office.com/mail/"
)

# ... (rest of your script) ...

function Launch-BrowserContent {
    try {
        # First validate if Chrome exists
        if (-not (Test-Path $Config.ChromePath)) {
            # ... (existing code for finding Chrome or falling back to Edge) ...
        }
        
        $chromeArgs = @()
        if ($Config.ChromeProfile) {
            $chromeArgs += $Config.ChromeProfile
        }

        # Define a new profile for the work urls
        $workProfile = "--profile-directory=`"Profile 19`""
        
        # Launch main URLs with delay between each to avoid overwhelming system
        Write-Debug "Opening URLs in browser" "DarkCyan"
        foreach ($url in $Urls) {
            Write-Debug "Opening URL: $url" "DarkCyan"
            Start-ProcessEx $Config.ChromePath ($chromeArgs + $url)
            Start-Sleep -Milliseconds 500  # Small delay between launches
        }
        
        # Launch communication URLs
        Write-Debug "Opening communication channels" "Blue"
        foreach ($url in $CommUrls) {
            Start-ProcessEx $Config.ChromePath ($chromeArgs + $url)
            Start-Sleep -Milliseconds 500  # Small delay between launches
        }

        #Launch Work urls
         Write-Debug "Opening Work Profile URLs" "Blue"
        foreach ($url in $WorkProfileurls) {
            Start-ProcessEx $Config.ChromePath ($workProfile + $url)
            Start-Sleep -Milliseconds 500  # Small delay between launches
        }

    } catch {
        # ... (rest of your error handling) ...
    }
}
# ... (rest of your script) ...


$DebugPreference = "Continue"

# Ensure log directory exists
try {
    $logDir = Split-Path -Parent $Config.LogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        Write-Host "Created log directory: $logDir" -ForegroundColor Green
    }
} catch {
    Write-Host "Error creating log directory: $_" -ForegroundColor Red
    # Fallback to a simpler log path if the desktop path fails
    $Config.LogFile = "$env:TEMP\Startup_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    Write-Host "Using alternative log file: $($Config.LogFile)" -ForegroundColor Yellow
}

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

function Write-Debug {
    param ([string]$Message, [string]$Color = "Cyan")
    Write-Host "[DEBUG] $Message" -ForegroundColor $Color
    Write-Log "[DEBUG] $Message"
}

function Write-Ascii {
    param([string]$Text, [string]$ForegroundColor = "White", [string]$BackgroundColor = "Black")
    Write-Host $Text -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    Write-Log $Text
}

function Start-ProcessEx {
    param (
        [string]$ProcessPath, 
        [string[]]$Arguments = @(), 
        [string]$Verb = "", 
        [string]$WorkingDirectory = ""
    )
    
    try {
        # Check if path exists with more detailed output
        if (-not (Test-Path $ProcessPath)) {
            Write-Host "[WARNING] Path not found: $ProcessPath" -ForegroundColor Yellow
            Write-Log "[WARNING] Path not found: $ProcessPath"
            return $false
        }
        
        # Create process start info
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $ProcessPath
        $startInfo.Arguments = $Arguments -join " "
        if ($Verb) { $startInfo.Verb = $Verb }
        if ($WorkingDirectory -and (Test-Path $WorkingDirectory)) { 
            $startInfo.WorkingDirectory = $WorkingDirectory 
        }
        
        # Add more robust error handling for RunAs
        if ($Verb -eq "RunAs") {
            try {
                # Try to launch with admin rights
                [System.Diagnostics.Process]::Start($startInfo) | Out-Null
            } catch {
                Write-Host "[ERROR] Failed to start with admin rights: $ProcessPath. Error: $_" -ForegroundColor Red
                Write-Log "[ERROR] Failed to start with admin rights: $ProcessPath. Error: $_"
                
                # Fallback to regular start without admin rights
                Write-Host "[INFO] Attempting to start without admin rights: $ProcessPath" -ForegroundColor Yellow
                $startInfo.Verb = ""
                try {
                    [System.Diagnostics.Process]::Start($startInfo) | Out-Null
                } catch {
                    Write-Host "[ERROR] Failed to start without admin rights: $ProcessPath. Error: $_" -ForegroundColor Red
                    Write-Log "[ERROR] Failed to start without admin rights: $ProcessPath. Error: $_"
                    return $false
                }
            }
        } else {
            # Regular start without admin rights
            [System.Diagnostics.Process]::Start($startInfo) | Out-Null
        }
        
        Write-Debug "Successfully launched: $ProcessPath" "Green"
        return $true
    } catch {
        Write-Host "[ERROR] Failed to start $ProcessPath. Error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to start $ProcessPath. Error: $_"
        return $false
    }
}

function Initialize-Environment {
    try {
        Write-Ascii $Config.StartAscii -ForegroundColor Green
        Write-Debug "Workstation Automation Started" "Green"
        Write-Debug "Script started on $(Get-Date)" "Green"
        Write-Debug "Minimizing all windows" "Yellow"
        
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.MinimizeAll()
        } catch {
            Write-Host "[WARNING] Failed to minimize windows: $_" -ForegroundColor Yellow
            Write-Log "[WARNING] Failed to minimize windows: $_"
        }
    } catch {
        Write-Host "[ERROR] Failed to initialize environment: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to initialize environment: $_"
    }
}

function Launch-BrowserContent {
    try {
        # First validate if Chrome exists
        if (-not (Test-Path $Config.ChromePath)) {
            Write-Host "[ERROR] Chrome not found at: $($Config.ChromePath)" -ForegroundColor Red
            Write-Log "[ERROR] Chrome not found at: $($Config.ChromePath)"
            
            # Try to find Chrome in other common locations
            $possiblePaths = @(
                "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
            )
            
            foreach ($path in $possiblePaths) {
                if (Test-Path $path) {
                    Write-Host "[INFO] Found Chrome at: $path" -ForegroundColor Green
                    $Config.ChromePath = $path
                    break
                }
            }
            
            # If still not found, try to use Edge as fallback
            if (-not (Test-Path $Config.ChromePath)) {
                $edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
                if (Test-Path $edgePath) {
                    Write-Host "[INFO] Using Edge as fallback browser" -ForegroundColor Yellow
                    $Config.ChromePath = $edgePath
                    $Config.ChromeProfile = ""  # Reset profile as it's different for Edge
                } else {
                    Write-Host "[ERROR] No browser found. Skipping URL launches." -ForegroundColor Red
                    Write-Log "[ERROR] No browser found. Skipping URL launches."
                    return
                }
            }
        }
        
        $chromeArgs = @()
        if ($Config.ChromeProfile) {
            $chromeArgs += $Config.ChromeProfile
        }
        
        # Launch main URLs with delay between each to avoid overwhelming system
        Write-Debug "Opening URLs in browser" "DarkCyan"
        foreach ($url in $Urls) {
            Write-Debug "Opening URL: $url" "DarkCyan"
            Start-ProcessEx $Config.ChromePath ($chromeArgs + $url)
            Start-Sleep -Milliseconds 500  # Small delay between launches
        }
        
        # Launch communication URLs
        Write-Debug "Opening communication channels" "Blue"
        foreach ($url in $CommUrls) {
            Start-ProcessEx $Config.ChromePath ($chromeArgs + $url)
            Start-Sleep -Milliseconds 500  # Small delay between launches
        }
    } catch {
        Write-Host "[ERROR] Failed to launch browser content: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to launch browser content: $_"
    }
}

function Launch-Applications {
    try {
        foreach ($app in $Applications) {
            $verb = if ($app.RequiresAdmin) { "RunAs" } else { "" }
            Write-Debug "Launching $($app.Name)" "Blue"
            
            if (-not (Test-Path $app.Path)) {
                Write-Host "[WARNING] Application not found: $($app.Name) at $($app.Path)" -ForegroundColor Yellow
                Write-Log "[WARNING] Application not found: $($app.Name) at $($app.Path)"
                continue
            }
            
            if ($app.Name -eq "Visual Studio Code") {
                # Check if folders exist before opening
                $workstationPath = "C:\projects\workstation\"
                $secondbrainPath = "C:\projects\secondbrain\"
                
                if (Test-Path $workstationPath) {
                    Start-ProcessEx $app.Path $workstationPath
                } else {
                    Write-Host "[WARNING] Path not found: $workstationPath" -ForegroundColor Yellow
                }
                
                if (Test-Path $secondbrainPath) {
                    Start-ProcessEx $app.Path $secondbrainPath
                } else {
                    Write-Host "[WARNING] Path not found: $secondbrainPath" -ForegroundColor Yellow
                }
            } else {
                Start-ProcessEx $app.Path -Verb $verb
            }
            
            # Add a small delay between application launches
            Start-Sleep -Milliseconds 1000
        }
    } catch {
        Write-Host "[ERROR] Failed to launch applications: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to launch applications: $_"
    }
}

function Update-System {
    # Check if the script is running with administrative privileges
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        # Relaunch the script with elevated privileges
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        return
    }

    try {
        Write-Debug "Checking for Chocolatey"
        $chocoExists = Get-Command choco -ErrorAction SilentlyContinue

        if ($chocoExists) {
            Write-Debug "Updating Chocolatey packages"
            try {
                Start-Process "cmd.exe" -ArgumentList "/c choco upgrade all -y" -Verb RunAs -Wait
            } catch {
                Write-Host "[ERROR] Chocolatey update failed: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "[INFO] Chocolatey not installed. Skipping package updates." -ForegroundColor Yellow
        }

        Write-Debug "Opening Windows Update settings"
        try {
            Start-Process "ms-settings:windowsupdate" -ErrorAction SilentlyContinue
        } catch {
            Write-Host "[ERROR] Failed to open Windows Update: $_" -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] System update error: $_" -ForegroundColor Red
    }
}

function Sync-Repositories {
    try {
        Write-Debug "Pulling Second Brain Repo" "Green"
        if (Test-Path "C:\projects\secondbrain") {
            try {
                # Check if git is installed
                $gitExists = Get-Command git -ErrorAction SilentlyContinue
                
                if ($gitExists) {
                    Set-Location "C:\projects\secondbrain"
                    $output = git pull 2>&1
                    Write-Debug "Git pull output: $output" "Green"
                    Write-Debug "Successfully pulled Second Brain repo" "Green"
                } else {
                    Write-Host "[WARNING] Git not found. Cannot pull repository." -ForegroundColor Yellow
                    Write-Log "[WARNING] Git not found. Cannot pull repository."
                }
            } catch {
                Write-Host "[ERROR] Second Brain pull failed: $_" -ForegroundColor Red
                Write-Log "[ERROR] Second Brain pull failed: $_"
            }
        } else {
            Write-Host "[WARNING] Second Brain repo not found at C:\projects\secondbrain" -ForegroundColor Yellow
            Write-Log "[WARNING] Second Brain repo not found at C:\projects\secondbrain"
        }
    } catch {
        Write-Host "[ERROR] Repository sync error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Repository sync error: $_"
    }
}

function Test-Network {
    try {
        Write-Debug "Testing network latency to 1.1.1.1" "Yellow"
        
        try {
            $pingResults = Test-Connection -ComputerName "1.1.1.1" -Count 4 -ErrorAction Stop
            $avgPing = ($pingResults | Measure-Object -Property ResponseTime -Average).Average
            $color = if ($avgPing -gt 20) { "Red" } else { "Green" }
            Write-Host "Average ping to 1.1.1.1: $avgPing ms" -ForegroundColor $color
            Write-Log "Average ping to 1.1.1.1: $avgPing ms"
        } catch {
            Write-Host "[WARNING] Network test failed: $_" -ForegroundColor Yellow
            Write-Log "[WARNING] Network test failed: $_"
            
            # Try using alternative ping method
            try {
                $ping = New-Object System.Net.NetworkInformation.Ping
                $results = @()
                for ($i = 0; $i -lt 4; $i++) {
                    $results += $ping.Send("1.1.1.1")
                    Start-Sleep -Milliseconds 500
                }
                
                $successfulPings = $results | Where-Object { $_.Status -eq 'Success' }
                if ($successfulPings.Count -gt 0) {
                    $avgPing = ($successfulPings | Measure-Object -Property RoundtripTime -Average).Average
                    $color = if ($avgPing -gt 20) { "Red" } else { "Green" }
                    Write-Host "Average ping to 1.1.1.1: $avgPing ms" -ForegroundColor $color
                    Write-Log "Average ping to 1.1.1.1: $avgPing ms"
                } else {
                    Write-Host "[WARNING] All ping attempts failed. Check network connection." -ForegroundColor Red
                    Write-Log "[WARNING] All ping attempts failed. Check network connection."
                }
            } catch {
                Write-Host "[ERROR] Alternate network test also failed: $_" -ForegroundColor Red
                Write-Log "[ERROR] Alternate network test also failed: $_"
            }
        }
    } catch {
        Write-Host "[ERROR] Network test function error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Network test function error: $_"
    }
}

function Get-SystemInfo {
    try {
        Write-Host "`n=======================================" -ForegroundColor Blue
        Write-Host "SYSTEM INFORMATION" -ForegroundColor Cyan
        Write-Host "=======================================" -ForegroundColor Blue
        Get-RAMInfo

        Write-Host "`n=======================================" -ForegroundColor Blue
        Write-Host "DISK INFORMATION" -ForegroundColor Cyan
        Write-Host "=======================================" -ForegroundColor Blue
        Get-DiskInfo
    } catch {
        Write-Host "[ERROR] Failed to get system information: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to get system information: $_"
    }
}

function Get-RAMInfo {
    try {
        $RAM = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop | 
               Select-Object TotalVisibleMemorySize, FreePhysicalMemory
        
        $RAMUsed = $RAM.TotalVisibleMemorySize - $RAM.FreePhysicalMemory
        $RAMTotalGB = [math]::Round($RAM.TotalVisibleMemorySize / 1MB, 2)
        $RAMFreeGB = [math]::Round($RAM.FreePhysicalMemory / 1MB, 2)
        $RAMPercentUsed = [math]::Round(($RAMUsed / $RAM.TotalVisibleMemorySize) * 100, 2)
        $color = if ($RAMPercentUsed -gt 80) { "Red" } elseif ($RAMPercentUsed -gt 60) { "Yellow" } else { "Green" }

        Write-Host "Total RAM: $RAMTotalGB GB"
        Write-Host "Free RAM: $RAMFreeGB GB"
        Write-Host "RAM Usage: $RAMPercentUsed%" -ForegroundColor $color
        Write-Log "RAM Info - Total: $RAMTotalGB GB, Free: $RAMFreeGB GB, Usage: $RAMPercentUsed%"
    } catch {
        # Try alternative method
        try {
            Write-Host "[WARNING] Standard RAM check failed, trying alternative method." -ForegroundColor Yellow
            $computerSystem = Get-CimInstance CIM_ComputerSystem
            $totalRAM = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
            
            Write-Host "Total RAM: $totalRAM GB"
            Write-Host "Note: Detailed RAM usage information unavailable" -ForegroundColor Yellow
            Write-Log "RAM Info - Total: $totalRAM GB (alternative method)"
        } catch {
            Write-Host "[ERROR] Failed to get RAM information: $_" -ForegroundColor Red
            Write-Log "[ERROR] Failed to get RAM information: $_"
        }
    }
}

function Get-DiskInfo {
    try {
        Get-WmiObject Win32_LogicalDisk -ErrorAction Stop | 
        Where-Object { $_.DriveType -eq 3 } | 
        ForEach-Object {
            $DiskSizeGB = [math]::Round($_.Size / 1GB, 2)
            $DiskFreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
            $DiskPercentUsed = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
            $color = if ($DiskPercentUsed -gt 90) { "Red" } elseif ($DiskPercentUsed -gt 75) { "Yellow" } else { "Green" }

            Write-Host "Drive $($_.DeviceID):" -ForegroundColor White
            Write-Host "  Total Size: $DiskSizeGB GB"
            Write-Host "  Free Space: $DiskFreeGB GB"
            Write-Host "  Disk Usage: $DiskPercentUsed%" -ForegroundColor $color
            Write-Log "Disk $($_.DeviceID) - Total: $DiskSizeGB GB, Free: $DiskFreeGB GB, Usage: $DiskPercentUsed%"
        }
    } catch {
        Write-Host "[ERROR] Failed to get disk information: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to get disk information: $_"
        
        # Try alternative method
        try {
            Write-Host "[WARNING] Standard disk check failed, trying alternative method." -ForegroundColor Yellow
            Get-PSDrive -PSProvider FileSystem | ForEach-Object {
                try {
                    $driveName = $_.Name
                    $driveRoot = $_.Root
                    $totalSize = [math]::Round($_.Used / 1GB + $_.Free / 1GB, 2)
                    $freeSpace = [math]::Round($_.Free / 1GB, 2)
                    
                    Write-Host "Drive ${driveName}:" -ForegroundColor White
                    Write-Host "  Total Size: $totalSize GB (approximate)"
                    Write-Host "  Free Space: $freeSpace GB"
                    Write-Log "Disk ${driveName}: - Total: $totalSize GB, Free: $freeSpace GB (alternative method)"
                } catch {
                    Write-Host "[ERROR] Failed to get info for drive $($_.Name): $_" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "[ERROR] Alternative disk check also failed: $_" -ForegroundColor Red
            Write-Log "[ERROR] Alternative disk check also failed: $_"
        }
    }
}

function Position-Windows {
    try {
        Write-Debug "Attempting to set window positions" "Magenta"
        
        try {
            # Check if we can load the Windows Forms assembly
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            Start-Sleep -Seconds 3

            $windows = @(
                @{ Process = "WhatsApp"; X = 0;   Y = 0 }
                @{ Process = "Chrome";  X = 1920; Y = 0 }
                @{ Process = "OBS";     X = 3840; Y = 0 }
            )

            foreach ($window in $windows) {
                try {
                    $proc = Get-Process | Where-Object { $_.MainWindowTitle -like "*$($window.Process)*" }
                    if ($proc) {
                        $proc | ForEach-Object {
                            try {
                                $_.WaitForInputIdle() | Out-Null
                                if ($_.MainWindowHandle -ne 0) {
                                    $control = [System.Windows.Forms.Control]::FromHandle($_.MainWindowHandle)
                                    $control.Location = New-Object System.Drawing.Point($window.X, $window.Y)
                                    $control.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
                                }
                            } catch {
                                Write-Host "[WARNING] Failed to position window for $($window.Process): $_" -ForegroundColor Yellow
                            }
                        }
                        Write-Debug "$($window.Process) window positioned" "Green"
                    } else {
                        Write-Host "[INFO] $($window.Process) window not found" -ForegroundColor Yellow
                        Write-Log "[INFO] $($window.Process) window not found"
                    }
                } catch {
                    Write-Host "[WARNING] Error handling $($window.Process): $_" -ForegroundColor Yellow
                    Write-Log "[WARNING] Error handling $($window.Process): $_"
                }
            }
        } catch {
            Write-Host "[WARNING] Failed to load Windows Forms assembly: $_. Window positioning skipped." -ForegroundColor Yellow
            Write-Log "[WARNING] Failed to load Windows Forms assembly: $_. Window positioning skipped."
        }
    } catch {
        Write-Host "[ERROR] Window positioning function error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Window positioning function error: $_"
    }
}

# Main Execution with error handling
try {
    Initialize-Environment
    
    # Each function call is wrapped with error handling in the function itself
    Launch-BrowserContent
    Launch-Applications
    Update-System
    Sync-Repositories
    Test-Network
    Get-SystemInfo
    Position-Windows

    Write-Debug "Script completed on $(Get-Date)" "Green"
    Write-Ascii $Config.EndAscii -ForegroundColor Cyan

    Write-Host "`n=======================================" -ForegroundColor Yellow
    Write-Host "✅ All startup tasks completed!" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Yellow

    $close = Read-Host "Press Enter to close or type 'stay' to keep open"
    if ($close -ne "stay") {
        Write-Debug "Closing terminal" "Green"
        Stop-Process -Id $PID
    } else {
        Write-Debug "Terminal remains open" "Green"
    }
} catch {
    Write-Host "`n=======================================" -ForegroundColor Red
    Write-Host "❌ Script encountered errors!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=======================================" -ForegroundColor Red
    Write-Log "[CRITICAL] Main script execution error: $_"
    
    Write-Host "`nLog file location: $($Config.LogFile)" -ForegroundColor Yellow
    Write-Host "Press Enter to close..." -ForegroundColor Yellow
    Read-Host | Out-Null
}

$WorkProfileurls = @(
    "https://teams.microsoft.com/v2/"
    "https://outlook.office.com/calendar/view/week"
    "https://outlook.office.com/mail/"
    "https://calendar.google.com/calendar/u/0/r/agenda"
    "https://glasp.co/?ref=glasp_extension"
    "https://chatgpt4youtube.com/tr"
)

# Add Paint.NET to the startup process list
$ProcessesToStart = @(
    @{ Path = "C:\Program Files\OBS-Studio\bin\64bit\obs64.exe"; Monitor = 1 },
    @{ Path = "C:\Program Files\Google\Chrome\Application\chrome.exe"; Arguments = "--profile-directory=Profile 2 $WorkProfileurls"; Monitor = 2 },
    @{ Path = "C:\Program Files\Google\Chrome\Application\chrome.exe"; Arguments = "--profile-directory=Profile 3"; Monitor = 3 }, # work profile
    @{ Path = "C:\Program Files\Mozilla Firefox\firefox.exe"; Monitor = 1 }, # browser
    @{ Path = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"; Monitor = 1 }, # voice search
    @{ Path = "C:\WINDOWS\System32\notepad.exe"; Monitor = 4 }, # notepad
    @{ Path = "C:\Program Files\Paint.NET\paintdotnet.exe"; Monitor = 4 }, # Paint.NET
    @{ Path = "C:\Program Files\WindowsApps\MSTeams_25044.2208.3471.2155_x64__8wekyb3d8bbwe\ms-teams.exe"; Monitor = 4 } # Teams
)

foreach ($process in $ProcessesToStart) {
    Start-ProcessOnMonitor -ProcessPath $process.Path -Monitor $process.Monitor -Arguments $process.Arguments
}



function Start-ProcessOnMonitor {
    param(
        [string]$ProcessPath,
        [int]$Monitor = 0,
        [string]$Arguments = ""
    )

    try {
        $Process = Start-Process -FilePath $ProcessPath -ArgumentList $Arguments -PassThru

        if ($Monitor -gt 0) {
            Start-Sleep -Seconds 1
            $Window = Get-Process | Where-Object {$_.Id -eq $Process.Id} | Select-Object MainWindowHandle -ExpandProperty MainWindowHandle
            if ($Window -ne 0) {
                [System.Windows.Forms.Screen]::AllScreens | Where-Object {$_.DeviceName -eq "\\.\DISPLAY$Monitor"} | ForEach-Object {
                    $Bounds = $_.Bounds
                    [System.Windows.Forms.Control]::FromHandle($Window).SetBounds($Bounds.X, $Bounds.Y, $Bounds.Width, $Bounds.Height)
                }
            } else {
                Write-Warning "Could not find window for $ProcessPath" -ForegroundColor Yellow
                Write-Log "Could not find window for $ProcessPath"
            }
        }

        return $true

    } catch {
        Write-Host "[ERROR] Failed to start $ProcessPath" -ForegroundColor Red
        Write-Log "[ERROR] Failed to start $ProcessPath"
        return $false
    }
}

# Add a section to run AHK scripts from a specified folder
function Run-AHKScripts {
    param (
        [string]$AHKFolder = "C:\projects\workstation\6_Symbols\ahk\"
    )

    try {
        $ahkFiles = Get-ChildItem -Path $AHKFolder -Filter *.ahk
        foreach ($file in $ahkFiles) {
            Write-Debug "Running AHK script: $($file.FullName)" "Magenta"
            Start-Process "AutoHotkey.exe" -ArgumentList $file.FullName
        }
    } catch {
        Write-Host "[ERROR] Failed to run AHK scripts from $AHKFolder. Error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to run AHK scripts from $AHKFolder. Error: $_"
    }
}

# Alternative browser launch
function Launch-AlternativeBrowser {
    try {
        $url = "https://deepai.org/chat"
        Write-Debug "Opening alternative URL: $url" "Magenta"
        Start-Process "$Config.ChromePath" $url
    } catch {
        Write-Host "[ERROR] Failed to launch alternative browser for URL: $url. Error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to launch alternative browser for URL: $url. Error: $_"
    }
}

# Winget update process
function Update-WingetPrograms {
    try {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Debug "Updating Winget packages" "Magenta"
            Start-ProcessEx "cmd.exe" "/c winget upgrade --all --silent" -Verb "RunAs"
        } else {
            Write-Host "[INFO] Winget not installed. Skipping Winget package updates." -ForegroundColor Yellow
            Write-Log "[INFO] Winget not installed. Skipping Winget package updates."
        }
    } catch {
        Write-Host "[ERROR] Failed to update Winget programs: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to update Winget programs: $_"
    }
}

# List installed Chocolatey and Winget programs
function List-InstalledPrograms {
    try {
        Write-Debug "Listing installed Chocolatey programs" "Magenta"
        $chocoPrograms = choco list --local-only
        Write-Log "Installed Chocolatey programs:`n$chocoPrograms"

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Debug "Listing installed Winget programs" "Magenta"
            $wingetPrograms = winget list
            Write-Log "Installed Winget programs:`n$wingetPrograms"
        } else {
            Write-Log "[INFO] Winget not installed. Skipping listing Winget programs."
        }
    } catch {
        Write-Host "[ERROR] Failed to list installed programs: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to list installed programs: $_"
    }
}

# Call these functions in the main script execution block
try {
    Initialize-Environment

    # Each function call is wrapped with error handling in the function itself
    Launch-BrowserContent
    Launch-Applications
    Run-AHKScripts  # New: Run AHK scripts
    Launch-AlternativeBrowser  # New: Open alternative URL
    Update-System
    Update-WingetPrograms  # New: Update Winget programs
    List-InstalledPrograms  # New: List installed programs
    Sync-Repositories
    Test-Network
    Get-SystemInfo
    Position-Windows

    Write-Debug "Script completed on $(Get-Date)" "Green"
    Write-Ascii $Config.EndAscii -ForegroundColor Cyan

    Write-Host "`n=======================================" -ForegroundColor Yellow
    Write-Host "✅ All startup tasks completed!" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Yellow

    $close = Read-Host "Press Enter to close or type 'stay' to keep open"
    if ($close -ne "stay") {
        Write-Debug "Closing terminal" "Green"
        Stop-Process -Id $PID
    } else {
        Write-Debug "Terminal remains open" "Green"
    }
} catch {
    Write-Host "`n=======================================" -ForegroundColor Red
    Write-Host "❌ Script encountered errors!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=======================================" -ForegroundColor Red
    Write-Log "[CRITICAL] Main script execution error: $_"

    Write-Host "`nLog file location: $($Config.LogFile)" -ForegroundColor Yellow
    Write-Host "Press Enter to close..." -ForegroundColor Yellow
    Read-Host | Out-Null
}
# Add a section to run AHK scripts from a specified folder
function Run-AHKScripts {
    param (
        [string]$AHKFolder = "C:\projects\workstation\6_Symbols\ahk\"
    )

    try {
        $ahkFiles = Get-ChildItem -Path $AHKFolder -Filter *.ahk
        foreach ($file in $ahkFiles) {
            Write-Debug "Running AHK script: $($file.FullName)" "Magenta"
            Start-Process "AutoHotkey.exe" -ArgumentList $file.FullName
        }
    } catch {
        Write-Host "[ERROR] Failed to run AHK scripts from $AHKFolder. Error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to run AHK scripts from $AHKFolder. Error: $_"
    }
}

# Alternative browser launch
function Launch-AlternativeBrowser {
    try {
        $url = "https://deepai.org/chat"
        Write-Debug "Opening alternative URL: $url" "Magenta"
        Start-Process "$Config.ChromePath" $url
    } catch {
        Write-Host "[ERROR] Failed to launch alternative browser for URL: $url. Error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to launch alternative browser for URL: $url. Error: $_"
    }
}

# Winget update process
function Update-WingetPrograms {
    try {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Debug "Updating Winget packages" "Magenta"
            Start-ProcessEx "cmd.exe" "/c winget upgrade --all --silent" -Verb "RunAs"
        } else {
            Write-Host "[INFO] Winget not installed. Skipping Winget package updates." -ForegroundColor Yellow
            Write-Log "[INFO] Winget not installed. Skipping Winget package updates."
        }
    } catch {
        Write-Host "[ERROR] Failed to update Winget programs: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to update Winget programs: $_"
    }
}

# List installed Chocolatey and Winget programs
function List-InstalledPrograms {
    try {
        Write-Debug "Listing installed Chocolatey programs" "Magenta"
        $chocoPrograms = choco list --local-only
        Write-Log "Installed Chocolatey programs:`n$chocoPrograms"

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Debug "Listing installed Winget programs" "Magenta"
            $wingetPrograms = winget list
            Write-Log "Installed Winget programs:`n$wingetPrograms"
        } else {
            Write-Log "[INFO] Winget not installed. Skipping listing Winget programs."
        }
    } catch {
        Write-Host "[ERROR] Failed to list installed programs: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to list installed programs: $_"
    }
}

# Call these functions in the main script execution block
try {
    Initialize-Environment

    # Each function call is wrapped with error handling in the function itself
    Launch-BrowserContent
    Launch-Applications
    Run-AHKScripts  # New: Run AHK scripts
    Launch-AlternativeBrowser  # New: Open alternative URL
    Update-System
    Update-WingetPrograms  # New: Update Winget programs
    List-InstalledPrograms  # New: List installed programs
    Sync-Repositories
    Test-Network
    Get-SystemInfo
    Position-Windows

    Write-Debug "Script completed on $(Get-Date)" "Green"
    Write-Ascii $Config.EndAscii -ForegroundColor Cyan

    Write-Host "`n=======================================" -ForegroundColor Yellow
    Write-Host "✅ All startup tasks completed!" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Yellow

    $close = Read-Host "Press Enter to close or type 'stay' to keep open"
    if ($close -ne "stay") {
        Write-Debug "Closing terminal" "Green"
        Stop-Process -Id $PID
    } else {
        Write-Debug "Terminal remains open" "Green"
    }
} catch {
    Write-Host "`n=======================================" -ForegroundColor Red
    Write-Host "❌ Script encountered errors!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=======================================" -ForegroundColor Red
    Write-Log "[CRITICAL] Main script execution error: $_"

    Write-Host "`nLog file location: $($Config.LogFile)" -ForegroundColor Yellow
    Write-Host "Press Enter to close..." -ForegroundColor Yellow
    Read-Host | Out-Null
}

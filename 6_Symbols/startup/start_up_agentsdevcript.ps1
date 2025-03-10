# ASCII art for "start"
$startAscii = @"
  _,-._
 / \_/ \
>-(_)-<
 \_/ \_/
  `-'
"@

# ASCII art for "end"
$endAscii = @"
 _______
<       >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
"@

# Enable debugging output
$DebugPreference = "Continue"

# Function to write colored debug messages
function Write-DebugWithColor {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Color = "Cyan"
    )
    Write-Host "[DEBUG] $Message" -ForegroundColor $Color
}

# Function to display colored ASCII art
function Write-ColoredAscii {
    param(
        [string]$Text,
        [string]$ForegroundColor = "White",
        [string]$BackgroundColor = "Black"
    )

    Write-Host $Text -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

# Function to start a process with error handling
function Start-ProcessWithCheck {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProcessPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $false)]
        [string]$Verb = "",

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = ""
    )

    if (Test-Path $ProcessPath) {
        try {
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.FileName = $ProcessPath
            $startInfo.Arguments = $Arguments -join " "
            if ($Verb) { $startInfo.Verb = $Verb }
            if ($WorkingDirectory) { $startInfo.WorkingDirectory = $WorkingDirectory }
            [System.Diagnostics.Process]::Start($startInfo) | Out-Null
            Write-DebugWithColor "Successfully launched: $ProcessPath" "Green"
        } catch {
            Write-Host "[ERROR] Failed to start process: $ProcessPath. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "[WARNING] Process not found at: $ProcessPath" -ForegroundColor Yellow
    }
}

# Display "start" message
Write-ColoredAscii -Text $startAscii -ForegroundColor Green

Write-DebugWithColor "Workstation Automation Started" "Green"
Write-DebugWithColor "Script started on $(Get-Date)" "Green"

# Minimize all windows
Write-DebugWithColor "Minimizing all windows" "Yellow"
(New-Object -ComObject Shell.Application).MinimizeAll()

# Define URLs to open
$urls = @(
    "https://chatgpt.com/?hints=search&ref=ext&model=auto",  # ChatGPT
    "https://claude.ai/new",                                 # Claude AI
    "https://to-do.office.com/tasks/",                       # Microsoft To-Do
    "https://www.perplexity.ai/",                            # Perplexity AI
    "https://www.linkedin.com/",                             # LinkedIn
    "https://www.gmail.com/",                                # Gmail
    "https://vdo.ninja/?director=rifaterdemsahin",           # VDO Ninja
    "https://calendly.com/app/scheduled_events/user/me",     # Calendly
    "https://github.com/n8n-io/n8n",                         # n8n GitHub
    "https://www.notion.so/",                                # Notion
    "https://x.com/i/grok",                                  # Grok on X
    "https://rifaterdemsahinblog.wordpress.com/wp-admin/post-new.php?post_type=post&calypsoify=1&block-editor=1&frame-nonce=3e1e1b7b1b&origin=https%3A%",    
    "https://github.com/rifaterdemsahin/workstation/edit/master/6_Symbols/startup/start_up_script.ps1",
    "https://mail.google.com/mail/u/0/#advanced-search/is_unread=true&query=label%3A1_borrow_followup&isrefinement=true",
    "https://192-168-9-34.petersfieldmansions.direct.quickconnect.to:5001/"
)

# Launch default browser with URLs
foreach ($url in $urls) {
    Write-DebugWithColor "Opening URL: $url" "DarkCyan"
    try {
        Start-Process $url
        Write-DebugWithColor "Successfully opened: $url" "Green"
    } catch {
        Write-Host "[ERROR] Failed to open URL: $url. Error: $_" -ForegroundColor Red
    }
}

# Define applications to launch with full paths
$applications = @(
    @{
        Name = "OBS Studio"
        Path = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"  # Updated with full path
        RequiresAdmin = $true
    },
    @{
        Name = "LM Studio"
        Path = "C:\Program Files\LM Studio\LM Studio.exe"  # Updated with full path
        RequiresAdmin = $true
    },
    @{
        Name = "AnythingLLM"
        Path = "C:\Program Files\AnythingLLM\AnythingLLM.exe"  # Updated with full path
        RequiresAdmin = $false
    },
    @{
        Name = "Obsidian"
        Path = "C:\Users\%USERNAME%\AppData\Local\Obsidian\Obsidian.exe"  # Updated with full path
        RequiresAdmin = $false
    },
    @{
        Name = "Stream Deck"
        Path = "C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"  # Updated with full path
        RequiresAdmin = $false
    },
    @{
        Name = "Visual Studio Code"
        Path = "C:\Program Files\Microsoft VS Code\Code.exe"  # Updated with full path
        RequiresAdmin = $false
    },
    @{
        Name = "Docker Desktop"
        Path = "C:\Program Files\Docker\Docker\Docker Desktop.exe"  # Updated with full path
        RequiresAdmin = $false
    }
)

# Launch applications
foreach ($app in $applications) {
    if (Test-Path $app.Path -ErrorAction SilentlyContinue) {
        $verb = if ($app.RequiresAdmin) { "RunAs" } else { "" }
        Write-DebugWithColor "Launching $($app.Name)" "Blue"
        Start-ProcessWithCheck -ProcessPath $app.Path -Verb $verb
    } else {
        Write-Host "[WARNING] $($app.Name) not found at: $($app.Path)" -ForegroundColor Yellow
    }
}

# Update Chocolatey packages
Write-DebugWithColor "Updating Chocolatey packages" "Yellow"
try {
    Start-Process "cmd.exe" -ArgumentList "/c choco upgrade all -y" -Verb RunAs
    Write-DebugWithColor "Chocolatey package update initiated" "Green"
} catch {
    Write-Host "[ERROR] Failed to initiate Chocolatey update. Error: $_" -ForegroundColor Red
}

# Open Windows Update settings
Write-DebugWithColor "Opening Windows Update settings" "Yellow"
try {
    Start-Process "ms-settings:windowsupdate"
    Write-DebugWithColor "Windows Update settings opened" "Green"
} catch {
    Write-Host "[ERROR] Failed to open Windows Update settings. Error: $_" -ForegroundColor Red
}

# Pull Second Brain Repo
Write-DebugWithColor "Pulling Second Brain Repo for obsidian to Use" "Green"
try {
    # Change directory to the project path
    if (Test-Path "C:\projects\secondbrain") {
        Set-Location "C:\projects\secondbrain"
        git pull
        Write-DebugWithColor "Successfully pulled Second Brain repo" "Green"
    } else {
        Write-Host "[WARNING] Second Brain repository not found at C:\projects\secondbrain" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] Failed to pull Second Brain repository. Error: $_" -ForegroundColor Red
}

# Open additional URLs
Write-DebugWithColor "Opening communication channels" "Blue"
Start-Process "https://x.com/messages"
Start-Process "https://www.linkedin.com/messaging/"
Start-Process "http://localhost:5678/" # n8n

# Get RAM information
$RAM = Get-WmiObject Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory

# Calculate RAM usage
$RAMUsed = $RAM.TotalVisibleMemorySize - $RAM.FreePhysicalMemory
$RAMTotalGB = [math]::Round($RAM.TotalVisibleMemorySize/1MB, 2)
$RAMFreeGB = [math]::Round($RAM.FreePhysicalMemory/1MB, 2)
$RAMPercentUsed = [math]::Round(($RAMUsed / $RAM.TotalVisibleMemorySize) * 100, 2)

# Display RAM information
Write-Host "`n=======================================" -ForegroundColor Blue
Write-Host "SYSTEM INFORMATION" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Blue
Write-Host "Total RAM: $RAMTotalGB GB"
Write-Host "Free RAM: $RAMFreeGB GB"
Write-Host "RAM Usage: $RAMPercentUsed%" -ForegroundColor $(if ($RAMPercentUsed -gt 80) {"Red"} elseif ($RAMPercentUsed -gt 60) {"Yellow"} else {"Green"})

# Get disk usage information
Write-Host "`n=======================================" -ForegroundColor Blue
Write-Host "DISK INFORMATION" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Blue
Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object {
    $DiskSize = $_.Size
    $DiskFree = $_.FreeSpace
    $DiskUsed = $DiskSize - $DiskFree
    $DiskPercentUsed = [math]::Round(($DiskUsed / $DiskSize) * 100, 2)
    $DiskSizeGB = [math]::Round($DiskSize/1GB, 2)
    $DiskFreeGB = [math]::Round($DiskFree/1GB, 2)
    
    Write-Host "Drive $($_.DeviceID):" -ForegroundColor White
    Write-Host "  Total Size: $DiskSizeGB GB"
    Write-Host "  Free Space: $DiskFreeGB GB"
    Write-Host "  Disk Usage: $DiskPercentUsed%" -ForegroundColor $(if ($DiskPercentUsed -gt 90) {"Red"} elseif ($DiskPercentUsed -gt 75) {"Yellow"} else {"Green"})
}

# Set window positions
Write-DebugWithColor "Attempting to set window positions" "Magenta"
try {
    Add-Type -AssemblyName System.Windows.Forms

    # Give windows time to open
    Start-Sleep -Seconds 3

    # Replace with your application titles and monitor indices
    $whatsapp = Get-Process | Where-Object {$_.MainWindowTitle -like "*WhatsApp*"}
    $chrome = Get-Process | Where-Object {$_.MainWindowTitle -like "*Chrome*"}
    $obs = Get-Process | Where-Object {$_.MainWindowTitle -like "*OBS*"}

    if ($whatsapp) {
        $whatsapp.WaitForInputIdle()  # Ensure the window is ready
        $whatsapp.MainWindowHandle | ForEach-Object {
            [System.Windows.Forms.Control]::FromHandle($_).Location = New-Object System.Drawing.Point(0,0) #vertical monitor, assumed to be index 1 (0-indexed)
            [System.Windows.Forms.Control]::FromHandle($_).WindowState = [System.Windows.Forms.FormWindowState]::Maximized
        }
        Write-DebugWithColor "WhatsApp window positioned" "Green"
    } else {
        Write-Host "[INFO] WhatsApp window not found" -ForegroundColor Yellow
    }

    if ($chrome) {
        $chrome.WaitForInputIdle()
        $chrome.MainWindowHandle | ForEach-Object {
            [System.Windows.Forms.Control]::FromHandle($_).Location = New-Object System.Drawing.Point(1920,0) #first monitor, assumed to be index 0 (0-indexed)
            [System.Windows.Forms.Control]::FromHandle($_).WindowState = [System.Windows.Forms.FormWindowState]::Maximized
        }
        Write-DebugWithColor "Chrome window positioned" "Green"
    } else {
        Write-Host "[INFO] Chrome window not found" -ForegroundColor Yellow
    }

    if ($obs) {
        $obs.WaitForInputIdle()
        $obs.MainWindowHandle | ForEach-Object {
            [System.Windows.Forms.Control]::FromHandle($_).Location = New-Object System.Drawing.Point(3840,0) #third monitor, assumed to be index 2 (0-indexed)
            [System.Windows.Forms.Control]::FromHandle($_).WindowState = [System.Windows.Forms.FormWindowState]::Maximized
        }
        Write-DebugWithColor "OBS window positioned" "Green"
    } else {
        Write-Host "[INFO] OBS window not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] Failed to set window positions. Error: $_" -ForegroundColor Red
}

Write-DebugWithColor "Script completed on $(Get-Date)" "Green"

# Display "end" message
Write-ColoredAscii -Text $endAscii -ForegroundColor Cyan

# Prompt to close terminal
Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "✅ All startup applications launched!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Yellow

$close = Read-Host "Press Enter to close this terminal window or type 'stay' to keep it open"

if ($close -ne "stay") {
    Write-DebugWithColor "Closing terminal as per user input." "Green"
    Stop-Process -Id $PID
} else {
    Write-DebugWithColor "Terminal will remain open as per user request." "Green"
}
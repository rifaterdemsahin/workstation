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


# Function to display colored ASCII art
function Write-ColoredAscii {
    param(
        [string]$Text,
        [string]$ForegroundColor = "White",
        [string]$BackgroundColor = "Black"
    )

    Write-Host $Text -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

# Display "start" message
Write-ColoredAscii -Text $startAscii -ForegroundColor Green

# Existing code (e.g., window positioning logic)
#todo: Set windows to the correct monitors > whatsapp in the vertucal monitor, chrome in the first monitor and obs in the third monitor
#todo: display the start with ascii of the workstation statupo

Write-DebugWithColor "Workstation Automation Started"

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

Write-DebugWithColor "Script started on $(Get-Date)" "Green"

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
    "https://x.com/i/grok"                                   # Grok on X
    "https://github.com/rifaterdemsahin/workstation/edit/master/6_Symbols/startup/start_up_script.ps1"                                  # Workstation Code Update
    
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

# Define applications to launch
$applications = @(
    @{
        Name = "OBS Studio"
        Path = "obs64.exe"
        RequiresAdmin = $true
    },
    @{
        Name = "LM Studio"
        Path = "LM Studio.exe"
        RequiresAdmin = $true
    },
    @{
        Name = "AnythingLLM"
        Path = "AnythingLLM.exe"
        RequiresAdmin = $false
    },
    @{
        Name = "Obsidian"
        Path = "Obsidian.exe"
        RequiresAdmin = $false
    },
    @{
        Name = "Stream Deck"
        Path = "StreamDeck.exe"
        RequiresAdmin = $false
    },
    @{
        Name = "Visual Studio Code"
        Path = "Code.exe"
        RequiresAdmin = $false
    },
    @{
        Name = "Docker Desktop"
        Path = "Docker Desktop.exe"
        RequiresAdmin = $false
    }
)

# Launch applications
foreach ($app in $applications) {
    $appPath = (Get-Command $app.Path -ErrorAction SilentlyContinue)
    if ($appPath) {
        $verb = if ($app.RequiresAdmin) { "RunAs" } else { "" }
        Write-DebugWithColor "Launching $($app.Name)" "Blue"
        Start-ProcessWithCheck -ProcessPath $appPath -Verb $verb
    } else {
        Write-Host "[WARNING] $($app.Name) not found in system PATH." -ForegroundColor Yellow
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

Write-DebugWithColor "Script completed on $(Get-Date)" "Green"

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

Write-DebugWithColor "Pulling Second Brain Repo for obsidian to Use" "Green"
# Change directory to the project path
Set-Location "C:\projects\secondbrain"
git pull

# Open Twitter/X messages
Start-Process "https://x.com/messages"

# Open LinkedIn messages
Start-Process "https://www.linkedin.com/messaging/"

# Open local LinkedIn n8n
Start-Process "http://localhost:5678/" # Replace with the actual URL if different

# Get RAM information
$RAM = Get-WmiObject Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory

# Calculate RAM usage
$RAMUsed = $RAM.TotalVisibleMemorySize - $RAM.FreePhysicalMemory
$RAMPercentUsed = ($RAMUsed / $RAM.TotalVisibleMemorySize) * 100

# Display RAM information
Write-Host "Total RAM: $($RAM.TotalVisibleMemorySize/1GB) GB"
Write-Host "Free RAM: $($RAM.FreePhysicalMemory/1GB) GB"
Write-Host "RAM Usage: $([Math]::Round($RAMPercentUsed, 2))%"

# Get disk usage information
Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object { # DriveType 3 represents local disks
    $DiskSize = $_.Size
    $DiskFree = $_.FreeSpace
    $DiskUsed = $DiskSize - $DiskFree
    $DiskPercentUsed = ($DiskUsed / $DiskSize) * 100
    if ($_.MediaType -ne $null) { # Check if MediaType property exists (it might be null for some drives)
        Write-Host "Drive $($_.DeviceID): $($_.MediaType)"
    } else {
        Write-Host "Drive $($_.DeviceID):"
    }
    Write-Host "  Total Size: $($DiskSize/1GB) GB"
    Write-Host "  Free Space: $($DiskFree/1GB) GB"
    Write-Host "  Disk Usage: $([Math]::Round($DiskPercentUsed, 2))%"
}


# Set window positions
Add-Type -AssemblyName System.Windows.Forms

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
}

if ($chrome) {
  $chrome.WaitForInputIdle()
    $chrome.MainWindowHandle | ForEach-Object {
      [System.Windows.Forms.Control]::FromHandle($_).Location = New-Object System.Drawing.Point(1920,0) #first monitor, assumed to be index 0 (0-indexed)
      [System.Windows.Forms.Control]::FromHandle($_).WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    }
}

if ($obs) {
  $obs.WaitForInputIdle()
   $obs.MainWindowHandle | ForEach-Object {
      [System.Windows.Forms.Control]::FromHandle($_).Location = New-Object System.Drawing.Point(3840,0) #third monitor, assumed to be index 2 (0-indexed)
      [System.Windows.Forms.Control]::FromHandle($_).WindowState = [System.Windows.Forms.FormWindowState]::Maximized
     }
}




# Display "end" message
Write-ColoredAscii -Text $endAscii -ForegroundColor Cyan



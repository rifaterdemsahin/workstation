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

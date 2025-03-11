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

# Set log file path on Desktop
$logFile = "$env:USERPROFILE\Desktop\Startup_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host $Message
}

# Function to write colored debug messages
function Write-DebugWithColor {
    param (
        [string]$Message,
        [string]$Color = "Cyan"
    )
    Write-Host "[DEBUG] $Message" -ForegroundColor $Color
    Write-Log "[DEBUG] $Message"
}

# Function to display colored ASCII art
function Write-ColoredAscii {
    param(
        [string]$Text,
        [string]$ForegroundColor = "White",
        [string]$BackgroundColor = "Black"
    )
    Write-Host $Text -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    Write-Log $Text
}

# Function to start a process with error handling
function Start-ProcessWithCheck {
    param (
        [string]$ProcessPath,
        [string[]]$Arguments = @(),
        [string]$Verb = "",
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
            Write-Log "[ERROR] Failed to start process: $ProcessPath. Error: $_"
        }
    } else {
        Write-Host "[WARNING] Process not found at: $ProcessPath" -ForegroundColor Yellow
        Write-Log "[WARNING] Process not found at: $ProcessPath"
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
    "https://chatgpt.com/?hints=search&ref=ext&model=auto",
    "https://claude.ai/new",
    "https://to-do.office.com/tasks/",
    "https://www.perplexity.ai/",
    "https://www.linkedin.com/",
    "https://www.gmail.com/",
    "https://vdo.ninja/?director=rifaterdemsahin",
    "https://calendly.com/app/scheduled_events/user/me",
    "https://github.com/n8n-io/n8n",
    "https://www.notion.so/",
    "https://x.com/i/grok",
    "https://rifaterdemsahinblog.wordpress.com/wp-admin/post-new.php?post_type=post&calypsoify=1&block-editor=1&frame-nonce=3e1e1b7b1b&origin=https%3A%",
    "https://github.com/rifaterdemsahin/workstation/edit/master/6_Symbols/startup/start_up_script.ps1",
    "https://mail.google.com/mail/u/0/#advanced-search/is_unread=true&query=label%3A1_borrow_followup&isrefinement=true",
    "https://192-168-9-34.petersfieldmansions.direct.quickconnect.to:5001/"
)

# Launch Chrome with specific profile
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$chromeArgs = @("--profile-directory=`"Profile 21`"")
foreach ($url in $urls) {
    Write-DebugWithColor "Opening URL: $url" "DarkCyan"
    try {
        Start-ProcessWithCheck -ProcessPath $chromePath -Arguments ($chromeArgs + $url)
    } catch {
        Write-Host "[ERROR] Failed to open URL: $url. Error: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to open URL: $url. Error: $_"
    }
}

# Define applications to launch with updated paths
$applications = @(
    @{
        Name = "OBS Studio"
        Path = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
        RequiresAdmin = $true
    },
    @{
        Name = "LM Studio"
        Path = "C:\Users\Pexabo\AppData\Local\Programs\LM Studio\LM Studio.exe"
        RequiresAdmin = $true
    },
    @{
        Name = "AnythingLLM"
        Path = "C:\Users\Pexabo\AppData\Local\Programs\AnythingLLM\AnythingLLM.exe"
        RequiresAdmin = $false
    },
    @{
        Name = "Obsidian"
        Path = "C:\Users\Pexabo\AppData\Local\Programs\Obsidian\Obsidian.exe"
        RequiresAdmin = $false
    },
    @{
        Name = "Stream Deck"
        Path = "C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"
        RequiresAdmin = $false
    },
    @{
        Name = "Visual Studio Code"
        Path = "C:\Program Files\Microsoft VS Code\Code.exe"
        RequiresAdmin = $false
    },
    @{
        Name = "Docker Desktop"
        Path = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
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
        Write-Log "[WARNING] $($app.Name) not found at: $($app.Path)"
    }
}

# Ping test
Write-DebugWithColor "Testing network latency to 1.1.1.1" "Yellow"
$pingResults = Test-Connection -ComputerName "1.1.1.1" -Count 4
$avgPing = ($pingResults | Measure-Object -Property ResponseTime -Average).Average
Write-Host "Average ping to 1.1.1.1: $avgPing ms" -ForegroundColor $(if ($avgPing -gt 20) {"Red"} else {"Green"})
Write-Log "Average ping to 1.1.1.1: $avgPing ms"

# ... [Rest of your script remains the same until the end] ...

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
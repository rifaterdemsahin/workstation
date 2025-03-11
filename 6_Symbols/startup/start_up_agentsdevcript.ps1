# Startup Script Configuration
$Config = @{
    LogFile = "$env:USERPROFILE\Desktop\Startup_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    ChromeProfile = "--profile-directory=`"Profile 21`""
    StartAscii = @"
  _,-._
 / \_/ \
>-(_)-<
 \_/ \_/
  `-'
"@
    EndAscii = @"
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

# Application Definitions
$Applications = @(
    @{ Name = "OBS Studio"; Path = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"; RequiresAdmin = $true }
    @{ Name = "LM Studio"; Path = "C:\Users\Pexabo\AppData\Local\Programs\LM Studio\LM Studio.exe"; RequiresAdmin = $true }
    @{ Name = "AnythingLLM"; Path = "C:\Users\Pexabo\AppData\Local\Programs\AnythingLLM\AnythingLLM.exe"; RequiresAdmin = $false }
    @{ Name = "Obsidian"; Path = "C:\Users\Pexabo\AppData\Local\Programs\Obsidian\Obsidian.exe"; RequiresAdmin = $false }
    @{ Name = "Stream Deck"; Path = "C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"; RequiresAdmin = $false }
    @{ Name = "Visual Studio Code"; Path = "C:\Program Files\Microsoft VS Code\Code.exe"; RequiresAdmin = $false }
    @{ Name = "Docker Desktop"; Path = "C:\Program Files\Docker\Docker\Docker Desktop.exe"; RequiresAdmin = $false }
)

# URL Definitions
$Urls = @(
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

$CommUrls = @(
    "https://x.com/messages",
    "https://www.linkedin.com/messaging/",
    "http://localhost:5678/"  # n8n
)

# Enable debugging output
$DebugPreference = "Continue"

# Utility Functions
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $Config.LogFile -Append
    Write-Host $Message
}

function Write-DebugWithColor {
    param (
        [string]$Message,
        [string]$Color = "Cyan"
    )
    Write-Host "[DEBUG] $Message" -ForegroundColor $Color
    Write-Log "[DEBUG] $Message"
}

function Write-ColoredAscii {
    param(
        [string]$Text,
        [string]$ForegroundColor = "White",
        [string]$BackgroundColor = "Black"
    )
    Write-Host $Text -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    Write-Log $Text
}

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

# Main Functions
function Initialize-Environment {
    Write-ColoredAscii -Text $Config.StartAscii -ForegroundColor Green
    Write-DebugWithColor "Workstation Automation Started" "Green"
    Write-DebugWithColor "Script started on $(Get-Date)" "Green"
    Write-DebugWithColor "Minimizing all windows" "Yellow"
    (New-Object -ComObject Shell.Application).MinimizeAll()
}

function Launch-BrowserContent {
    $chromeArgs = @($Config.ChromeProfile)
    foreach ($url in $Urls) {
        Write-DebugWithColor "Opening URL: $url" "DarkCyan"
        Start-ProcessWithCheck -ProcessPath $Config.ChromePath -Arguments ($chromeArgs + $url)
    }
    Write-DebugWithColor "Opening communication channels" "Blue"
    foreach ($url in $CommUrls) {
        Start-ProcessWithCheck -ProcessPath $Config.ChromePath -Arguments ($chromeArgs + $url)
    }
}

function Launch-Applications {
    foreach ($app in $Applications) {
        $verb = if ($app.RequiresAdmin) { "RunAs" } else { "" }
        Write-DebugWithColor "Launching $($app.Name)" "Blue"
        Start-ProcessWithCheck -ProcessPath $app.Path -Verb $verb
    }
}

function Update-System {
    Write-DebugWithColor "Updating Chocolatey packages" "Yellow"
    try {
        Start-ProcessWithCheck -ProcessPath "cmd.exe" -Arguments "/c choco upgrade all -y" -Verb "RunAs"
    } catch {
        Write-Host "[ERROR] Failed to initiate Chocolatey update: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to initiate Chocolatey update: $_"
    }

    Write-DebugWithColor "Opening Windows Update settings" "Yellow"
    try {
        Start-ProcessWithCheck -ProcessPath "ms-settings:windowsupdate"
    } catch {
        Write-Host "[ERROR] Failed to open Windows Update: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to open Windows Update: $_"
    }
}

function Sync-Repositories {
    Write-DebugWithColor "Pulling Second Brain Repo" "Green"
    try {
        if (Test-Path "C:\projects\secondbrain") {
            Set-Location "C:\projects\secondbrain"
            git pull
            Write-DebugWithColor "Successfully pulled Second Brain repo" "Green"
        } else {
            Write-Host "[WARNING] Second Brain repo not found" -ForegroundColor Yellow
            Write-Log "[WARNING] Second Brain repo not found"
        }
    } catch {
        Write-Host "[ERROR] Failed to pull Second Brain repo: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to pull Second Brain repo: $_"
    }
}

function Test-Network {
    Write-DebugWithColor "Testing network latency to 1.1.1.1" "Yellow"
    $pingResults = Test-Connection -ComputerName "1.1.1.1" -Count 4
    $avgPing = ($pingResults | Measure-Object -Property ResponseTime -Average).Average
    Write-Host "Average ping to 1.1.1.1: $avgPing ms" -ForegroundColor $(if ($avgPing -gt 20) {"Red"} else {"Green"})
    Write-Log "Average ping to 1.1.1.1: $avgPing ms"
}

function Get-SystemInfo {
    $RAM = Get-WmiObject Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory
    $RAMUsed = $RAM.TotalVisibleMemorySize - $RAM.FreePhysicalMemory
    $RAMTotalGB = [math]::Round($RAM.TotalVisibleMemorySize/1MB, 2)
    $RAMFreeGB = [math]::Round($RAM.FreePhysicalMemory/1MB, 2)
    $RAMPercentUsed = [math]::Round(($RAMUsed / $RAM.TotalVisibleMemorySize) * 100, 2)

    Write-Host "`n=======================================" -ForegroundColor Blue
    Write-Host "SYSTEM INFORMATION" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Blue
    Write-Host "Total RAM: $RAMTotalGB GB"
    Write-Host "Free RAM: $RAMFreeGB GB"
    Write-Host "RAM Usage: $RAMPercentUsed%" -ForegroundColor $(if ($RAMPercentUsed -gt 80) {"Red"} elseif ($RAMPercentUsed -gt 60) {"Yellow"} else {"Green"})
    Write-Log "RAM Info - Total: $RAMTotalGB GB, Free: $RAMFreeGB GB, Usage: $RAMPercentUsed%"

    Write-Host "`n=======================================" -ForegroundColor Blue
    Write-Host "DISK INFORMATION" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Blue
    Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object {
        $DiskSizeGB = [math]::Round($_.Size/1GB, 2)
        $DiskFreeGB = [math]::Round($_.FreeSpace/1GB, 2)
        $DiskPercentUsed = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
        
        Write-Host "Drive $($_.DeviceID):" -ForegroundColor White
        Write-Host "  Total Size: $DiskSizeGB GB"
        Write-Host "  Free Space: $DiskFreeGB GB"
        Write-Host "  Disk Usage: $DiskPercentUsed%" -ForegroundColor $(if ($DiskPercentUsed -gt 90) {"Red"} elseif ($DiskPercentUsed -gt 75) {"Yellow"} else {"Green"})
        Write-Log "Disk $($_.DeviceID) - Total: $DiskSizeGB GB, Free: $DiskFreeGB GB, Usage: $DiskPercentUsed%"
    }
}

function Position-Windows {
    Write-DebugWithColor "Attempting to set window positions" "Magenta"
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Start-Sleep -Seconds 3

        $windows = @(
            @{ Process = "WhatsApp"; X = 0; Y = 0 },
            @{ Process = "Chrome"; X = 1920; Y = 0 },
            @{ Process = "OBS"; X = 3840; Y = 0 }
        )

        foreach ($win in $windows) {
            $proc = Get-Process | Where-Object {$_.MainWindowTitle -like "*$($win.Process)*"}
            if ($proc) {
                $proc.WaitForInputIdle()
                $proc.MainWindowHandle | ForEach-Object {
                    $control = [System.Windows.Forms.Control]::FromHandle($_)
                    $control.Location = New-Object System.Drawing.Point($win.X, $win.Y)
                    $control.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
                }
                Write-DebugWithColor "$($win.Process) window positioned" "Green"
            } else {
                Write-Host "[INFO] $($win.Process) window not found" -ForegroundColor Yellow
                Write-Log "[INFO] $($win.Process) window not found"
            }
        }
    } catch {
        Write-Host "[ERROR] Failed to set window positions: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set window positions: $_"
    }
}

# Main Execution
Initialize-Environment
Launch-BrowserContent
Launch-Applications
Update-System
Sync-Repositories
Test-Network
Get-SystemInfo
Position-Windows

Write-DebugWithColor "Script completed on $(Get-Date)" "Green"
Write-ColoredAscii -Text $Config.EndAscii -ForegroundColor Cyan

Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "✅ All startup applications launched!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Yellow

$close = Read-Host "Press Enter to close or type 'stay' to keep open"
if ($close -ne "stay") {
    Write-DebugWithColor "Closing terminal" "Green"
    Stop-Process -Id $PID
} else {
    Write-DebugWithColor "Terminal remains open" "Green"
}

todo : Open visual studio code  for this folder C:\projects\workstation\
todo : Open visual studio code  for this folder C:\projects\secondbrain\
todo: open gimp "C:\Program Files\GIMP 2\bin\gimp-2.10.exe"
todo: open manusai web page

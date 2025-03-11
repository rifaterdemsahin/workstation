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

$Applications = @(
    @{ Name = "OBS Studio"; Path = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"; RequiresAdmin = $true }
    @{ Name = "LM Studio"; Path = "C:\Users\Pexabo\AppData\Local\Programs\LM Studio\LM Studio.exe"; RequiresAdmin = $true }
    @{ Name = "AnythingLLM"; Path = "C:\Users\Pexabo\AppData\Local\Programs\AnythingLLM\AnythingLLM.exe"; RequiresAdmin = $false }
    @{ Name = "Obsidian"; Path = "C:\Users\Pexabo\AppData\Local\Programs\Obsidian\Obsidian.exe"; RequiresAdmin = $false }
    @{ Name = "Stream Deck"; Path = "C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"; RequiresAdmin = $false }
    @{ Name = "Visual Studio Code"; Path = "C:\Program Files\Microsoft VS Code\Code.exe"; RequiresAdmin = $false }
    @{ Name = "Docker Desktop"; Path = "C:\Program Files\Docker\Docker\Docker Desktop.exe"; RequiresAdmin = $false }
    @{ Name = "GIMP"; Path = "C:\Program Files\GIMP 2\bin\gimp-2.10.exe"; RequiresAdmin = $false }
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
    "https://github.com/rifaterdemsahin/workstation/edit/master/6_Symbols/startup/start_up_script.ps1"
    "https://mail.google.com/mail/u/0/#advanced-search/is_unread=true&query=label%3A1_borrow_followup&isrefinement=true"
    "https://petersfieldmansions.direct.quickconnect.to:5001/"
    "https://manusai.com/"
)

$CommUrls = @(
    "https://x.com/messages"
    "https://www.linkedin.com/messaging/"
    "http://localhost:5678/"
)

$DebugPreference = "Continue"

# Ensure log directory exists
$logDir = Split-Path -Parent $Config.LogFile
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $Config.LogFile -Append
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
    param ([string]$ProcessPath, [string[]]$Arguments = @(), [string]$Verb = "", [string]$WorkingDirectory = "")
    if (Test-Path $ProcessPath) {
        try {
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.FileName = $ProcessPath
            $startInfo.Arguments = $Arguments -join " "
            if ($Verb) { $startInfo.Verb = $Verb }
            if ($WorkingDirectory) { $startInfo.WorkingDirectory = $WorkingDirectory }
            [System.Diagnostics.Process]::Start($startInfo) | Out-Null
            Write-Debug "Successfully launched: $ProcessPath" "Green"
        } catch {
            Write-Host "[ERROR] Failed to start $ProcessPath: $_" -ForegroundColor Red
            Write-Log "[ERROR] Failed to start $ProcessPath: $_"
        }
    } else {
        Write-Host "[WARNING] $ProcessPath not found" -ForegroundColor Yellow
        Write-Log "[WARNING] $ProcessPath not found"
    }
}

function Initialize-Environment {
    Write-Ascii $Config.StartAscii -ForegroundColor Green
    Write-Debug "Workstation Automation Started" "Green"
    Write-Debug "Script started on $(Get-Date)" "Green"
    Write-Debug "Minimizing all windows" "Yellow"
    (New-Object -ComObject Shell.Application).MinimizeAll()
}

function Launch-BrowserContent {
    $chromeArgs = @($Config.ChromeProfile)
    $Urls | ForEach-Object {
        Write-Debug "Opening URL: $_" "DarkCyan"
        Start-ProcessEx $Config.ChromePath ($chromeArgs + $_)
    }
    Write-Debug "Opening communication channels" "Blue"
    $CommUrls | ForEach-Object {
        Start-ProcessEx $Config.ChromePath ($chromeArgs + $_)
    }
}

function Launch-Applications {
    $Applications | ForEach-Object {
        $verb = if ($_.RequiresAdmin) { "RunAs" } else { "" }
        Write-Debug "Launching $($_.Name)" "Blue"
        if ($_.Name -eq "Visual Studio Code") {
            Start-ProcessEx $_.Path "C:\projects\workstation\"
            Start-ProcessEx $_.Path "C:\projects\secondbrain\"
        } else {
            Start-ProcessEx $_.Path -Verb $verb
        }
    }
}

function Update-System {
    Write-Debug "Updating Chocolatey packages" "Yellow"
    try { Start-ProcessEx "cmd.exe" "/c choco upgrade all -y" -Verb "RunAs" }
    catch { Write-Log "[ERROR] Chocolatey update failed: $_" }

    Write-Debug "Opening Windows Update settings" "Yellow"
    try { Start-ProcessEx "ms-settings:windowsupdate" }
    catch { Write-Log "[ERROR] Failed to open Windows Update: $_" }
}

function Sync-Repositories {
    Write-Debug "Pulling Second Brain Repo" "Green"
    if (Test-Path "C:\projects\secondbrain") {
        try {
            Set-Location "C:\projects\secondbrain"
            git pull
            Write-Debug "Successfully pulled Second Brain repo" "Green"
        } catch {
            Write-Host "[ERROR] Second Brain pull failed: $_" -ForegroundColor Red
            Write-Log "[ERROR] Second Brain pull failed: $_"
        }
    } else {
        Write-Host "[WARNING] Second Brain repo not found" -ForegroundColor Yellow
        Write-Log "[WARNING] Second Brain repo not found"
    }
}

function Test-Network {
    Write-Debug "Testing network latency to 1.1.1.1" "Yellow"
    $pingResults = Test-Connection -ComputerName "1.1.1.1" -Count 4
    $avgPing = ($pingResults | Measure-Object -Property ResponseTime -Average).Average
    $color = if ($avgPing -gt 20) { "Red" } else { "Green" }
    Write-Host "Average ping to 1.1.1.1: $avgPing ms" -ForegroundColor $color
    Write-Log "Average ping to 1.1.1.1: $avgPing ms"
}

function Get-SystemInfo {
    Write-Host "`n=======================================" -ForegroundColor Blue
    Write-Host "SYSTEM INFORMATION" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Blue
    Get-RAMInfo

    Write-Host "`n=======================================" -ForegroundColor Blue
    Write-Host "DISK INFORMATION" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Blue
    Get-DiskInfo
}

function Get-RAMInfo {
    $RAM = Get-WmiObject Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory
    $RAMUsed = $RAM.TotalVisibleMemorySize - $RAM.FreePhysicalMemory
    $RAMTotalGB = [math]::Round($RAM.TotalVisibleMemorySize / 1MB, 2)
    $RAMFreeGB = [math]::Round($RAM.FreePhysicalMemory / 1MB, 2)
    $RAMPercentUsed = [math]::Round(($RAMUsed / $RAM.TotalVisibleMemorySize) * 100, 2)
    $color = if ($RAMPercentUsed -gt 80) { "Red" } elseif ($RAMPercentUsed -gt 60) { "Yellow" } else { "Green" }

    Write-Host "Total RAM: $RAMTotalGB GB"
    Write-Host "Free RAM: $RAMFreeGB GB"
    Write-Host "RAM Usage: $RAMPercentUsed%" -ForegroundColor $color
    Write-Log "RAM Info - Total: $RAMTotalGB GB, Free: $RAMFreeGB GB, Usage: $RAMPercentUsed%"
}

function Get-DiskInfo {
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
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
}

function Position-Windows {
    Write-Debug "Attempting to set window positions" "Magenta"
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Start-Sleep -Seconds 3

        $windows = @(
            @{ Process = "WhatsApp"; X = 0;   Y = 0 }
            @{ Process = "Chrome";  X = 1920; Y = 0 }
            @{ Process = "OBS";     X = 3840; Y = 0 }
        )

        $windows | ForEach-Object {
            $proc = Get-Process | Where-Object { $_.MainWindowTitle -like "*$($_.Process)*" }
            if ($proc) {
                $proc.WaitForInputIdle()
                $proc.MainWindowHandle | ForEach-Object {
                    $control = [System.Windows.Forms.Control]::FromHandle($_)
                    $control.Location = New-Object System.Drawing.Point($window.X, $window.Y)
                    $control.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
                }
                Write-Debug "$($_.Process) window positioned" "Green"
            } else {
                Write-Host "[INFO] $($_.Process) window not found" -ForegroundColor Yellow
                Write-Log "[INFO] $($_.Process) window not found"
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

Write-Debug "Script completed on $(Get-Date)" "Green"
Write-Ascii $Config.EndAscii -ForegroundColor Cyan

Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "✅ All startup applications launched!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Yellow

$close = Read-Host "Press Enter to close or type 'stay' to keep open"
if ($close -ne "stay") {
    Write-Debug "Closing terminal" "Green"
    Stop-Process -Id $PID
} else {
    Write-Debug "Terminal remains open" "Green"
}
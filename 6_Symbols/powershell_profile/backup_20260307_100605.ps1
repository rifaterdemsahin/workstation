# ==============================================================================
# PowerShell Profile - Enhanced with Emojis and Colors
# ==============================================================================
# Location: C:\Users\Pexabo\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
# Repository: C:\projects\workstation\6_Symbols\powershell_profile
# ==============================================================================

# Profile Welcome Message
$rocket = [System.Char]::ConvertFromUtf32(0x1F680)
$sparkles = [System.Char]::ConvertFromUtf32(0x2728)
Write-Host "`n$rocket PowerShell Profile Loaded! $sparkles`n" -ForegroundColor Cyan

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================
$env:GOOGLE_CLOUD_PROJECT = "leafy-winter-477609-k0"

# ==============================================================================
# CHOCOLATEY INTEGRATION
# ==============================================================================
# Import the Chocolatey Profile for tab-completions
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# ==============================================================================
# CUSTOM FUNCTIONS
# ==============================================================================

# Update All - Update Winget, Windows, and Chocolatey packages
function update-all {
    $package = [System.Char]::ConvertFromUtf32(0x1F4E6)
    $check = [System.Char]::ConvertFromUtf32(0x2705)

    Write-Host "`n$package Starting Winget package upgrades..." -ForegroundColor Green
    winget upgrade --all

    Write-Host "`n$package Starting Windows Update..." -ForegroundColor Green
    Install-WindowsUpdate -AcceptAll -AutoReboot

    Write-Host "`n$package Starting Chocolatey package upgrades..." -ForegroundColor Green
    choco upgrade all -y

    Write-Host "`n$check All updates complete!`n" -ForegroundColor Cyan
}

# Quick navigation to DaVinci Resolve logs
function dvl {
    $folder = [System.Char]::ConvertFromUtf32(0x1F4C1)
    Write-Host "$folder Navigating to DaVinci Resolve logs..." -ForegroundColor Yellow
    Set-Location "C:\Users\Pexabo\AppData\Roaming\Blackmagic Design\DaVinci Resolve\Support\logs"
}

# Reset Stream Deck - Kills Stream Deck, sets LG as primary, restarts Stream Deck
function reset-streamdeck {
    $wrench = [System.Char]::ConvertFromUtf32(0x1F527)
    Write-Host "$wrench Resetting Stream Deck..." -ForegroundColor Magenta
    & powershell -ExecutionPolicy Bypass -File "C:\projects\workstation\6_Symbols\streamdeck\Reset-StreamDeck.ps1"
}

# Raspberry Pi Pico 2 W - Send text via WiFi
function Send-ToPico {
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [string]$Text,

        [Parameter(Mandatory=$false)]
        [switch]$Clipboard,

        [Parameter(Mandatory=$false)]
        [switch]$Base64
    )

    $ProjectDir = "C:\projects\raspberry-pico-2-hid"
    $wifi = [System.Char]::ConvertFromUtf32(0x1F4F6)

    Push-Location $ProjectDir

    try {
        if ($Clipboard) {
            Write-Host "$wifi Sending clipboard to Pico..." -ForegroundColor Cyan
            if ($Base64) {
                python send_wifi_windows.py --clip --base64
            } else {
                python send_wifi_windows.py --clip
            }
        }
        elseif ($Text) {
            Write-Host "$wifi Sending text to Pico: $Text" -ForegroundColor Cyan
            if ($Base64) {
                $Text | python send_wifi_windows.py --stdin --base64
            } else {
                $Text | python send_wifi_windows.py --stdin
            }
        }
        else {
            $info = [System.Char]::ConvertFromUtf32(0x2139)
            Write-Host "$info Usage: Send-ToPico 'text to send'" -ForegroundColor Yellow
            Write-Host "$info        Send-ToPico -Clipboard" -ForegroundColor Yellow
            Write-Host "$info        Send-ToPico 'text' -Base64  (preserves all special chars)" -ForegroundColor Yellow
        }
    }
    finally {
        Pop-Location
    }
}

# GPU Diagnostics - Run GPU diagnostic script
function gpu-diag {
    param(
        [switch]$Once
    )

    $gpu = [System.Char]::ConvertFromUtf32(0x1F3AE)
    Write-Host "$gpu Running GPU Diagnostics..." -ForegroundColor Cyan

    if ($Once) {
        powershell -ExecutionPolicy Bypass -Command "& { `$RunContinuously = `$false; & 'C:\projects\workstation\6_Symbols\startup\desktopscripts\gpudiag\GPU_Diagnostic_Startup.ps1' }"
    }
    else {
        powershell -ExecutionPolicy Bypass -File "C:\projects\workstation\6_Symbols\startup\desktopscripts\gpudiag\GPU_Diagnostic_Startup.ps1"
    }
}

# Quick Git Status
function gs {
    $git = [System.Char]::ConvertFromUtf32(0x1F4BB)
    Write-Host "$git Git Status:" -ForegroundColor Cyan
    git status
}

# Quick Git Add All, Commit, and Push
function gcp {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Message
    )

    $git = [System.Char]::ConvertFromUtf32(0x1F4BB)
    Write-Host "$git Git: Add, Commit, Push..." -ForegroundColor Cyan
    git add .
    git commit -m $Message
    git push
}

# System Information with Emojis
function sysinfo {
    $computer = [System.Char]::ConvertFromUtf32(0x1F4BB)
    $memory = [System.Char]::ConvertFromUtf32(0x1F9E0)
    $disk = [System.Char]::ConvertFromUtf32(0x1F4BE)

    Write-Host "`n$computer System Information" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor DarkCyan

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $mem = Get-CimInstance Win32_PhysicalMemory
    $totalRAM = ($mem | Measure-Object -Property Capacity -Sum).Sum / 1GB

    Write-Host "OS: $($os.Caption)" -ForegroundColor White
    Write-Host "CPU: $($cpu.Name)" -ForegroundColor White
    Write-Host "$memory RAM: $([math]::Round($totalRAM, 2)) GB" -ForegroundColor White

    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
    foreach ($drive in $drives) {
        $usedGB = [math]::Round($drive.Used / 1GB, 2)
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        $totalGB = $usedGB + $freeGB
        $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 2)

        Write-Host "$disk Drive $($drive.Name): $usedGB GB / $totalGB GB ($usedPercent% used)" -ForegroundColor White
    }
    Write-Host ""
}

# Quick project navigation
function proj {
    param(
        [Parameter(Position=0)]
        [string]$Name
    )

    $folder = [System.Char]::ConvertFromUtf32(0x1F4C1)

    if ($Name) {
        $projectPath = "C:\projects\$Name"
        if (Test-Path $projectPath) {
            Write-Host "$folder Navigating to project: $Name" -ForegroundColor Cyan
            Set-Location $projectPath
        }
        else {
            $cross = [System.Char]::ConvertFromUtf32(0x274C)
            Write-Host "$cross Project not found: $projectPath" -ForegroundColor Red
        }
    }
    else {
        Write-Host "$folder Navigating to projects directory..." -ForegroundColor Cyan
        Set-Location "C:\projects"
    }
}

# List all custom functions
function Show-ProfileFunctions {
    $bulb = [System.Char]::ConvertFromUtf32(0x1F4A1)
    Write-Host "`n$bulb Custom PowerShell Functions:" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor DarkCyan
    Write-Host "update-all        - Update Winget, Windows, and Chocolatey" -ForegroundColor White
    Write-Host "dvl               - Navigate to DaVinci Resolve logs" -ForegroundColor White
    Write-Host "reset-streamdeck  - Reset Stream Deck configuration" -ForegroundColor White
    Write-Host "Send-ToPico       - Send text to Raspberry Pi Pico (alias: pico)" -ForegroundColor White
    Write-Host "gpu-diag          - Run GPU diagnostics (use -Once for single run)" -ForegroundColor White
    Write-Host "gs                - Quick git status" -ForegroundColor White
    Write-Host "gcp 'message'     - Git add, commit, push in one command" -ForegroundColor White
    Write-Host "sysinfo           - Display system information" -ForegroundColor White
    Write-Host "proj [name]       - Navigate to C:\projects\[name]" -ForegroundColor White
    Write-Host "Show-ProfileFunctions - Show this help" -ForegroundColor White
    Write-Host ""
}

# ==============================================================================
# ALIASES
# ==============================================================================
Set-Alias -Name pico -Value Send-ToPico -Scope Global -Option AllScope
Set-Alias -Name help-profile -Value Show-ProfileFunctions
Set-Alias -Name ll -Value Get-ChildItem

# ==============================================================================
# PROMPT CUSTOMIZATION
# ==============================================================================
function prompt {
    $location = Get-Location
    $gitBranch = ""

    # Check if in a git repository
    $gitStatus = git rev-parse --abbrev-ref HEAD 2>$null
    if ($gitStatus) {
        $branch = [System.Char]::ConvertFromUtf32(0x1F333)
        $gitBranch = " $branch $gitStatus"
    }

    $prompt = [System.Char]::ConvertFromUtf32(0x1F4BB)
    Write-Host "$prompt " -NoNewline -ForegroundColor Cyan
    Write-Host "$location" -NoNewline -ForegroundColor Yellow
    if ($gitBranch) {
        Write-Host "$gitBranch" -NoNewline -ForegroundColor Green
    }

    return "`n> "
}

# ==============================================================================
# AUTO-BACKUP PROFILE
# ==============================================================================
# Auto-backup profile on startup (once per day)
$backupScript = "C:\projects\workstation\6_Symbols\powershell_profile\backup_powershell_profile.ps1"
$lastBackupFile = "C:\projects\workstation\6_Symbols\powershell_profile\.last_backup"

if (Test-Path $backupScript) {
    $shouldBackup = $false

    if (Test-Path $lastBackupFile) {
        try {
            $lastBackup = Get-Content $lastBackupFile -ErrorAction SilentlyContinue
            $lastBackupDate = [DateTime]::ParseExact($lastBackup, "yyyy-MM-dd", $null)

            if ($lastBackupDate -lt (Get-Date).Date) {
                $shouldBackup = $true
            }
        }
        catch {
            $shouldBackup = $true
        }
    }
    else {
        $shouldBackup = $true
    }

    if ($shouldBackup) {
        $floppy = [System.Char]::ConvertFromUtf32(0x1F4BE)
        Write-Host "$floppy Backing up PowerShell profile..." -ForegroundColor DarkYellow
        & $backupScript
        (Get-Date -Format "yyyy-MM-dd") | Out-File -FilePath $lastBackupFile -Force
    }
}

# ==============================================================================
# HELPFUL TIPS
# ==============================================================================
$info = [System.Char]::ConvertFromUtf32(0x2139)
Write-Host "$info Type 'help-profile' or 'Show-ProfileFunctions' to see available commands`n" -ForegroundColor DarkGray

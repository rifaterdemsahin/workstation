#Requires -Version 5.1
<#
.SYNOPSIS
    Startup App Manager - Lists running apps, suggests ones to close,
    remembers your choices, and offers bulk-close on next boot.

.NOTES
    Place this script anywhere, then register it as a Scheduled Task
    (see bottom of file for the registration command).
#>

# ──────────────────────────────────────────────────────────────────────────────
# CONFIG
# ──────────────────────────────────────────────────────────────────────────────
$ConfigDir  = "$env:APPDATA\StartupAppManager"
$HistoryFile = "$ConfigDir\closed_history.json"

# Processes that are ALWAYS skipped (system / shell / this script itself)
$SystemExclusions = @(
    'svchost','csrss','smss','lsass','wininit','winlogon','services',
    'System','Registry','Idle','dwm','fontdrvhost','conhost',
    'powershell','pwsh','cmd','explorer','SearchHost','StartMenuExperienceHost',
    'ShellExperienceHost','RuntimeBroker','sihost','taskhostw','ctfmon',
    'audiodg','spoolsv','WmiPrvSE','MsMpEng','SecurityHealthSystray',
    'NisSrv','SgrmBroker','dllhost','backgroundTaskHost','ApplicationFrameHost',
    'TextInputHost','UserOOBEBroker','LockApp','LogonUI'
)

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────────────────────
function Initialize-Config {
    if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir | Out-Null }
    if (-not (Test-Path $HistoryFile)) { '[]' | Set-Content $HistoryFile -Encoding UTF8 }
}

function Load-History {
    try {
        $json = Get-Content $HistoryFile -Raw -ErrorAction Stop | ConvertFrom-Json
        return @($json)
    }
    catch { return ,@() }
}

function Save-History($data) {
    ConvertTo-Json -InputObject @($data) -Depth 5 | Set-Content $HistoryFile -Encoding UTF8
}

function Get-UserApps {
    Get-Process | Where-Object {
        $_.MainWindowHandle -ne 0 -and
        $_.ProcessName -notin $SystemExclusions -and
        $_.Id -ne $PID
    } | Sort-Object ProcessName -Unique
}

function Write-Header($text) {
    Write-Host ""
    Write-Host ("─" * 60) -ForegroundColor DarkGray
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ("─" * 60) -ForegroundColor DarkGray
}

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║       STARTUP APP MANAGER  by Erdem          ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN LOGIC
# ──────────────────────────────────────────────────────────────────────────────
Initialize-Config
Write-Banner

[array]$history = Load-History
$apps    = Get-UserApps

# ── 1. BULK-CLOSE OFFER FROM PREVIOUS SESSION ────────────────────────────────
if ($history.Count -gt 0) {
    Write-Header "Apps you closed last time"
    Write-Host ""
    $i = 1
    $prevNames = $history | Sort-Object -Unique
    foreach ($name in $prevNames) {
        $running = Get-Process -Name $name -ErrorAction SilentlyContinue
        $status  = if ($running) { "[RUNNING]" } else { "[not running]" }
        $color   = if ($running) { "Yellow" } else { "DarkGray" }
        Write-Host ("  {0,2}. {1,-35} {2}" -f $i, $name, $status) -ForegroundColor $color
        $i++
    }
    Write-Host ""
    Write-Host "  [B] Bulk-close all running ones from history" -ForegroundColor Green
    Write-Host "  [S] Skip" -ForegroundColor DarkGray
    Write-Host ""
    $choice = Read-Host "  Your choice"

    if ($choice -match '^[Bb]$') {
        foreach ($name in $prevNames) {
            $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                try {
                    $p.CloseMainWindow() | Out-Null
                    Start-Sleep -Milliseconds 400
                    if (-not $p.HasExited) { $p | Stop-Process -Force }
                    Write-Host "  ✓ Closed: $name" -ForegroundColor Green
                } catch {
                    Write-Host "  ✗ Could not close: $name ($_)" -ForegroundColor Red
                }
            }
        }
        Write-Host ""
        Write-Host "  Bulk-close done. Exiting." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        exit
    }
}

# ── 2. LIST CURRENT RUNNING APPS ─────────────────────────────────────────────
# Refresh after possible bulk-close
$apps = Get-UserApps

if ($apps.Count -eq 0) {
    Write-Host "  No user applications are currently running." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    exit
}

Write-Header "Currently running applications"
Write-Host ""
$index = 1
$appList = @()
foreach ($proc in $apps) {
    $cpu = try { [math]::Round($proc.CPU, 1) } catch { "?" }
    $mem = [math]::Round($proc.WorkingSet64 / 1MB, 0)
    Write-Host ("  {0,2}. {1,-35} CPU:{2,6}s  RAM:{3,5} MB" -f `
        $index, $proc.ProcessName, $cpu, $mem) -ForegroundColor White
    $appList += $proc
    $index++
}

# ── 3. SUGGESTIONS (high memory / known background hogs) ─────────────────────
$HogPatterns = @('discord','spotify','teams','slack','onedrive','dropbox',
                 'steam','epicgameslauncher','googledrivefs','skype',
                 'zoom','lync','msteams','notion','obsidian')

$suggestions = $appList | Where-Object {
    ($_.WorkingSet64 / 1MB -gt 200) -or ($_.ProcessName -in $HogPatterns)
} | Select-Object -ExpandProperty ProcessName -Unique

Write-Host ""
Write-Host "  💡 Suggested candidates to close (high RAM or background apps):" -ForegroundColor DarkYellow

if ($suggestions.Count -gt 0) {
    $suggestions | ForEach-Object {
        $num = ($appList | Where-Object ProcessName -eq $_ | Select-Object -First 1)
        $idx = $appList.IndexOf($num) + 1
        Write-Host ("     #{0} {1}" -f $idx, $_) -ForegroundColor Yellow
    }
} else {
    Write-Host "     None detected." -ForegroundColor DarkGray
}

# ── 4. USER SELECTION ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Enter numbers to close (comma-separated), [A] for all suggested," -ForegroundColor Cyan
Write-Host "  or press ENTER to skip:  " -ForegroundColor Cyan -NoNewline
$userInput = Read-Host

$toClose = @()

if ($userInput -match '^[Aa]$') {
    $toClose = $suggestions
} elseif ($userInput.Trim() -ne '') {
    $nums = $userInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
    foreach ($n in $nums) {
        $idx = [int]$n - 1
        if ($idx -ge 0 -and $idx -lt $appList.Count) {
            $toClose += $appList[$idx].ProcessName
        }
    }
}

# ── 5. CLOSE SELECTED ────────────────────────────────────────────────────────
$closedThisSession = @()
if ($toClose.Count -gt 0) {
    Write-Host ""
    foreach ($name in ($toClose | Sort-Object -Unique)) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            try {
                $p.CloseMainWindow() | Out-Null
                Start-Sleep -Milliseconds 400
                if (-not $p.HasExited) { $p | Stop-Process -Force }
                Write-Host "  ✓ Closed: $name" -ForegroundColor Green
                $closedThisSession += $name
            } catch {
                Write-Host "  ✗ Failed: $name ($_)" -ForegroundColor Red
            }
        }
    }

    # Save to history (merge + deduplicate)
    $merged = @($history) + @($closedThisSession) | Sort-Object -Unique
    Save-History @($merged)
    Write-Host ""
    Write-Host "  Session saved to history." -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "  Nothing closed. Goodbye!" -ForegroundColor DarkGray
}

Start-Sleep -Seconds 2

# ──────────────────────────────────────────────────────────────────────────────
# HOW TO REGISTER AS A STARTUP TASK
# Run the block below ONCE in an elevated PowerShell to register the task:
# ──────────────────────────────────────────────────────────────────────────────
<#
$ScriptPath = "C:\Path\To\Manage-StartupApps.ps1"   # ← change this

$Action  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger -AtLogOn

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

Register-ScheduledTask `
    -TaskName   "StartupAppManager" `
    -Action     $Action `
    -Trigger    $Trigger `
    -Settings   $Settings `
    -RunLevel   Highest `
    -Description "Interactive startup app manager" `
    -Force
#>

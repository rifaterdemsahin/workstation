# =============================================================================
# addnote.ps1 - Second Brain Git Sync Script
# Triggered via StreamDeck Multi Action
#
# STREAMDECK SETUP NOTE:
#   Configure the "Open" action to run PowerShell with -NoExit flag:
#   powershell.exe -NoExit -ExecutionPolicy Bypass -File "path\to\addnote.ps1"
#   Without -NoExit the window closes the moment the script ends or errors.
#
# DEBUGGING:
#   Every run is logged to: C:\Temp\addnote_log.txt
#   Check that file if the window closes before you can read the output.
# =============================================================================

# --- Log file: survives window close, check this if window disappears ---
$logFile = "C:\Temp\addnote_log.txt"
if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}
Start-Transcript -Path $logFile -Append
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Transcript started -> $logFile" -ForegroundColor DarkGray

# Get the current date for default commit message
$date = Get-Date -Format "yyyy-MM-dd HH:mm"

# --- Header ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "   Second Brain - Add Note / Sync Script   " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Triggered from: StreamDeck Multi Action  " -ForegroundColor DarkGray
Write-Host "  Log file: $logFile" -ForegroundColor DarkGray
Write-Host ""

# --- VERBOSE: Show script location ---
Write-Host "[DEBUG] Script file   : $PSCommandPath" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Script started: $date" -ForegroundColor DarkCyan
Write-Host "[DEBUG] PowerShell ver: $($PSVersionTable.PSVersion)" -ForegroundColor DarkCyan
Write-Host ""

# 1. User Input
Write-Host "Enter commit message (Leave blank for 'Update $date'):" -ForegroundColor Yellow
$commitMessage = Read-Host " >"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Update $date"
}
Write-Host "[DEBUG] Commit message: '$commitMessage'" -ForegroundColor DarkCyan

# 2. Configuration
$remoteRepo = "origin"
$branch     = "main"
$repoPath   = "F:\secondbrain_v4\secondbrain\secondbrain\"

Write-Host "[DEBUG] Target repo   : $repoPath" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Remote/Branch : $remoteRepo / $branch" -ForegroundColor DarkCyan
Write-Host ""

# 3. Execution
Write-Host "--- Starting Git Automation ---" -ForegroundColor Cyan

# --- VERBOSE: Validate path exists before jumping into it ---
Write-Host "[DEBUG] Checking if repo path exists..." -ForegroundColor DarkCyan
if (-not (Test-Path $repoPath)) {
    Write-Host "ERROR: Repo path does not exist: $repoPath" -ForegroundColor Red
    Write-Host "       Check the drive letter and folder names." -ForegroundColor Red
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}
Write-Host "[DEBUG] Path exists: OK" -ForegroundColor DarkGreen

# Navigate to the second brain repo directory
Write-Host "[DEBUG] Changing location to: $repoPath" -ForegroundColor DarkCyan
Set-Location $repoPath
Write-Host "[DEBUG] Current location: $(Get-Location)" -ForegroundColor DarkCyan

# --- VERBOSE: Show what files are present ---
Write-Host "[DEBUG] Files in repo root:" -ForegroundColor DarkCyan
Get-ChildItem -Force | Select-Object Mode, LastWriteTime, Length, Name | Format-Table -AutoSize

# --- VERBOSE: Show git status before doing anything ---
Write-Host "[DEBUG] Git status before staging:" -ForegroundColor DarkCyan
git status
Write-Host ""

# Pull latest changes to avoid conflicts
Write-Host "Pulling from $remoteRepo/$branch..." -ForegroundColor Yellow
git pull $remoteRepo $branch
Write-Host "[DEBUG] git pull exit code: $LASTEXITCODE" -ForegroundColor DarkCyan
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Pull failed. Please resolve conflicts manually." -ForegroundColor Red
    Stop-Transcript
    Read-Host "Press Enter to close"   # Always ask before closing - never silent exit
    exit 1
}

# Stage all changes
Write-Host "Staging all changes..." -ForegroundColor Yellow
git add .
Write-Host "[DEBUG] git add exit code: $LASTEXITCODE" -ForegroundColor DarkCyan

# --- VERBOSE: Show what got staged ---
Write-Host "[DEBUG] Git status after staging:" -ForegroundColor DarkCyan
git status
Write-Host ""

# Commit with the provided or default message
Write-Host "Committing: '$commitMessage'" -ForegroundColor Yellow
git commit -m "$commitMessage"
Write-Host "[DEBUG] git commit exit code: $LASTEXITCODE" -ForegroundColor DarkCyan
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Nothing to commit or commit failed." -ForegroundColor DarkYellow
    Stop-Transcript
    Read-Host "Press Enter to close"   # Always ask before closing - never silent exit
    exit 1
}

# Push to remote
Write-Host "Pushing to $remoteRepo/$branch..." -ForegroundColor Yellow
git push $remoteRepo $branch
Write-Host "[DEBUG] git push exit code: $LASTEXITCODE" -ForegroundColor DarkCyan

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "          Process Complete!                 " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Log saved to: $logFile" -ForegroundColor DarkGray
Write-Host ""

Stop-Transcript

# Keep window open - required for StreamDeck Multi Action which closes terminal immediately
# Always ask before closing - never silent exit
Read-Host "Press Enter to close"

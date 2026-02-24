# =============================================================================
# addnote.ps1 - Second Brain Git Sync Script
# Triggered via StreamDeck Multi Action
#
# STREAMDECK MULTI ACTION ORDER:
#   1. Hotkey: Ctrl+C          (copy selected text)
#   2. Delay                   (let copy settle)
#   3. System: Open addnote.bat  <-- script reads clipboard itself, no paste needed
#
#   The script reads the clipboard with Get-Clipboard so there is no timing
#   dependency on StreamDeck's System: Text / paste action. Remove that step.
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

# --- DEBUG: Show script info ---
Write-Host "[DEBUG] Script file   : $PSCommandPath" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Script started: $date" -ForegroundColor DarkCyan
Write-Host "[DEBUG] PowerShell ver: $($PSVersionTable.PSVersion)" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# 1. COMMIT MESSAGE — read from clipboard first, fallback to manual input
#    StreamDeck copies text with Ctrl+C before opening this script.
#    Get-Clipboard captures it instantly without any paste timing issues.
# =============================================================================
$clipboardText = Get-Clipboard
Write-Host "[DEBUG] Clipboard contents: '$clipboardText'" -ForegroundColor DarkCyan

if (-not [string]::IsNullOrWhiteSpace($clipboardText)) {
    # Clipboard has content — use it, but let user confirm or override
    Write-Host ""
    Write-Host "Clipboard detected:" -ForegroundColor Cyan
    Write-Host "  $clipboardText" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Enter to use clipboard as commit message, or type a new one:" -ForegroundColor Yellow
    $userInput = Read-Host " >"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $commitMessage = $clipboardText
        Write-Host "[DEBUG] Using clipboard text as commit message" -ForegroundColor DarkCyan
    } else {
        $commitMessage = $userInput
        Write-Host "[DEBUG] Using manually typed commit message" -ForegroundColor DarkCyan
    }
} else {
    # No clipboard content — ask manually
    Write-Host "No clipboard text found." -ForegroundColor DarkYellow
    Write-Host "Enter commit message (Leave blank for 'Update $date'):" -ForegroundColor Yellow
    $userInput = Read-Host " >"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $commitMessage = "Update $date"
    } else {
        $commitMessage = $userInput
    }
}

Write-Host "[DEBUG] Final commit message: '$commitMessage'" -ForegroundColor DarkCyan

# =============================================================================
# 2. Configuration
# =============================================================================
$remoteRepo = "origin"
$branch     = "main"
$repoPath   = "F:\secondbrain_v4\secondbrain\secondbrain\"

Write-Host "[DEBUG] Target repo   : $repoPath" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Remote/Branch : $remoteRepo / $branch" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# 3. Execution
# =============================================================================
Write-Host "--- Starting Git Automation ---" -ForegroundColor Cyan

# Validate path exists before jumping into it
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
Write-Host ""

# Pull latest changes — show output so user can see what came down
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "Pulling from $remoteRepo/$branch..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
git pull $remoteRepo $branch
Write-Host "[DEBUG] git pull exit code: $LASTEXITCODE" -ForegroundColor DarkCyan
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Pull failed. Please resolve conflicts manually." -ForegroundColor Red
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}
Write-Host ""

# Stage all changes
Write-Host "Staging all changes..." -ForegroundColor Yellow
git add .
Write-Host "[DEBUG] git add exit code: $LASTEXITCODE" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# SHOW WHAT WILL BE COMMITTED — diff stat so user sees exactly what goes in
# =============================================================================
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "Changes about to be committed:" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
git diff --cached --stat
Write-Host ""
Write-Host "Full staged diff:" -ForegroundColor Cyan
git diff --cached --name-status
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Commit
Write-Host "Committing: '$commitMessage'" -ForegroundColor Yellow
git commit -m "$commitMessage"
Write-Host "[DEBUG] git commit exit code: $LASTEXITCODE" -ForegroundColor DarkCyan
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Nothing to commit or commit failed." -ForegroundColor DarkYellow
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}

# Push
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "Pushing to $remoteRepo/$branch..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
git push $remoteRepo $branch
Write-Host "[DEBUG] git push exit code: $LASTEXITCODE" -ForegroundColor DarkCyan

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "          Process Complete!                 " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Committed : $commitMessage" -ForegroundColor Green
Write-Host "  Log saved : $logFile" -ForegroundColor DarkGray
Write-Host ""

Stop-Transcript

# Keep window open - always ask before closing
Read-Host "Press Enter to close"

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

# Navigate to the configured path first, then find the actual git repo root
# This matters when $repoPath is a subfolder — git add . would miss files outside it
Write-Host "[DEBUG] Changing location to: $repoPath" -ForegroundColor DarkCyan
Set-Location $repoPath

$gitRoot = git rev-parse --show-toplevel 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not inside a git repo at: $repoPath" -ForegroundColor Red
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}
# Normalise to Windows path (git returns forward slashes)
$gitRoot = $gitRoot -replace '/', '\'
Set-Location $gitRoot
Write-Host "[DEBUG] Git repo root : $gitRoot" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Current location: $(Get-Location)" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# CREATE NOTE FILE — note_YYYY-MM-DD_HH-MM.md inside the secondbrain folder
# File name uses datetime so every run produces a unique, sortable file.
# Content is the clipboard text (the thing you copied before pressing StreamDeck).
# =============================================================================
$noteDateTime   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$noteFileName   = "note_$noteDateTime.md"
$noteFilePath   = Join-Path $gitRoot $noteFileName   # gitRoot = F:\secondbrain_v4\secondbrain\

$noteContent = @"
# $commitMessage

$clipboardText

---
Created: $date
"@

Set-Content -Path $noteFilePath -Value $noteContent -Encoding UTF8
Write-Host "[DEBUG] Note file created: $noteFilePath" -ForegroundColor DarkGreen
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

# Stage all changes from the entire repo root (not just current subdir)
# -A includes deletions and renames anywhere in the repo, not just below cwd
Write-Host "Staging all changes (git add -A from repo root)..." -ForegroundColor Yellow
git add -A
Write-Host "[DEBUG] git add exit code: $LASTEXITCODE" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# SHOW WHAT WILL BE COMMITTED — diff stat so user sees exactly what goes in
# Capture new files (status A) now so we can show them in the final summary
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

# Capture newly created files (A = Added) for the end summary
$newFiles = git diff --cached --name-status | Where-Object { $_ -match '^A\s' } |
            ForEach-Object { ($_ -replace '^A\s+', '').Trim() }

# Commit
# Exit code 1 from git commit can mean "nothing to commit" (not a real error).
# We do NOT exit here — always continue to push, in case there are
# previously committed but unpushed changes waiting on the local branch.
Write-Host "Committing: '$commitMessage'" -ForegroundColor Yellow
git commit -m "$commitMessage"
$commitExitCode = $LASTEXITCODE
Write-Host "[DEBUG] git commit exit code: $commitExitCode" -ForegroundColor DarkCyan
if ($commitExitCode -ne 0) {
    Write-Host "NOTE: Nothing new to commit (or commit skipped). Continuing to push anyway..." -ForegroundColor DarkYellow
}

# Push — always runs, even if there was nothing to commit locally
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

# Show both created files: the transcript log AND any new files in the secondbrain repo
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "Files created this run:" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor DarkGray

# 1. Note file created in secondbrain (primary output — shown first and most prominent)
Write-Host "  [NOTE] $noteFilePath" -ForegroundColor Green

# 2. Transcript log (always created)
Write-Host "  [LOG]  $logFile" -ForegroundColor Yellow

# 3. Any other new files committed to the repo (full absolute paths)
$otherNewFiles = $newFiles | Where-Object { (Join-Path $gitRoot $_) -ne $noteFilePath }
if ($otherNewFiles) {
    foreach ($f in $otherNewFiles) {
        $fullPath = Join-Path $gitRoot $f
        Write-Host "  [REPO] $fullPath" -ForegroundColor White
    }
}
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Copy note file path + commit message to clipboard
$clipboardSummary = "Note: $noteFilePath | Committed: $commitMessage"
Set-Clipboard -Value $clipboardSummary
Write-Host "Copied to clipboard:" -ForegroundColor Cyan
Write-Host "  $clipboardSummary" -ForegroundColor White
Write-Host ""

Stop-Transcript

# Keep window open - always ask before closing
Read-Host "Press Enter to close"

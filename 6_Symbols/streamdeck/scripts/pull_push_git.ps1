# =============================================================================
# pull_push_git.ps1 - Second Brain Git Pull & Push Script
# Triggered via StreamDeck
#
# Pulls latest, stages all changes, commits, and pushes to origin/main.
#
# DEBUGGING:
#   Every run is logged to: C:\Temp\pull_push_git_log.txt
# =============================================================================

# --- Log file ---
$logFile = "C:\Temp\pull_push_git_log.txt"
if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}
Start-Transcript -Path $logFile -Append

$date = Get-Date -Format "yyyy-MM-dd HH:mm"

# --- Header ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "   Second Brain - Pull & Push Git Sync     " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Log file: $logFile" -ForegroundColor DarkGray
Write-Host ""

# =============================================================================
# Configuration
# =============================================================================
$remoteRepo = "origin"
$branch     = "main"
$repoPath   = "F:\secondbrain_v4\secondbrain\secondbrain\"

Write-Host "[DEBUG] Target repo   : $repoPath" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Remote/Branch : $remoteRepo / $branch" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# Validate & navigate to repo
# =============================================================================
if (-not (Test-Path $repoPath)) {
    Write-Host "ERROR: Repo path does not exist: $repoPath" -ForegroundColor Red
    Write-Host "       Check the drive letter and folder names." -ForegroundColor Red
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}

Set-Location $repoPath

$gitRoot = git rev-parse --show-toplevel 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not inside a git repo at: $repoPath" -ForegroundColor Red
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}
$gitRoot = $gitRoot -replace '/', '\'
Set-Location $gitRoot
Write-Host "[DEBUG] Git repo root : $gitRoot" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# 1. PULL — fetch and merge latest changes
# =============================================================================
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

# =============================================================================
# 2. STAGE all changes
# =============================================================================
Write-Host "Staging all changes (git add -A)..." -ForegroundColor Yellow
git add -A
Write-Host "[DEBUG] git add exit code: $LASTEXITCODE" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# 3. Show what will be committed
# =============================================================================
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "Changes about to be committed:" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
git diff --cached --stat
Write-Host ""
git diff --cached --name-status
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# =============================================================================
# 4. COMMIT
# =============================================================================
$commitMessage = "Sync $date"
Write-Host "Committing: '$commitMessage'" -ForegroundColor Yellow
git commit -m "$commitMessage"
$commitExitCode = $LASTEXITCODE
Write-Host "[DEBUG] git commit exit code: $commitExitCode" -ForegroundColor DarkCyan
if ($commitExitCode -ne 0) {
    Write-Host "NOTE: Nothing new to commit. Continuing to push anyway..." -ForegroundColor DarkYellow
}
Write-Host ""

# =============================================================================
# 5. PUSH
# =============================================================================
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "Pushing to $remoteRepo/$branch..." -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
git push $remoteRepo $branch
Write-Host "[DEBUG] git push exit code: $LASTEXITCODE" -ForegroundColor DarkCyan
Write-Host ""

# =============================================================================
# Done
# =============================================================================
Write-Host "============================================" -ForegroundColor Green
Write-Host "          Sync Complete!                    " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Committed : $commitMessage" -ForegroundColor Green
Write-Host "  Log saved : $logFile" -ForegroundColor DarkGray
Write-Host ""

Stop-Transcript
Read-Host "Press Enter to close"
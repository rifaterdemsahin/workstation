# =============================================================================
# addnote.ps1 - Second Brain Git Sync Script
# Triggered via StreamDeck Multi Action
# Because StreamDeck closes the terminal immediately after execution,
# this script uses colored output and ends with Read-Host to keep the
# window open so the user can review the result before closing.
# =============================================================================

# Get the current date for default commit message
$date = Get-Date -Format "yyyy-MM-dd HH:mm"

# --- Header ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "   Second Brain - Add Note / Sync Script   " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Triggered from: StreamDeck Multi Action  " -ForegroundColor DarkGray
Write-Host ""

# 1. User Input
Write-Host "Enter commit message (Leave blank for 'Update $date'):" -ForegroundColor Yellow
$commitMessage = Read-Host " >"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Update $date"
}

# 2. Configuration
$remoteRepo = "origin"
$branch = "main" # Change this to your default branch name

# 3. Execution
Write-Host ""
Write-Host "--- Starting Git Automation ---" -ForegroundColor Cyan

# Navigate to the second brain repo directory
# This is where notes/files are committed from
$repoPath = "F:\secondbrain_v4\secondbrain\secondbrain\"
Set-Location $repoPath
Write-Host "Working directory: $repoPath" -ForegroundColor Cyan

# Pull latest changes to avoid conflicts
Write-Host "Pulling from $remoteRepo/$branch..." -ForegroundColor Yellow
git pull $remoteRepo $branch
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Pull failed. Please resolve conflicts manually." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to close"   # Always ask before closing - never silent exit
    exit 1
}

# Stage all changes
Write-Host "Staging all changes..." -ForegroundColor Yellow
git add .

# Commit with the provided or default message
Write-Host "Committing: '$commitMessage'" -ForegroundColor Yellow
git commit -m "$commitMessage"
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Nothing to commit or commit failed." -ForegroundColor DarkYellow
    Write-Host ""
    Read-Host "Press Enter to close"   # Always ask before closing - never silent exit
    exit 1
}

# Push to remote
Write-Host "Pushing to $remoteRepo/$branch..." -ForegroundColor Yellow
git push $remoteRepo $branch

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "          Process Complete!                 " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Keep window open - required for StreamDeck Multi Action which closes terminal immediately
# Always ask before closing - never silent exit
Read-Host "Press Enter to close"

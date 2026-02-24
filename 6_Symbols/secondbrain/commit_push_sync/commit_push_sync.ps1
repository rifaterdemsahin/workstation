# =============================================================================
# commit_push_sync.ps1 - Lightweight Git Commit & Push
# Just stages everything, commits, and pushes. No note creation, no Obsidian.
# =============================================================================

$logFile = "C:\Temp\commit_push_sync_log.txt"
if (-not (Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" | Out-Null }
Start-Transcript -Path $logFile -Append

$date = Get-Date -Format "yyyy-MM-dd HH:mm"

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "   Second Brain - Commit & Push Only       " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# =============================================================================
# 1. COMMIT MESSAGE — clipboard first, fallback to manual, default to timestamp
# =============================================================================
$clipboardText = Get-Clipboard

if (-not [string]::IsNullOrWhiteSpace($clipboardText)) {
    Write-Host "Clipboard detected:" -ForegroundColor Cyan
    Write-Host "  $clipboardText" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Enter to use clipboard as commit message, or type a new one:" -ForegroundColor Yellow
    $userInput = Read-Host " >"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $commitMessage = $clipboardText
    } else {
        $commitMessage = $userInput
    }
} else {
    Write-Host "Enter commit message (Leave blank for 'Update $date'):" -ForegroundColor Yellow
    $userInput = Read-Host " >"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $commitMessage = "Update $date"
    } else {
        $commitMessage = $userInput
    }
}

Write-Host ""
Write-Host "Commit message: '$commitMessage'" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# 2. Configuration
# =============================================================================
$remoteRepo = "origin"
$branch     = "main"
$repoPath   = "F:\secondbrain_v4\secondbrain\secondbrain\"

# =============================================================================
# 3. Navigate to repo
# =============================================================================
if (-not (Test-Path $repoPath)) {
    Write-Host "ERROR: Repo path does not exist: $repoPath" -ForegroundColor Red
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

# =============================================================================
# 4. Pull, Stage, Commit, Push
# =============================================================================
Write-Host "Pulling from $remoteRepo/$branch..." -ForegroundColor Yellow
git pull $remoteRepo $branch
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Pull failed. Resolve conflicts manually." -ForegroundColor Red
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host ""
Write-Host "Staging all changes..." -ForegroundColor Yellow
git add -A

Write-Host ""
Write-Host "Changes to commit:" -ForegroundColor Cyan
git diff --cached --name-status
Write-Host ""

Write-Host "Committing: '$commitMessage'" -ForegroundColor Yellow
git commit -m "$commitMessage"
$commitExitCode = $LASTEXITCODE
if ($commitExitCode -ne 0) {
    Write-Host "Nothing new to commit. Continuing to push..." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "Pushing to $remoteRepo/$branch..." -ForegroundColor Yellow
git push $remoteRepo $branch

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   Done! Committed & Pushed.               " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Message: $commitMessage" -ForegroundColor Green
Write-Host ""

Stop-Transcript

Read-Host "Press Enter to close"

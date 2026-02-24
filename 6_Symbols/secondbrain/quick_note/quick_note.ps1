# =============================================================================
# quick_note.ps1 - Type a Quick Note and Push to Second Brain
# Saves each note as its own timestamped .md file, commits, and pushes.
# =============================================================================

$logFile = "C:\Temp\quick_note_log.txt"
if (-not (Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" | Out-Null }
Start-Transcript -Path $logFile -Append

$datetime       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$datetimeFile   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "   Second Brain - Quick Note               " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# =============================================================================
# 1. Get note text
# =============================================================================
Write-Host "Type your note:" -ForegroundColor Yellow
$noteText = Read-Host " >"

if ([string]::IsNullOrWhiteSpace($noteText)) {
    Write-Host "ERROR: Note is empty. Nothing to save." -ForegroundColor Red
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}

# =============================================================================
# 2. Configuration
# =============================================================================
$remoteRepo = "origin"
$branch     = "main"
$repoPath   = "F:\secondbrain_v4\secondbrain\secondbrain\"
$saveDir    = "F:\secondbrain_v4\secondbrain\"

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
# 4. Save note as individual file
# =============================================================================
if (-not (Test-Path $saveDir)) {
    New-Item -ItemType Directory -Path $saveDir | Out-Null
    Write-Host "Created folder: $saveDir" -ForegroundColor DarkYellow
}

$filePath = Join-Path $saveDir "quick_note_${datetimeFile}.md"

$content = @"
# $datetime

$noteText
"@

Set-Content -Path $filePath -Value $content -Encoding UTF8

Write-Host "Note saved to: $filePath" -ForegroundColor Green
Write-Host ""

# =============================================================================
# 5. Pull, Stage, Commit, Push
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

$commitMessage = "StreamDeck quick note $datetime"
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
Write-Host "   Done! Note saved & pushed.              " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Note:    $noteText" -ForegroundColor Green
Write-Host "  File:    $filePath" -ForegroundColor Green
Write-Host "  Message: $commitMessage" -ForegroundColor Green
Write-Host ""

Stop-Transcript

Read-Host "Press Enter to close"

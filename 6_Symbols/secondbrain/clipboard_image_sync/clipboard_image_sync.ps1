# =============================================================================
# clipboard_image_sync.ps1 - Save Clipboard Image to Second Brain & Push
# Grabs whatever image is on the clipboard, saves it as a timestamped PNG
# inside the second brain repo, then stages, commits, and pushes.
# =============================================================================

$logFile = "C:\Temp\clipboard_image_sync_log.txt"
if (-not (Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" | Out-Null }
Start-Transcript -Path $logFile -Append

$datetime   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$dateLabel  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "   Second Brain - Clipboard Image Sync     " -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# =============================================================================
# 1. Grab image from clipboard
# =============================================================================
Add-Type -AssemblyName System.Windows.Forms
$clipImage = [System.Windows.Forms.Clipboard]::GetImage()

if ($null -eq $clipImage) {
    Write-Host "ERROR: No image found on clipboard." -ForegroundColor Red
    Write-Host "       Copy a screenshot or image first, then run this script." -ForegroundColor Yellow
    Stop-Transcript
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Image detected on clipboard ($($clipImage.Width)x$($clipImage.Height)px)" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# 2. Configuration
# =============================================================================
$remoteRepo  = "origin"
$branch      = "main"
$repoPath    = "F:\secondbrain_v4\secondbrain\secondbrain\"
$imageFolder = "screenshots"

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
# 4. Save image
# =============================================================================
$saveDir = Join-Path $gitRoot $imageFolder
if (-not (Test-Path $saveDir)) {
    New-Item -ItemType Directory -Path $saveDir | Out-Null
    Write-Host "Created folder: $saveDir" -ForegroundColor DarkYellow
}

Write-Host "Enter a name for the image file:" -ForegroundColor Yellow
$userInput = Read-Host " >"
$baseName  = $userInput.Trim() -replace '\s+', '_' -replace '[\\/:*?"<>|]', '_'
$fileName  = "${baseName}_${datetime}.png"
$savePath  = Join-Path $saveDir $fileName

$clipImage.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved: $savePath" -ForegroundColor Green
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

$commitMessage = "StreamDeck clipboard image $dateLabel"
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
Write-Host "   Done! Image saved & pushed.             " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  File:    $savePath" -ForegroundColor Green
Write-Host "  Message: $commitMessage" -ForegroundColor Green
Write-Host ""

Stop-Transcript

Read-Host "Press Enter to close"

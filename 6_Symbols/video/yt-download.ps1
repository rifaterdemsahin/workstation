# ================================================
#  yt-download.ps1
#  YouTube Video Downloader using yt-dlp
#  Downloads to: $env:USERPROFILE\Downloads
#  Debug mode: verbose output at every step
# ================================================

$DebugMode       = $true   # Set to $false to suppress debug lines
$DownloadsFolder = "$env:USERPROFILE\Downloads"
$YtDlpWinGet     = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\yt-dlp.yt-dlp*\yt-dlp.exe"
$LogFile         = "$DownloadsFolder\yt-download-debug.log"

# -- Logging helpers ----------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Color = "Gray", [string]$Level = "INFO")
    $ts   = Get-Date -Format "HH:mm:ss"
    $line = "[$ts][$Level] $Message"
    if ($DebugMode -or $Level -eq "ERROR") {
        Write-Host $line -ForegroundColor $Color
    }
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "  >> $Message" -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'HH:mm:ss')][STEP] $Message" -ErrorAction SilentlyContinue
}

# -- Banner -------------------------------------------------------------------
Clear-Host
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        YouTube Video Downloader" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Debug mode : ON" -ForegroundColor DarkYellow
Write-Host "  Log file   : $LogFile" -ForegroundColor DarkYellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Script started" "DarkYellow"
Write-Log "PowerShell version : $($PSVersionTable.PSVersion)" "DarkYellow"
Write-Log "OS                 : $([System.Environment]::OSVersion.VersionString)" "DarkYellow"
Write-Log "User               : $env:USERNAME" "DarkYellow"
Write-Log "Downloads folder   : $DownloadsFolder" "DarkYellow"

# -- Verify Downloads folder exists -------------------------------------------
Write-Step "Checking Downloads folder..."
if (-not (Test-Path $DownloadsFolder)) {
    Write-Log "Downloads folder missing -- creating it" "Yellow" "WARN"
    New-Item -ItemType Directory -Path $DownloadsFolder -Force | Out-Null
    Write-Log "Created: $DownloadsFolder" "Green"
} else {
    Write-Log "Downloads folder OK: $DownloadsFolder" "Green"
}

# -- Helper: find yt-dlp ------------------------------------------------------
function Get-YtDlp {
    Write-Log "  [1/3] Searching PATH for yt-dlp..." "DarkYellow"
    $found = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if ($found) {
        Write-Log "  Found on PATH: $($found.Source)" "Green"
        return $found.Source
    }

    Write-Log "  [2/3] Checking WinGet packages folder..." "DarkYellow"
    $wg = Get-Item $YtDlpWinGet -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wg) {
        Write-Log "  Found via WinGet: $($wg.FullName)" "Green"
        return $wg.FullName
    }

    Write-Log "  [3/3] Checking Scoop shims..." "DarkYellow"
    $scoop = "$env:USERPROFILE\scoop\shims\yt-dlp.exe"
    if (Test-Path $scoop) {
        Write-Log "  Found via Scoop: $scoop" "Green"
        return $scoop
    }

    Write-Log "  yt-dlp not found in any location" "Red" "WARN"
    return $null
}

# -- Check / install yt-dlp ---------------------------------------------------
Write-Step "Locating yt-dlp..."
$ytdlp = Get-YtDlp

if (-not $ytdlp) {
    Write-Host ""
    Write-Host "  yt-dlp not found -- attempting install via winget..." -ForegroundColor Yellow

    Write-Log "Checking winget availability..." "DarkYellow"
    $wgCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wgCmd) {
        Write-Log "winget not found -- cannot auto-install" "Red" "ERROR"
        Write-Host ""
        Write-Host "  ERROR: winget is not available on this machine." -ForegroundColor Red
        Write-Host "  Please install yt-dlp manually: https://github.com/yt-dlp/yt-dlp#installation" -ForegroundColor Yellow
        Read-Host "`nPress Enter to exit"
        exit 1
    }

    Write-Log "winget found at: $($wgCmd.Source)" "DarkYellow"
    Write-Log "Running: winget install --id yt-dlp.yt-dlp -e --source winget" "DarkYellow"

    $wingetOutput = winget install --id yt-dlp.yt-dlp -e --source winget 2>&1
    $wingetOutput | ForEach-Object { Write-Log "  [winget] $_" "DarkGray" }

    # Refresh PATH in current session
    Write-Log "Refreshing PATH after install..." "DarkYellow"
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH","User")

    $ytdlp = Get-YtDlp

    if (-not $ytdlp) {
        Write-Log "yt-dlp still not found after install" "Red" "ERROR"
        Write-Host ""
        Write-Host "  ERROR: Could not locate yt-dlp after install." -ForegroundColor Red
        Write-Host "  Try closing and re-opening this window, or install manually:" -ForegroundColor Yellow
        Write-Host "  https://github.com/yt-dlp/yt-dlp#installation" -ForegroundColor Yellow
        Read-Host "`nPress Enter to exit"
        exit 1
    }

    Write-Log "yt-dlp installed and located: $ytdlp" "Green"
}

Write-Host "  yt-dlp path: $ytdlp" -ForegroundColor Green

# -- Verify yt-dlp actually executes -----------------------------------------
Write-Step "Verifying yt-dlp executes..."
try {
    $version = & "$ytdlp" --version 2>&1
    Write-Log "yt-dlp version: $version" "Green"
    Write-Host "  Version: $version" -ForegroundColor Green
} catch {
    Write-Log "yt-dlp failed to run: $_" "Red" "ERROR"
    Write-Host "  ERROR: yt-dlp could not be executed. Path used: $ytdlp" -ForegroundColor Red
    Read-Host "`nPress Enter to exit"
    exit 1
}

# -- Check ffmpeg -------------------------------------------------------------
Write-Step "Checking for ffmpeg (needed for HD quality merging)..."
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($ffmpeg) {
    Write-Log "ffmpeg found: $($ffmpeg.Source)" "Green"
    Write-Host "  ffmpeg: OK ($($ffmpeg.Source))" -ForegroundColor Green
} else {
    Write-Log "ffmpeg NOT found -- HD merging unavailable" "Yellow" "WARN"
    Write-Host "  ffmpeg: NOT FOUND" -ForegroundColor Yellow
    Write-Host "  1080p+ quality merging will be limited." -ForegroundColor DarkYellow
    Write-Host "  Fix: winget install Gyan.FFmpeg  (then restart)" -ForegroundColor DarkYellow
}

# -- Collect YouTube URL ------------------------------------------------------
Write-Step "Waiting for YouTube URL input..."
Write-Host ""

do {
    $url = Read-Host "  Paste YouTube URL (or type 'exit' to quit)"
    $url = $url.Trim()
    Write-Log "Raw input received: '$url'" "DarkYellow"

    if ($url -eq 'exit') {
        Write-Log "User chose to exit at URL prompt" "Yellow"
        Write-Host "  Goodbye!" -ForegroundColor Yellow
        exit 0
    }

    $isValid = $url -match "^https?://(www\.)?(youtube\.com/watch|youtu\.be/|youtube\.com/shorts/)"
    Write-Log "URL validation result: $isValid" "DarkYellow"

    if (-not $isValid) {
        Write-Host "  Invalid YouTube URL. Accepted formats:" -ForegroundColor Red
        Write-Host "    https://www.youtube.com/watch?v=XXXX" -ForegroundColor DarkGray
        Write-Host "    https://youtu.be/XXXX" -ForegroundColor DarkGray
        Write-Host "    https://www.youtube.com/shorts/XXXX" -ForegroundColor DarkGray
        Write-Host ""
    }
} while (-not $isValid)

Write-Log "URL accepted: $url" "Green"

# -- Quality selection --------------------------------------------------------
Write-Step "Quality selection..."
Write-Host ""
Write-Host "  [1] Best quality (default)" -ForegroundColor White
Write-Host "  [2] 1080p" -ForegroundColor White
Write-Host "  [3] 720p" -ForegroundColor White
Write-Host "  [4] 480p" -ForegroundColor White
Write-Host "  [5] Audio only (MP3)" -ForegroundColor White
Write-Host ""
$choice = Read-Host "  Enter choice [1-5]"
Write-Log "Quality choice entered: '$choice'" "DarkYellow"

switch ($choice) {
    "2" { $format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]"; $ext = "mp4"; $label = "1080p" }
    "3" { $format = "bestvideo[height<=720]+bestaudio/best[height<=720]";   $ext = "mp4"; $label = "720p"  }
    "4" { $format = "bestvideo[height<=480]+bestaudio/best[height<=480]";   $ext = "mp4"; $label = "480p"  }
    "5" { $format = "bestaudio/best"; $ext = "mp3"; $label = "Audio MP3" }
    default { $format = "bestvideo+bestaudio/best"; $ext = "mp4"; $label = "Best (auto)" }
}

Write-Log "Format label   : $label" "DarkYellow"
Write-Log "Format string  : $format" "DarkYellow"
Write-Log "Output ext     : $ext" "DarkYellow"

# -- Build yt-dlp args --------------------------------------------------------
Write-Step "Building yt-dlp command..."

$outputTemplate = "$DownloadsFolder\%(title)s.%(ext)s"

if ($ext -eq "mp3") {
    $dlArgs = @(
        "--format",        $format,
        "--extract-audio",
        "--audio-format",  "mp3",
        "--audio-quality", "0",
        "--output",        $outputTemplate,
        "--progress",
        "--verbose",
        $url
    )
} else {
    $dlArgs = @(
        "--format",               $format,
        "--merge-output-format",  "mp4",
        "--output",               $outputTemplate,
        "--progress",
        "--verbose",
        $url
    )
}

Write-Log "Executable : $ytdlp" "DarkYellow"
Write-Log "Arguments  : $($dlArgs -join ' ')" "DarkYellow"
Write-Host ""
Write-Host "  Executable : $ytdlp" -ForegroundColor DarkGray
Write-Host "  Arguments  : $($dlArgs -join ' ')" -ForegroundColor DarkGray
Write-Host ""

# -- Download ------------------------------------------------------------------
Write-Step "Starting download (verbose yt-dlp output follows)..."
Write-Host ""
Write-Log "Invoking yt-dlp now..." "Cyan"

& "$ytdlp" @dlArgs

$exitCode = $LASTEXITCODE
Write-Log "yt-dlp finished with exit code: $exitCode" $(if ($exitCode -eq 0) { "Green" } else { "Red" })

# -- Result --------------------------------------------------------------------
Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "  Download complete!" -ForegroundColor Green
    Write-Host "  Saved to: $DownloadsFolder" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Log "Opening Downloads folder..." "DarkYellow"
    Start-Process explorer.exe $DownloadsFolder
} else {
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "  Download FAILED  (exit code: $exitCode)" -ForegroundColor Red
    Write-Host "  Review the verbose output above, or check:" -ForegroundColor Yellow
    Write-Host "  $LogFile" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Red
}

Write-Log "Script finished. Exit code: $exitCode" "DarkYellow"
Write-Host ""
Write-Host "  Full debug log: $LogFile" -ForegroundColor DarkGray
Write-Host ""
Read-Host "Press Enter to exit"

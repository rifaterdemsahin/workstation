@echo off
title YouTube Downloader [DEBUG MODE]
color 0B

echo ================================================
echo         YouTube Video Downloader
echo         Debug mode active
echo ================================================
echo.
echo Launching PowerShell script...
echo.

:: Pass script path explicitly so it works from any working directory
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0yt-download.ps1"

:: PS1 handles its own pause — only land here on a hard PS1 crash
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [BAT] PowerShell exited with error code: %ERRORLEVEL%
    echo [BAT] The PS1 script may have crashed before its own pause.
    pause
)

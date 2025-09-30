@echo off
REM Batch file to launch Chrome with specific profile and open Telegram & Gemini URLs
REM This is a wrapper script that can run either PowerShell or AutoHotkey version

echo =======================================
echo Telegram & Gemini Chrome Launcher
echo =======================================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% equ 0 (
    echo Running PowerShell version...
    powershell -ExecutionPolicy Bypass -File "%~dp0launch_chrome_urls.ps1"
) else (
    echo PowerShell not available, trying AutoHotkey...
    if exist "%~dp0launch_chrome_urls.ahk" (
        if exist "C:\Program Files\AutoHotkey\AutoHotkey.exe" (
            "C:\Program Files\AutoHotkey\AutoHotkey.exe" "%~dp0launch_chrome_urls.ahk"
        ) else if exist "C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe" (
            "C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe" "%~dp0launch_chrome_urls.ahk"
        ) else (
            echo AutoHotkey not found. Please install AutoHotkey or run the PowerShell script directly.
            pause
        )
    ) else (
        echo Neither PowerShell script nor AutoHotkey script found.
        pause
    )
)

echo.
echo Script execution completed.
pause

@echo off
REM Batch file to run DisableVoiceAssistant.ps1 with proper permissions
REM This ensures the PowerShell script runs with administrator privileges

echo ========================================
echo  Voice Assistant Disable Script
echo ========================================
echo.
echo This script will disable Windows voice assistant features
echo including Cortana, voice services, and related features.
echo.
echo WARNING: This requires Administrator privileges!
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with Administrator privileges...
    echo.
) else (
    echo ERROR: This script must be run as Administrator!
    echo.
    echo Please right-click on this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Set execution policy for this session
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force"

REM Run the PowerShell script
echo.
echo Running DisableVoiceAssistant.ps1...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0DisableVoiceAssistant.ps1"

REM Check if the script ran successfully
if %errorLevel% == 0 (
    echo.
    echo ========================================
    echo  Script completed successfully!
    echo ========================================
    echo.
    echo Voice assistant features have been disabled.
    echo Check the log file for detailed results.
    echo.
) else (
    echo.
    echo ========================================
    echo  Script encountered errors!
    echo ========================================
    echo.
    echo Please check the log file for error details.
    echo.
)

echo Press any key to exit...
pause >nul

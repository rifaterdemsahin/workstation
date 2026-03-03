@echo off
:: USB Diagnostic Launcher
:: Opens the USB diagnostic PowerShell script in a new terminal window
:: Add this .bat to Windows Startup folder or Task Scheduler for auto-run

set "SCRIPT=%~dp0usb_diagnostic.ps1"

:: Launch in a visible PowerShell 7 (pwsh) window first, fall back to Windows PowerShell
where pwsh >nul 2>&1
if %ERRORLEVEL% == 0 (
    start "USB Diagnostic" pwsh.exe -NoExit -ExecutionPolicy Bypass -File "%SCRIPT%"
) else (
    start "USB Diagnostic" powershell.exe -NoExit -ExecutionPolicy Bypass -File "%SCRIPT%"
)

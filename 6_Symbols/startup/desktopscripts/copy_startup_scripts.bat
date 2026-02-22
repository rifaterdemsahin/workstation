@echo off
REM Batch Script to Copy Windows Startup Scripts
REM Purpose: Simplifies the installation of startup scripts to Windows Startup folder
REM This runs the PowerShell installer script with proper execution policy

echo ========================================
echo Windows Startup Scripts Installer
echo ========================================
echo.
echo This script will install the following scripts to your Windows Startup folder:
echo   - launch_chrome_urls.ps1
echo   - start_gemini_secondbrain.ps1
echo   - run_updates_admin.ps1
echo   - scan_windows_events.ps1
echo   - start_ollama.ps1
echo   - GPU_Diagnostic_Startup.ps1
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Running PowerShell installer...
echo.

REM Run the PowerShell script with bypass execution policy
powershell.exe -ExecutionPolicy Bypass -File "%~dp0install_startup_shortcuts.ps1"

echo.
echo ========================================
echo Installation process completed!
echo ========================================
echo.
echo To verify the installation:
echo 1. Press Win + R
echo 2. Type: shell:startup
echo 3. Press Enter
echo 4. Check that the shortcuts have been created
echo.
echo The scripts will run automatically the next time you log in to Windows.
echo.
pause

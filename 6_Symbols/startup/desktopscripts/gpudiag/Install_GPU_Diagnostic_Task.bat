@echo off
REM GPU Diagnostic Startup Task Installer
REM Run this as Administrator to install the diagnostic service

setlocal enabledelayedexpansion

echo.
echo ======================================
echo GPU DIAGNOSTIC STARTUP INSTALLER
echo ======================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must run as Administrator!
    echo Please right-click Command Prompt and select "Run as Administrator"
    pause
    exit /b 1
)

echo [✓] Administrator privileges confirmed
echo.

REM Set paths
set PS_SCRIPT=%ProgramFiles%\GPU_Diagnostics\GPU_Diagnostic_Startup.ps1
set TASK_NAME=GPU_Diagnostic_Startup
set TASK_FOLDER=\GPU_Diagnostics\

echo Installing GPU Diagnostic to: %ProgramFiles%\GPU_Diagnostics\
echo.

REM Create directory if it doesn't exist
if not exist "%ProgramFiles%\GPU_Diagnostics" (
    mkdir "%ProgramFiles%\GPU_Diagnostics"
    echo [✓] Created directory
)

REM Copy PowerShell script
echo Copying diagnostic script...
copy /Y "GPU_Diagnostic_Startup.ps1" "%PS_SCRIPT%" >nul 2>&1
if %errorLevel% equ 0 (
    echo [✓] Script copied successfully
) else (
    echo [✗] Failed to copy script - Make sure GPU_Diagnostic_Startup.ps1 is in the current directory
    pause
    exit /b 1
)

echo.
echo Creating Windows scheduled task...

REM Create scheduled task to run at startup
powershell -Command "
$taskName = '%TASK_NAME%'
$taskFolder = '%TASK_FOLDER%'
$scriptPath = '%PS_SCRIPT%'

# Create task folder if it doesn't exist
$taskService = New-Object -ComObject Schedule.Service
$taskService.Connect()
$rootFolder = $taskService.GetFolder('\')

try {
    $rootFolder.CreateFolder([string]$taskFolder)
    Write-Host '[✓] Task folder created'
} catch {
    if ($_.Exception.Message -like '*exists*') {
        Write-Host '[✓] Task folder already exists'
    }
}

# Create trigger (at system startup)
`$trigger = New-ScheduledTaskTrigger -AtStartup
`$trigger.Delay = 'PT2M'  # 2 minute delay after startup to avoid startup congestion

# Create action (run PowerShell script)
`$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument \"-NoProfile -ExecutionPolicy Bypass -File `'`$scriptPath`'\" -WorkingDirectory 'C:\Windows\System32'

# Create settings (run with high priority, allow on-demand execution)
`$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable:`$false -MultipleInstances IgnoreNew

# Register the task
try {
    Register-ScheduledTask -TaskName `$taskName -TaskPath `$taskFolder -Trigger `$trigger -Action `$action -Settings `$settings -RunLevel Highest -Force -ErrorAction Stop
    Write-Host '[✓] Scheduled task created successfully'
    Write-Host '[✓] Task will run 2 minutes after Windows startup'
} catch {
    Write-Host '[✗] Failed to create scheduled task: ' `$_.Exception.Message
    exit 1
}
"

if %errorLevel% equ 0 (
    echo.
    echo ======================================
    echo [✓] INSTALLATION COMPLETE
    echo ======================================
    echo.
    echo Task Details:
    echo - Name: %TASK_NAME%
    echo - Folder: %TASK_FOLDER%
    echo - Trigger: At Windows startup (2 minute delay)
    echo - Runs as: System (HIGHEST privilege)
    echo.
    echo Log Files Location:
    echo   C:\ProgramData\GPU_Diagnostics\diagnostic_YYYY-MM-DD.log
    echo   C:\ProgramData\GPU_Diagnostics\latest_report.txt
    echo.
    echo The diagnostic will run automatically at each startup!
    echo.
    pause
) else (
    echo.
    echo [✗] Installation failed!
    echo.
    pause
    exit /b 1
)

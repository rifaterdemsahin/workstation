# PowerShell Script to Create a Scheduled Task for Temperature Monitoring
# Purpose: Registers monitor_temperatures.ps1 as a scheduled task to run at system startup.

#region Configuration
$TaskName = "MonitorTemperaturesAtStartup"
$ScriptPath = "C:\projects\workstation\6_Symbols\startup\monitor_temperatures.ps1"
$LogPath = "C:\projects\workstation\6_Symbols\Logs	emperature_monitor_task.log"
#endregion

Write-Host "Attempting to create Scheduled Task '$TaskName'..." -ForegroundColor Yellow

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run with Administrator privileges to create a Scheduled Task." -ForegroundColor Red
    Write-Host "Please right-click on the PowerShell script and select 'Run as Administrator'." -ForegroundColor Red
    exit 1
}

# Ensure the log directory exists
$LogDirectory = Split-Path -Path $LogPath -Parent
if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    Write-Host "Created log directory: $LogDirectory" -ForegroundColor Green
}

# Define the action to run the PowerShell script
# It's important to use powershell.exe with -File for script execution
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$ScriptPath`" >> `"$LogPath`" 2>&1"

# Define the trigger (at system startup)
$Trigger = New-ScheduledTaskTrigger -AtStartup

# Define settings for the task
$Settings = New-ScheduledTaskSettingsSet -Compatibility V2.1 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -Priority 7

# Register the scheduled task
try {
    # Check if task already exists, delete if it does to update it
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Host "Scheduled Task '$TaskName' already exists. Deleting existing task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Start-Sleep -Seconds 1 # Give it a moment to unregister
    }

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Monitors CPU and GPU temperatures after startup and logs results." -User "SYSTEM" -Force
    Write-Host "SUCCESS: Scheduled Task '$TaskName' created and registered successfully." -ForegroundColor Green
    Write-Host "The script will run 5 minutes after system startup." -ForegroundColor Green
    Write-Host "Output will be logged to: $LogPath" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to create Scheduled Task '$TaskName'." -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Installation script finished." -ForegroundColor Yellow

# GPU Diagnostic Task Manager
# View logs, check status, and manage the diagnostic service

param(
    [ValidateSet("status", "logs", "report", "disable", "enable", "remove", "test")]
    [string]$Action = "status",
    [int]$Lines = 20
)

$TaskName = "GPU_Diagnostic_Startup"
$TaskFolder = "\GPU_Diagnostics\"
$LogDir = "C:\ProgramData\GPU_Diagnostics"

function Check-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-TaskStatus {
    Write-Host "`n>>> TASK STATUS" -ForegroundColor Cyan
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskFolder -ErrorAction Stop
        Write-Host "Task Name: $($task.TaskName)" -ForegroundColor Green
        
        $statusColor = if ($task.State -eq "Ready") { "Green" } else { "Yellow" }
        Write-Host "Status: $($task.State)" -ForegroundColor $statusColor
        
        $resultColor = if ($task.LastTaskResult -eq 0) { "Green" } else { "Red" }
        Write-Host "Last Run Result: $($task.LastTaskResult)" -ForegroundColor $resultColor
        
        Write-Host "Last Run Time: $($task.LastRunTime)" -ForegroundColor White
        Write-Host "Next Run Time: $($task.NextRunTime)" -ForegroundColor White
        Write-Host "Triggers: $($task.Triggers.Count) trigger(s)"
        
        $enabled = if ($task.Settings.Enabled) { "Yes" } else { "No" }
        $enabledColor = if ($task.Settings.Enabled) { "Green" } else { "Yellow" }
        Write-Host "Enabled: $enabled" -ForegroundColor $enabledColor
    }
    catch {
        Write-Host "X Task not found or error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Run 'Install_GPU_Diagnostic_Task.bat' as Administrator to install." -ForegroundColor Yellow
    }
}

function Show-Report {
    Write-Host "`n>>> LATEST REPORT" -ForegroundColor Cyan
    
    $reportFile = "$LogDir\latest_report.txt"
    
    if (Test-Path $reportFile) {
        Get-Content $reportFile | Write-Host -ForegroundColor White
    }
    else {
        Write-Host "No report available yet. Diagnostic hasn't run." -ForegroundColor Yellow
    }
}

function Show-Logs {
    param([int]$Lines)
    
    Write-Host "`n>>> DIAGNOSTIC LOGS (Last $Lines lines)" -ForegroundColor Cyan
    
    $todayLog = "$LogDir\diagnostic_$(Get-Date -Format 'yyyy-MM-dd').log"
    
    if (Test-Path $todayLog) {
        Write-Host "Today's Log: $todayLog`n" -ForegroundColor Yellow
        Get-Content $todayLog -Tail $Lines | Write-Host -ForegroundColor White
    }
    else {
        Write-Host "No logs for today." -ForegroundColor Yellow
        Write-Host "`nAvailable logs:" -ForegroundColor Yellow
        
        if (Test-Path $LogDir) {
            Get-ChildItem -Path $LogDir -Filter "diagnostic_*.log" -ErrorAction SilentlyContinue | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 5 | 
            ForEach-Object { Write-Host "  - $($_.Name) ($($_.LastWriteTime))" }
        }
    }
}

function Disable-Task {
    if (-not (Check-Admin)) {
        Write-Host "`nX Requires Administrator privileges to disable task!" -ForegroundColor Red
        return
    }
    
    Write-Host "`nDisabling GPU diagnostic task..." -ForegroundColor Yellow
    
    try {
        Disable-ScheduledTask -TaskName $TaskName -TaskPath $TaskFolder -ErrorAction Stop
        Write-Host "V Task disabled successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "X Failed to disable task: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Enable-Task {
    if (-not (Check-Admin)) {
        Write-Host "`nX Requires Administrator privileges to enable task!" -ForegroundColor Red
        return
    }
    
    Write-Host "`nEnabling GPU diagnostic task..." -ForegroundColor Yellow
    
    try {
        Enable-ScheduledTask -TaskName $TaskName -TaskPath $TaskFolder -ErrorAction Stop
        Write-Host "V Task enabled successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "X Failed to enable task: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-Task {
    if (-not (Check-Admin)) {
        Write-Host "`nX Requires Administrator privileges to remove task!" -ForegroundColor Red
        return
    }
    
    Write-Host "`n! Are you sure you want to remove the GPU diagnostic task? (y/n)" -ForegroundColor Yellow
    $confirm = Read-Host
    
    if ($confirm -eq "y") {
        try {
            Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskFolder -Confirm:$false -ErrorAction Stop
            Write-Host "V Task removed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "X Failed to remove task: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Cancelled." -ForegroundColor Yellow
    }
}

function Run-TestDiagnostic {
    if (-not (Check-Admin)) {
        Write-Host "`nX Requires Administrator privileges to run diagnostic!" -ForegroundColor Red
        return
    }
    
    Write-Host "`nRunning diagnostic now (on-demand)..." -ForegroundColor Yellow
    
    try {
        Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskFolder -ErrorAction Stop
        Write-Host "V Diagnostic started" -ForegroundColor Green
        Write-Host "  Check logs in 30 seconds: $LogDir`n" -ForegroundColor White
    }
    catch {
        Write-Host "X Failed to start diagnostic: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Help {
    Write-Host @"

GPU DIAGNOSTIC TASK MANAGER
============================

USAGE: .\GPU_Diagnostic_Manager.ps1 -Action [action]

ACTIONS:
  status      - Show task status and information (default)
  report      - Display the latest diagnostic report
  logs        - Show recent log entries (use -Lines to change count)
  test        - Run diagnostic immediately (requires admin)
  disable     - Disable automatic startup (requires admin)
  enable      - Enable automatic startup (requires admin)
  remove      - Uninstall the diagnostic task (requires admin)

EXAMPLES:
  .\GPU_Diagnostic_Manager.ps1                    # Show status
  .\GPU_Diagnostic_Manager.ps1 -Action logs       # Show logs
  .\GPU_Diagnostic_Manager.ps1 -Action logs -Lines 50  # Show 50 lines
  .\GPU_Diagnostic_Manager.ps1 -Action report     # Show latest report
  .\GPU_Diagnostic_Manager.ps1 -Action test       # Run now

LOCATIONS:
  Task Folder:  $TaskFolder
  Log Directory: $LogDir
  
"@ -ForegroundColor Cyan
}

# Main execution
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "GPU DIAGNOSTIC TASK MANAGER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

switch ($Action.ToLower()) {
    "status" { Get-TaskStatus; Show-Report }
    "report" { Show-Report }
    "logs" { Show-Logs -Lines $Lines }
    "test" { Run-TestDiagnostic }
    "disable" { Disable-Task }
    "enable" { Enable-Task }
    "remove" { Remove-Task }
    "help" { Show-Help }
    default { Show-Help }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

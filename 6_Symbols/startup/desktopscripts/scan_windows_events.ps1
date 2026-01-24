<#
.SYNOPSIS
    Scans Windows System and Application event logs for hardware and application issues.
    Displays results in the terminal with color coding.

.DESCRIPTION
    This script retrieves Error and Warning events from the 'System' and 'Application' logs
    generated within the last 24 hours. It highlights errors in Red and warnings in Yellow.
#>

$ErrorActionPreference = "Stop"
$originalTitle = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle = "Windows Event Hardware & Application Scanner"

# Configuration
$HoursBack = 24
$StartDate = (Get-Date).AddHours(-$HoursBack)

Function Write-Header {
    param ([string]$Text)
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor White
    Write-Host "================================================================================" -ForegroundColor Cyan
}

Function Get-HardwareAppEvents {
    param ([string]$LogName)
    try {
        $found = Get-EventLog -LogName $LogName -After $StartDate -EntryType Error, Warning -ErrorAction SilentlyContinue 
        if ($found) { return $found }
    }
    catch {
        Write-Host "  [ERROR] Could not read log $LogName. (Run as Administrator?)" -ForegroundColor Red
    }
    return @()
}

Clear-Host
Write-Header "Starting Windows Hardware & Application Event Scanner"

Write-Host "Scanning System and Application logs (Last $HoursBack Hours)..." -ForegroundColor Cyan

$allEvents = @()
$allEvents += Get-HardwareAppEvents -LogName "System"
$allEvents += Get-HardwareAppEvents -LogName "Application"

# ------- Summary Section -------
if ($allEvents.Count -eq 0) {
    Write-Host "`n  [OK] No issues found." -ForegroundColor Green
}
else {
    # 1. Top Recurring Issues
    $groupedEvents = $allEvents | Group-Object Source, InstanceId | Sort-Object Count -Descending | Select-Object -First 10
    
    Write-Header "Top Recurring Issues"
    foreach ($group in $groupedEvents) {
        $first = $group.Group[0]
        $msg = ($first.Message -replace "[\r\n]+", " ").Trim()
        if ($msg.Length -gt 90) { $msg = $msg.Substring(0, 90) + "..." }
        
        $color = if ($first.EntryType -eq 'Error') { 'Red' } else { 'Yellow' }
        Write-Host "  [$($group.Count)x] [$($first.Log)] [$($first.Source)] $msg" -ForegroundColor $color
    }

    # 2. Total Counts & Last Restart Stats
    $errorCount = ($allEvents | Where-Object { $_.EntryType -eq 'Error' }).Count
    $warnCount = ($allEvents | Where-Object { $_.EntryType -eq 'Warning' }).Count
    
    # Calculate Last Restart Stats
    $lastBoot = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
    $sinceRestartCount = ($allEvents | Where-Object { $_.EntryType -eq 'Error' -and $_.TimeGenerated -ge $lastBoot }).Count
    $bootTimeStr = $lastBoot.ToString("yyyy-MM-dd HH:mm")

    Write-Host "`n  Total Summary (Last 24h): " -NoNewline
    if ($errorCount -gt 0) { Write-Host "$errorCount Errors " -ForegroundColor Red -NoNewline }
    if ($warnCount -gt 0) { Write-Host "$warnCount Warnings" -ForegroundColor Yellow }
    
    Write-Host "`n  Since Last Restart ($bootTimeStr): " -NoNewline
    if ($sinceRestartCount -gt 0) { 
        Write-Host "$sinceRestartCount Errors" -ForegroundColor Red
    }
    else {
        Write-Host "0 Errors" -ForegroundColor Green
    }
}

# Function to show a graphical close button
Function Show-CloseButton {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Scan Complete. Click OK to close the terminal.", "Hardware & App Scanner", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# ------- Interaction Section -------
Write-Host "`n`nPress 'L' to list individual errors." -ForegroundColor Cyan -NoNewline
Write-Host " Any other key to close." -ForegroundColor Gray
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if ($key.Character -eq 'l' -or $key.Character -eq 'L') {
    Write-Header "Detailed Event Log"
    
    $allEvents | Sort-Object TimeGenerated | ForEach-Object {
        $type = $_.EntryType
        $time = $_.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
        $source = $_.Source
        $log = $_.Log
        $message = ($_.Message -replace "[\r\n]+", " ").Trim()
        if ($message.Length -gt 150) { $message = $message.Substring(0, 150) + "..." }

        $color = if ($type -eq "Error") { "Red" } else { "Yellow" }
        
        Write-Host "  [$time] [$log] [$type] [$source]" -ForegroundColor $color -NoNewline
        Write-Host " $message" -ForegroundColor Gray
    }
    
    Write-Host "`nEnd of List." -ForegroundColor Cyan
    Show-CloseButton
}

$Host.UI.RawUI.WindowTitle = $originalTitle

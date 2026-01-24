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

Function Search-EventLog {
    param (
        [string]$LogName
    )

    Write-Header "Scanning $LogName Log (Last $HoursBack Hours)"

    try {
        $events = Get-EventLog -LogName $LogName -After $StartDate -EntryType Error, Warning -ErrorAction SilentlyContinue

        if (-not $events) {
            Write-Host "  [OK] No issues found." -ForegroundColor Green
            return
        }

        $events | Sort-Object TimeGenerated | ForEach-Object {
            $type = $_.EntryType
            $time = $_.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
            $source = $_.Source
            # Clean message: remove newlines, take first 150 chars
            $message = ($_.Message -replace "[\r\n]+", " ").Trim()
            if ($message.Length -gt 150) { $message = $message.Substring(0, 150) + "..." }

            $color = if ($type -eq "Error") { "Red" } else { "Yellow" }
            
            Write-Host "  [$time] [$type] [$source]" -ForegroundColor $color -NoNewline
            Write-Host " $message" -ForegroundColor Gray
        }
        
        $errorCount = ($events | Where-Object { $_.EntryType -eq 'Error' }).Count
        $warnCount = ($events | Where-Object { $_.EntryType -eq 'Warning' }).Count
        
        Write-Host "`n  Summary: " -NoNewline
        if ($errorCount -gt 0) { Write-Host "$errorCount Errors " -ForegroundColor Red -NoNewline }
        if ($warnCount -gt 0) { Write-Host "$warnCount Warnings" -ForegroundColor Yellow }
        
    }
    catch {
        Write-Host "  [ERROR] Could not read log $LogName. (Run as Administrator?)" -ForegroundColor Red
        Write-Host "  Details: $_" -ForegroundColor DarkRed
    }
}

Clear-Host
Write-Header "Starting Windows Hardware & Application Event Scanner"

# System Log (Hardware, Driver, Service issues often appear here)
Search-EventLog -LogName "System"

# Application Log (App crashes, hangs, issues)
Search-EventLog -LogName "Application"

# Function to show a graphical close button
Function Show-CloseButton {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Scan Complete. Click OK to close the terminal.", "Hardware & App Scanner", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

Write-Header "Scan Complete"
Write-Host "Waiting for user to close..." -ForegroundColor Cyan
Show-CloseButton
$Host.UI.RawUI.WindowTitle = $originalTitle

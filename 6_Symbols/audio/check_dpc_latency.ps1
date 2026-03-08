# ============================================================
# DPC/Interrupt Latency Diagnostics Script
# ============================================================
# This script helps diagnose audio latency and DPC issues
# by using Windows Performance Recorder (WPR) and event logs

Write-Host "Starting DPC/Interrupt Latency Check..." -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "WARNING: This script should be run as Administrator for full functionality." -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================
# Option 1: Windows Performance Recorder (WPR) Trace
# ============================================================
Write-Host "=== Windows Performance Recorder (WPR) ===" -ForegroundColor Green
Write-Host "To start a latency trace, run:"
Write-Host "  wpr -start latency -filemode" -ForegroundColor White
Write-Host ""
Write-Host "Let it run while you reproduce the audio issues, then stop with:"
Write-Host "  wpr -stop C:\latency_trace.etl" -ForegroundColor White
Write-Host ""
Write-Host "Analyze the .etl file with Windows Performance Analyzer (WPA)"
Write-Host ""

$response = Read-Host "Do you want to start a WPR trace now? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    try {
        Write-Host "Starting WPR latency trace..." -ForegroundColor Yellow
        wpr -start latency -filemode
        Write-Host ""
        Write-Host "Trace started! Reproduce your audio issues, then run:" -ForegroundColor Green
        Write-Host "  wpr -stop C:\latency_trace.etl" -ForegroundColor White
        Write-Host ""
    } catch {
        Write-Host "Error starting WPR trace: $_" -ForegroundColor Red
        Write-Host "Make sure Windows Performance Recorder is installed (part of Windows ADK)" -ForegroundColor Yellow
    }
}

# ============================================================
# Option 2: Quick DPC Check via Event Log
# ============================================================
Write-Host ""
Write-Host "=== PnP Configuration Events ===" -ForegroundColor Green
Write-Host "Checking recent Kernel PnP configuration events..." -ForegroundColor Cyan
Write-Host ""

try {
    $events = Get-WinEvent -LogName "Microsoft-Windows-Kernel-PnP/Configuration" -MaxEvents 20 -ErrorAction Stop

    if ($events) {
        $events | Format-Table TimeCreated, Id, LevelDisplayName, Message -AutoSize -Wrap
    } else {
        Write-Host "No recent PnP configuration events found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Could not retrieve PnP events: $_" -ForegroundColor Red
}

# ============================================================
# Additional Diagnostics
# ============================================================
Write-Host ""
Write-Host "=== Additional Audio/DPC Diagnostics ===" -ForegroundColor Green
Write-Host ""

# Check for known problematic drivers
Write-Host "Checking for common high-DPC drivers..." -ForegroundColor Cyan
$highDpcDrivers = @('nvlddmkm.sys', 'dxgkrnl.sys', 'tcpip.sys', 'USBXHCI.SYS', 'HDAudBus.sys')

foreach ($driver in $highDpcDrivers) {
    $driverInfo = Get-WmiObject Win32_SystemDriver | Where-Object { $_.Name -like "*$driver*" -or $_.PathName -like "*$driver*" }
    if ($driverInfo) {
        Write-Host "  Found: $driver - $($driverInfo.Description)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Recommendations ===" -ForegroundColor Green
Write-Host "1. Use LatencyMon (https://www.resplendence.com/latencymon) for real-time DPC monitoring"
Write-Host "2. Update audio, network, and GPU drivers"
Write-Host "3. Disable/update problematic devices showing high DPC latency"
Write-Host "4. Check Power Plan settings (prefer High Performance for audio work)"
Write-Host ""

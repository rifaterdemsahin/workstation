# Stream Deck Diagnostic and Fix Script
# Purpose: Diagnose and fix Elgato Stream Deck connectivity issues

Write-Host "=== Stream Deck Diagnostic and Fix Script ===" -ForegroundColor Cyan
Write-Host ""

# Check for Admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: This script should be run as Administrator for full functionality" -ForegroundColor Yellow
    Write-Host "Some fixes may require admin privileges to apply" -ForegroundColor Yellow
    Write-Host ""
}

# 1. Find all Stream Deck and Elgato devices
Write-Host "--- Step 1: Locating Stream Deck Devices ---" -ForegroundColor Green
$streamdeckDevices = Get-PnpDevice | Where-Object { $_.FriendlyName -like '*Stream*' -or $_.FriendlyName -like '*Elgato*' }

if ($streamdeckDevices) {
    $streamdeckDevices | Select-Object FriendlyName, Status, InstanceId, Class, Problem, ConfigManagerErrorCode | Format-List
} else {
    Write-Host "No Stream Deck or Elgato devices found!" -ForegroundColor Red
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "  1. Device is not physically connected" -ForegroundColor Yellow
    Write-Host "  2. USB cable is faulty" -ForegroundColor Yellow
    Write-Host "  3. Device is not receiving power" -ForegroundColor Yellow
    Write-Host "  4. Drivers are completely missing" -ForegroundColor Yellow
}

# 2. Check USB HID devices (Stream Deck appears as HID)
Write-Host ""
Write-Host "--- Step 2: Checking USB HID Devices ---" -ForegroundColor Green
$hidDevices = Get-PnpDevice -Class "HIDClass" | Where-Object { $_.Status -ne "OK" }

if ($hidDevices) {
    Write-Host "Found problematic HID devices:" -ForegroundColor Yellow
    $hidDevices | Select-Object FriendlyName, Status, InstanceId, Problem | Format-Table -AutoSize
} else {
    Write-Host "All HID devices are functioning normally" -ForegroundColor Green
}

# 3. Check for error devices on USB
Write-Host ""
Write-Host "--- Step 3: Checking for USB Device Errors ---" -ForegroundColor Green
$errorDevices = Get-PnpDevice | Where-Object { $_.Class -eq "USB" -and $_.Status -ne "OK" }

if ($errorDevices) {
    Write-Host "Found USB devices with errors:" -ForegroundColor Red
    $errorDevices | Select-Object FriendlyName, Status, Problem, InstanceId | Format-Table -AutoSize
} else {
    Write-Host "No USB devices with errors found" -ForegroundColor Green
}

# 4. Check Stream Deck processes
Write-Host ""
Write-Host "--- Step 4: Checking Stream Deck Software ---" -ForegroundColor Green
$streamdeckProcesses = Get-Process | Where-Object { $_.ProcessName -like '*Stream*' }

if ($streamdeckProcesses) {
    Write-Host "Stream Deck software is running:" -ForegroundColor Green
    $streamdeckProcesses | Select-Object ProcessName, Id, CPU, WorkingSet | Format-Table -AutoSize
} else {
    Write-Host "Stream Deck software is NOT running" -ForegroundColor Yellow
    Write-Host "Try starting the Stream Deck application" -ForegroundColor Yellow
}

# 5. Fix Options
Write-Host ""
Write-Host "=== Fix Options ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Would you like to attempt automated fixes? (Y/N)" -ForegroundColor Yellow
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host ""
    Write-Host "--- Applying Fixes ---" -ForegroundColor Green

    # Fix 1: Disable and re-enable all USB devices with problems
    if ($errorDevices) {
        Write-Host "Fix 1: Resetting problematic USB devices..." -ForegroundColor Cyan
        foreach ($device in $errorDevices) {
            try {
                Write-Host "  Disabling: $($device.FriendlyName)" -ForegroundColor Yellow
                Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Stop
                Start-Sleep -Seconds 2

                Write-Host "  Re-enabling: $($device.FriendlyName)" -ForegroundColor Green
                Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Stop
                Start-Sleep -Seconds 2
            }
            catch {
                Write-Host "  Error resetting device: $_" -ForegroundColor Red
            }
        }
    }

    # Fix 2: Restart Stream Deck processes
    if ($streamdeckProcesses) {
        Write-Host ""
        Write-Host "Fix 2: Restarting Stream Deck software..." -ForegroundColor Cyan
        $streamdeckProcesses | Stop-Process -Force
        Write-Host "  Stream Deck processes stopped. Please restart the application manually." -ForegroundColor Yellow
    }

    # Fix 3: Scan for hardware changes
    Write-Host ""
    Write-Host "Fix 3: Scanning for hardware changes..." -ForegroundColor Cyan
    $devcon = "pnputil /scan-devices"
    try {
        Invoke-Expression $devcon
        Write-Host "  Hardware scan completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  Could not scan for hardware changes: $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "=== Fixes Applied ===" -ForegroundColor Green
    Write-Host "Please check if your Stream Deck is now working." -ForegroundColor Cyan
    Write-Host "If not, try:" -ForegroundColor Yellow
    Write-Host "  1. Physically unplug and replug the Stream Deck" -ForegroundColor Yellow
    Write-Host "  2. Try a different USB port (preferably USB 2.0)" -ForegroundColor Yellow
    Write-Host "  3. Restart your computer" -ForegroundColor Yellow
    Write-Host "  4. Reinstall Stream Deck software from https://www.elgato.com/downloads" -ForegroundColor Yellow
} else {
    Write-Host "No fixes applied. Manual troubleshooting recommended." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Additional Information ===" -ForegroundColor Cyan
Write-Host "Common Stream Deck USB Issues:" -ForegroundColor White
Write-Host "  • Insufficient USB power - Try connecting directly to motherboard USB port" -ForegroundColor Gray
Write-Host "  • USB 3.0 compatibility - Try using a USB 2.0 port instead" -ForegroundColor Gray
Write-Host "  • Driver conflicts - Check Device Manager for unknown devices" -ForegroundColor Gray
Write-Host "  • Cable issues - Try a different USB cable" -ForegroundColor Gray
Write-Host "  • Windows power management - Disable USB selective suspend in Power Options" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host

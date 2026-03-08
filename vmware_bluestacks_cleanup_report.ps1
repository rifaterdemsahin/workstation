# VMware & BlueStacks Cleanup Report Generator
# Generated: 2026-03-08

$reportPath = "C:\projects\workstation\vmware_bluestacks_cleanup_report.md"

# Start report
$report = @"
# VMware & BlueStacks Post-Reboot Cleanup Report

**Report Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Machine:** $env:COMPUTERNAME
**User:** $env:USERNAME

---

## Executive Summary

This report identifies VMware and BlueStacks remnants on the system after attempted removal.

---

## 1. VMware Virtual Machine Files (.vmx)

"@

# Find VMware VM files
Write-Host "Scanning for VMware VM files..." -ForegroundColor Cyan
$vmxFiles = Get-ChildItem -Path C:\ -Recurse -Filter "*.vmx" -ErrorAction SilentlyContinue

$report += @"

**Total VMware VM Files Found:** $($vmxFiles.Count)

"@

if ($vmxFiles) {
    $report += "| File Path | Size (KB) | Last Modified |`n"
    $report += "|-----------|-----------|---------------|`n"
    foreach ($file in $vmxFiles) {
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        $report += "| ``$($file.FullName)`` | $sizeKB | $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |`n"
    }
    $report += "`n"

    # Calculate total size
    $totalSize = ($vmxFiles | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    $report += "**Total VM Configuration Size:** $totalSizeMB MB`n`n"
} else {
    $report += "No VMware VM files found.`n`n"
}

$report += @"

---

## 2. VMware Services

"@

# Get VMware services
Write-Host "Checking VMware services..." -ForegroundColor Cyan
$vmwareServices = Get-Service | Where-Object {$_.DisplayName -like "*VMware*"}

$report += "`n**Total VMware Services:** $($vmwareServices.Count)`n`n"

if ($vmwareServices) {
    $report += "| Service Name | Display Name | Status | Startup Type |`n"
    $report += "|--------------|--------------|--------|--------------|`n"
    foreach ($svc in $vmwareServices) {
        $report += "| ``$($svc.Name)`` | $($svc.DisplayName) | $($svc.Status) | $($svc.StartType) |`n"
    }
    $report += "`n"

    # Service summary
    $runningCount = ($vmwareServices | Where-Object {$_.Status -eq 'Running'}).Count
    $stoppedCount = ($vmwareServices | Where-Object {$_.Status -eq 'Stopped'}).Count
    $autoCount = ($vmwareServices | Where-Object {$_.StartType -eq 'Automatic'}).Count

    $report += "**Service Status Summary:**`n"
    $report += "- Running: $runningCount`n"
    $report += "- Stopped: $stoppedCount`n"
    $report += "- Automatic Startup: $autoCount`n`n"
} else {
    $report += "No VMware services found.`n`n"
}

$report += @"

---

## 3. VMware Installed Packages

"@

# Get VMware packages
Write-Host "Checking installed VMware packages..." -ForegroundColor Cyan
$vmwarePackages = Get-Package *VMware* -ErrorAction SilentlyContinue

$report += "`n**Total VMware Packages:** $($vmwarePackages.Count)`n`n"

if ($vmwarePackages) {
    $report += "| Package Name | Version | Provider |`n"
    $report += "|--------------|---------|----------|`n"
    foreach ($pkg in $vmwarePackages) {
        $report += "| $($pkg.Name) | $($pkg.Version) | $($pkg.ProviderName) |`n"
    }
    $report += "`n"
} else {
    $report += "No VMware packages found via Package Manager.`n`n"
}

$report += @"

---

## 4. BlueStacks Data Directories

"@

# Check for BlueStacks directories
Write-Host "Checking for BlueStacks directories..." -ForegroundColor Cyan
$bluestacksPaths = @(
    "C:\ProgramData\BlueStacks*",
    "C:\Program Files\BlueStacks*",
    "C:\Program Files (x86)\BlueStacks*",
    "$env:USERPROFILE\AppData\Local\BlueStacks*",
    "$env:USERPROFILE\AppData\Roaming\BlueStacks*"
)

$foundDirs = @()
foreach ($path in $bluestacksPaths) {
    $dirs = Get-Item $path -ErrorAction SilentlyContinue
    if ($dirs) {
        $foundDirs += $dirs
    }
}

$report += "`n**BlueStacks Directories Found:** $($foundDirs.Count)`n`n"

if ($foundDirs) {
    $report += "| Directory Path | Created | Last Modified |`n"
    $report += "|----------------|---------|---------------|`n"
    foreach ($dir in $foundDirs) {
        $report += "| ``$($dir.FullName)`` | $($dir.CreationTime.ToString('yyyy-MM-dd')) | $($dir.LastWriteTime.ToString('yyyy-MM-dd')) |`n"
    }
    $report += "`n"
} else {
    $report += "✓ No BlueStacks data directories found. Clean!`n`n"
}

$report += @"

---

## 5. Audio Endpoint Devices

"@

# Get audio devices
Write-Host "Checking audio endpoints..." -ForegroundColor Cyan
$audioDevices = Get-PnpDevice -Class AudioEndpoint

$report += "`n**Total Audio Endpoints:** $($audioDevices.Count)`n`n"

$okDevices = ($audioDevices | Where-Object {$_.Status -eq 'OK'}).Count
$unknownDevices = ($audioDevices | Where-Object {$_.Status -eq 'Unknown'}).Count
$errorDevices = ($audioDevices | Where-Object {$_.Status -eq 'Error'}).Count

$report += "**Audio Device Health Summary:**`n"
$okPercent = [math]::Round(($okDevices / $audioDevices.Count) * 100, 1)
$unknownPercent = [math]::Round(($unknownDevices / $audioDevices.Count) * 100, 1)
$report += "- OK: $okDevices ($okPercent%)`n"
$report += "- Unknown: $unknownDevices ($unknownPercent%)`n"
$report += "- Error: $errorDevices`n`n"

# List problem devices
$problemDevices = $audioDevices | Where-Object {$_.Status -ne 'OK'}
if ($problemDevices) {
    $report += "### Problematic Audio Devices`n`n"
    $report += "| Status | Friendly Name |`n"
    $report += "|--------|---------------|`n"
    foreach ($dev in $problemDevices) {
        $report += "| $($dev.Status) | $($dev.FriendlyName) |`n"
    }
    $report += "`n"
}

$report += @"

---

## 6. Cleanup Recommendations

### High Priority - VMware Removal

"@

if ($vmwareServices) {
    $report += @"

#### Stop Running VMware Services

``````powershell
# Stop all running VMware services
"@
    foreach ($svc in ($vmwareServices | Where-Object {$_.Status -eq 'Running'})) {
        $report += "`nStop-Service -Name '$($svc.Name)' -Force"
    }
    $report += "`n``````"
    $report += "`n`n"

    $report += @"
#### Disable VMware Services

``````powershell
# Set VMware services to disabled
"@
    foreach ($svc in $vmwareServices) {
        $report += "`nSet-Service -Name '$($svc.Name)' -StartupType Disabled"
    }
    $report += "`n``````"
    $report += "`n`n"
}

if ($vmwarePackages) {
    $report += @"
#### Uninstall VMware Packages

``````powershell
# Uninstall VMware packages
"@
    foreach ($pkg in $vmwarePackages) {
        $report += "`nUninstall-Package -Name '$($pkg.Name)' -Force"
    }
    $report += "`n``````"
    $report += "`n`n"
}

if ($vmxFiles) {
    $report += @"
#### Review and Remove VMware VM Files

**WARNING:** Only delete these if you no longer need these virtual machines!

VM Files located at:
"@
    foreach ($file in $vmxFiles) {
        $vmDir = Split-Path $file.FullName
        $report += "`n- ``$vmDir``"
    }
    $report += "`n`n"
}

$report += @"

### Medium Priority - Audio Device Cleanup

"@

if ($problemDevices.Count -gt 0) {
    $report += "`n$($problemDevices.Count) audio devices have 'Unknown' or 'Error' status. These are likely:`n"
    $report += "- Disconnected Bluetooth devices`n"
    $report += "- Virtual audio devices from uninstalled software`n"
    $report += "- Disconnected monitors with audio output`n`n"
    $report += "**Recommendation:** Review in Device Manager and disable/uninstall unused devices.`n`n"
} else {
    $report += "`n✓ All audio devices are in OK status.`n`n"
}

$report += @"

---

## 7. Automated Cleanup Script

Below is a complete cleanup script. **Review carefully before executing!**

``````powershell
# VMware Complete Removal Script
# WARNING: Review all commands before execution

# 1. Stop VMware services
Write-Host "Stopping VMware services..." -ForegroundColor Yellow
"@

if ($vmwareServices) {
    foreach ($svc in ($vmwareServices | Where-Object {$_.Status -eq 'Running'})) {
        $report += "`nStop-Service -Name '$($svc.Name)' -Force -ErrorAction SilentlyContinue"
    }
}

$report += @"


# 2. Disable VMware services
Write-Host "Disabling VMware services..." -ForegroundColor Yellow
"@

if ($vmwareServices) {
    foreach ($svc in $vmwareServices) {
        $report += "`nSet-Service -Name '$($svc.Name)' -StartupType Disabled -ErrorAction SilentlyContinue"
    }
}

$report += @"


# 3. Uninstall VMware packages
Write-Host "Uninstalling VMware packages..." -ForegroundColor Yellow
Get-Package *VMware* -ErrorAction SilentlyContinue | Uninstall-Package -Force

# 4. Review VM directories (manual review required)
Write-Host "`nVirtual Machine Directories:" -ForegroundColor Cyan
"@

if ($vmxFiles) {
    $vmDirs = $vmxFiles | ForEach-Object { Split-Path $_.FullName } | Select-Object -Unique
    foreach ($dir in $vmDirs) {
        $report += "`nWrite-Host '$dir' -ForegroundColor White"
    }
}

$report += @"


Write-Host "`nManually review and delete VM directories if no longer needed." -ForegroundColor Yellow

# 5. Clean registry (advanced - use with caution)
# Uncomment only if comfortable with registry operations
# Remove-Item "HKLM:\SOFTWARE\VMware*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nCleanup script completed!" -ForegroundColor Green
``````

---

## 8. System Health Metrics

### VMware Removal Progress

"@

$vmwarePresence = if ($vmwareServices.Count -gt 0 -or $vmwarePackages.Count -gt 0) { "Incomplete" } else { "Complete" }
$bluestacksPresence = if ($foundDirs.Count -gt 0) { "Remnants Found" } else { "Clean" }
$audioHealth = if ($problemDevices.Count -eq 0) { "Healthy" } else { "Needs Attention" }

$report += @"

| Component | Status | Details |
|-----------|--------|---------|
| VMware Services | $vmwarePresence | $($vmwareServices.Count) services found |
| VMware Packages | $vmwarePresence | $($vmwarePackages.Count) packages found |
| VMware VM Files | $(if ($vmxFiles.Count -gt 0) { 'Present' } else { 'Clean' }) | $($vmxFiles.Count) VM configurations |
| BlueStacks Data | $bluestacksPresence | $($foundDirs.Count) directories found |
| Audio Devices | $audioHealth | $unknownDevices unknown, $errorDevices error |

---

## 9. Next Steps Checklist

- [ ] Review VMware services list and stop running services
- [ ] Disable or uninstall VMware services
- [ ] Uninstall VMware packages via Programs and Features
- [ ] Review VM directories and backup/delete as needed
- [ ] Clean up audio devices in Device Manager
- [ ] Run Windows Disk Cleanup to remove temp files
- [ ] Reboot system and re-run this report to verify cleanup

---

**Report Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Tool:** VMware & BlueStacks Cleanup Report Generator v1.0
"@

# Write report to file
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nReport generated successfully!" -ForegroundColor Green
Write-Host "Location: $reportPath" -ForegroundColor Cyan

# Display summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "VMware Services: $($vmwareServices.Count)" -ForegroundColor White
Write-Host "VMware Packages: $($vmwarePackages.Count)" -ForegroundColor White
Write-Host "VMware VM Files: $($vmxFiles.Count)" -ForegroundColor White
Write-Host "BlueStacks Dirs: $($foundDirs.Count)" -ForegroundColor White
Write-Host "Problem Audio Devices: $($problemDevices.Count)" -ForegroundColor White

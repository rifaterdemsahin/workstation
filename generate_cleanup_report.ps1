# VMware & BlueStacks Cleanup Report Generator v2.0
# Date: 2026-03-08

$reportPath = "C:\projects\workstation\vmware_bluestacks_cleanup_report.md"

# Collect data
Write-Host "Collecting system information..." -ForegroundColor Cyan

# VMware VM files
Write-Host "  - Scanning for VMware VM files..." -ForegroundColor Yellow
$vmxFiles = Get-ChildItem -Path C:\ -Recurse -Filter "*.vmx" -ErrorAction SilentlyContinue

# VMware services
Write-Host "  - Checking VMware services..." -ForegroundColor Yellow
$vmwareServices = Get-Service | Where-Object {$_.DisplayName -like "*VMware*"}

# VMware packages
Write-Host "  - Checking VMware packages..." -ForegroundColor Yellow
$vmwarePackages = Get-Package *VMware* -ErrorAction SilentlyContinue

# BlueStacks directories
Write-Host "  - Checking BlueStacks directories..." -ForegroundColor Yellow
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

# Audio devices
Write-Host "  - Checking audio endpoints..." -ForegroundColor Yellow
$audioDevices = Get-PnpDevice -Class AudioEndpoint
$okDevices = ($audioDevices | Where-Object {$_.Status -eq 'OK'}).Count
$unknownDevices = ($audioDevices | Where-Object {$_.Status -eq 'Unknown'}).Count
$errorDevices = ($audioDevices | Where-Object {$_.Status -eq 'Error'}).Count
$problemDevices = $audioDevices | Where-Object {$_.Status -ne 'OK'}

# Generate report
Write-Host "`nGenerating report..." -ForegroundColor Cyan

@"
# VMware & BlueStacks Post-Reboot Cleanup Report

**Report Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Machine:** $env:COMPUTERNAME
**User:** $env:USERNAME

---

## Executive Summary

This report identifies VMware and BlueStacks remnants on the system after attempted removal.

**Quick Status:**
- VMware Services: $($vmwareServices.Count) found
- VMware Packages: $($vmwarePackages.Count) found
- VMware VM Files: $($vmxFiles.Count) found
- BlueStacks Directories: $($foundDirs.Count) found
- Problem Audio Devices: $($problemDevices.Count) found

---

## 1. VMware Virtual Machine Files (.vmx)

**Total VMware VM Files Found:** $($vmxFiles.Count)

"@ | Out-File -FilePath $reportPath -Encoding UTF8

if ($vmxFiles) {
    "| File Path | Size (KB) | Last Modified |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "|-----------|-----------|---------------|" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    foreach ($file in $vmxFiles) {
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        "| $($file.FullName) | $sizeKB | $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }
    "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    $totalSize = ($vmxFiles | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    "**Total VM Configuration Size:** $totalSizeMB MB" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    "No VMware VM files found." | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

@"

---

## 2. VMware Services

**Total VMware Services:** $($vmwareServices.Count)

"@ | Out-File -FilePath $reportPath -Append -Encoding UTF8

if ($vmwareServices) {
    "| Service Name | Display Name | Status | Startup Type |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "|--------------|--------------|--------|--------------|" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    foreach ($svc in $vmwareServices) {
        "| $($svc.Name) | $($svc.DisplayName) | $($svc.Status) | $($svc.StartType) |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }
    "" | Out-File -FilePath $reportPath -Append -Encoding UTF8

    $runningCount = ($vmwareServices | Where-Object {$_.Status -eq 'Running'}).Count
    $stoppedCount = ($vmwareServices | Where-Object {$_.Status -eq 'Stopped'}).Count
    $autoCount = ($vmwareServices | Where-Object {$_.StartType -eq 'Automatic'}).Count

    "**Service Status Summary:**" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "- Running: $runningCount" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "- Stopped: $stoppedCount" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "- Automatic Startup: $autoCount" | Out-File -FilePath $reportPath -Append -Encoding UTF8
} else {
    "No VMware services found." | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

@"

---

## 3. VMware Installed Packages

**Total VMware Packages:** $($vmwarePackages.Count)

"@ | Out-File -FilePath $reportPath -Append -Encoding UTF8

if ($vmwarePackages) {
    "| Package Name | Version | Provider |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "|--------------|---------|----------|" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    foreach ($pkg in $vmwarePackages) {
        "| $($pkg.Name) | $($pkg.Version) | $($pkg.ProviderName) |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }
} else {
    "No VMware packages found via Package Manager." | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

@"

---

## 4. BlueStacks Data Directories

**BlueStacks Directories Found:** $($foundDirs.Count)

"@ | Out-File -FilePath $reportPath -Append -Encoding UTF8

if ($foundDirs) {
    "| Directory Path | Created | Last Modified |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "|----------------|---------|---------------|" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    foreach ($dir in $foundDirs) {
        "| $($dir.FullName) | $($dir.CreationTime.ToString('yyyy-MM-dd')) | $($dir.LastWriteTime.ToString('yyyy-MM-dd')) |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }
} else {
    "No BlueStacks data directories found. Clean!" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

$okPercent = [math]::Round(($okDevices / $audioDevices.Count) * 100, 1)
$unknownPercent = [math]::Round(($unknownDevices / $audioDevices.Count) * 100, 1)

@"

---

## 5. Audio Endpoint Devices

**Total Audio Endpoints:** $($audioDevices.Count)

**Audio Device Health Summary:**
- OK: $okDevices ($okPercent%)
- Unknown: $unknownDevices ($unknownPercent%)
- Error: $errorDevices

"@ | Out-File -FilePath $reportPath -Append -Encoding UTF8

if ($problemDevices) {
    "### Problematic Audio Devices" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "| Status | Friendly Name |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "|--------|---------------|" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    foreach ($dev in $problemDevices) {
        "| $($dev.Status) | $($dev.FriendlyName) |" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }
}

@"

---

## 6. Cleanup Recommendations

### High Priority - VMware Removal

"@ | Out-File -FilePath $reportPath -Append -Encoding UTF8

if ($vmwareServices) {
    @"

#### Stop Running VMware Services

``````powershell
# Stop all running VMware services
"@ | Out-File -FilePath $reportPath -Append -Encoding UTF8

    foreach ($svc in ($vmwareServices | Where-Object {$_.Status -eq 'Running'})) {
        "Stop-Service -Name '$($svc.Name)' -Force" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    }
    "``````" | Out-File -FilePath $reportPath -Append -Encoding UTF8
    "" | Out-File -FilePath $reportPath -Append -Encoding UTF8
}

@"

### Complete Cleanup Script

See: ``post_reboot_check.ps1`` for automated cleanup

---

## 7. System Health Metrics

| Component | Status | Details |
|-----------|--------|---------|
| VMware Services | $(if ($vmwareServices.Count -gt 0) { 'Incomplete' } else { 'Complete' }) | $($vmwareServices.Count) services found |
| VMware Packages | $(if ($vmwarePackages.Count -gt 0) { 'Incomplete' } else { 'Complete' }) | $($vmwarePackages.Count) packages found |
| VMware VM Files | $(if ($vmxFiles.Count -gt 0) { 'Present' } else { 'Clean' }) | $($vmxFiles.Count) VM configurations |
| BlueStacks Data | $(if ($foundDirs.Count -gt 0) { 'Remnants Found' } else { 'Clean' }) | $($foundDirs.Count) directories found |
| Audio Devices | $(if ($problemDevices.Count -eq 0) { 'Healthy' } else { 'Needs Attention' }) | $unknownDevices unknown, $errorDevices error |

---

## 8. Next Steps Checklist

- [ ] Review VMware services list and stop running services
- [ ] Disable or uninstall VMware services
- [ ] Uninstall VMware packages via Programs and Features
- [ ] Review VM directories and backup/delete as needed
- [ ] Clean up audio devices in Device Manager
- [ ] Run Windows Disk Cleanup to remove temp files
- [ ] Reboot system and re-run this report to verify cleanup

---

**Report Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Tool:** VMware & BlueStacks Cleanup Report Generator v2.0
"@ | Out-File -FilePath $reportPath -Append -Encoding UTF8

Write-Host "`nReport generated successfully!" -ForegroundColor Green
Write-Host "Location: $reportPath" -ForegroundColor Cyan

# Display summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "VMware Services: $($vmwareServices.Count)" -ForegroundColor White
Write-Host "VMware Packages: $($vmwarePackages.Count)" -ForegroundColor White
Write-Host "VMware VM Files: $($vmxFiles.Count)" -ForegroundColor White
Write-Host "BlueStacks Dirs: $($foundDirs.Count)" -ForegroundColor White
Write-Host "Problem Audio Devices: $($problemDevices.Count)" -ForegroundColor White
Write-Host "`nFull report saved to: $reportPath" -ForegroundColor Cyan

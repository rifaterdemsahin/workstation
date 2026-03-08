# Post-reboot check - confirm BlueStacks is fully gone

Write-Host "`n=== BlueStacks and VMware Service Check ===" -ForegroundColor Cyan
$virtualServices = Get-Service | Where-Object {$_.DisplayName -like "*Blue*" -or $_.DisplayName -like "*VMware*"}

if ($virtualServices) {
    $virtualServices | Format-Table DisplayName, Status, StartType -AutoSize
    Write-Host "`nWARNING: Found $($virtualServices.Count) BlueStacks/VMware related services!" -ForegroundColor Yellow
} else {
    Write-Host "CLEAN: No BlueStacks or VMware services found!" -ForegroundColor Green
}

Write-Host "`n=== Audio Endpoint Device Status ===" -ForegroundColor Cyan
$audioDevices = Get-PnpDevice -Class AudioEndpoint | Select-Object Status, FriendlyName, InstanceId

# Display summary
$okDevices = ($audioDevices | Where-Object {$_.Status -eq 'OK'}).Count
$unknownDevices = ($audioDevices | Where-Object {$_.Status -eq 'Unknown'}).Count
$totalDevices = $audioDevices.Count

Write-Host "`nAudio Device Summary:" -ForegroundColor White
Write-Host "  Total Devices: $totalDevices" -ForegroundColor White
Write-Host "  OK Status: $okDevices" -ForegroundColor Green
Write-Host "  Unknown Status: $unknownDevices" -ForegroundColor $(if ($unknownDevices -gt 0) { 'Yellow' } else { 'Green' })

Write-Host "`nDetailed Audio Devices:" -ForegroundColor White
$audioDevices | Format-Table Status, FriendlyName -AutoSize

# Check for problematic devices
Write-Host "`n=== Unknown/Problem Audio Devices ===" -ForegroundColor Cyan
$problemDevices = $audioDevices | Where-Object {$_.Status -ne 'OK'}
if ($problemDevices) {
    $problemDevices | Format-Table Status, FriendlyName, InstanceId -AutoSize
    Write-Host "`nWARNING: Found $($problemDevices.Count) audio devices with issues!" -ForegroundColor Yellow
} else {
    Write-Host "CLEAN: All audio devices are in OK status!" -ForegroundColor Green
}

Write-Host "`n=== Check Complete ===" -ForegroundColor Cyan

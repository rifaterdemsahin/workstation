# 1. Get all USB Controllers and their current status
Write-Host "--- USB Controller Status ---" -ForegroundColor Cyan
Get-PnpDevice -PresentOnly | Where-Object { $_.Class -eq "USB" } | 
Select-Object FriendlyName, InstanceId, Status | Format-Table -AutoSize

# 2. Specifically look for the Stream Deck or 'Unknown' USB devices
Write-Host "--- Potential Stream Deck or Error Issues ---" -ForegroundColor Yellow
Get-PnpDevice | Where-Object { ($_.FriendlyName -like "*Stream Deck*" -or $_.Status -ne "OK") -and $_.Class -eq "USB" } |
Select-Object FriendlyName, Status, Problem, ConfigManagerErrorCode | Format-Table -AutoSize

# 3. List USB Hubs that might be limiting power
Write-Host "--- USB Hub Power Check ---" -ForegroundColor Green
Get-WmiObject Win32_USBHub | Select-Object DeviceID, Description, Status | Format-Table -AutoSize
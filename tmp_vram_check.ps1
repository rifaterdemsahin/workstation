$base = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
Get-ChildItem $base | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
    $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
    if ($p.DriverDesc) {
        Write-Host "--- $($_.PSChildName): $($p.DriverDesc)"
        Write-Host "    MemorySize:   $($p.'HardwareInformation.MemorySize')"
        Write-Host "    qwMemorySize: $($p.'HardwareInformation.qwMemorySize')"
    }
}

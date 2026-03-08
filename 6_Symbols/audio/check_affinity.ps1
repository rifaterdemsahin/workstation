$p = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue
if ($p) {
    $aff = [long]$p.ProcessorAffinity
    $hex = "0x{0:X}" -f $aff
    Write-Host "PID      : $($p.Id)"
    Write-Host "Affinity : $hex  ($aff decimal)"
    if ($aff -eq 0xFFFFFFFF) {
        Write-Host "Status   : CORRECT - cores 0-31 only (NUMA node 0)" -ForegroundColor Green
    } else {
        Write-Host "Status   : NOT SET - full 64 cores active" -ForegroundColor Yellow
    }
} else {
    Write-Host "Resolve is not running." -ForegroundColor Red
}

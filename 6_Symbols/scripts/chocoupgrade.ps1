choco upgrade all --confirm

# Log to second brain
$secondBrainLogPath = "F:\secondbrain_v4\secondbrain\system-updates.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = @"

=== Chocolatey Upgrade: $timestamp ===
Command: choco upgrade all --confirm
Script: chocoupgrade.ps1
"@

try {
    Add-Content -Path $secondBrainLogPath -Value $logEntry -ErrorAction SilentlyContinue
    Write-Host "Update logged to second brain" -ForegroundColor Green
}
catch {
    Write-Warning "Could not write to second brain log"
}
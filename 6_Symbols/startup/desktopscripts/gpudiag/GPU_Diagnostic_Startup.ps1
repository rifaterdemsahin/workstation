# GPU Diagnostic Startup Service
# Runs continuously every 5 minutes to monitor DaVinci Resolve and GPU health
# Minimal performance impact - runs in background

# Configuration
$LogDir = "C:\ProgramData\GPU_Diagnostics"
$CheckIntervalSeconds = 300  # Run every 5 minutes (300 seconds)
$RunContinuously = $true

# Create log directory if it doesn't exist
if (-not (Test-Path $LogDir)) {
    try {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    catch {
        # Fallback to temp if ProgramData is not accessible
        $LogDir = "$env:TEMP\GPU_Diagnostics"
        $LogFile = "$LogDir\diagnostic_$(Get-Date -Format 'yyyy-MM-dd').log"
        $ReportFile = "$LogDir\latest_report.txt"
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
}

# Function to log messages
function Log-Message {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    try {
        Add-Content -Path $LogFile -Value $logEntry -Force
    }
    catch {
        Write-Host "Error writing to log: $_"
    }
    
    if ($Type -eq "ERROR" -or $Type -eq "WARNING") {
        Write-Host $logEntry -ForegroundColor $(if ($Type -eq "ERROR") { "Red" } else { "Yellow" })
    }
    else {
        Write-Host $logEntry -ForegroundColor Green
    }
}

# Main monitoring loop
$runCount = 0
while ($RunContinuously) {
    $runCount++

    # Update log file path daily
    $LogFile = "$LogDir\diagnostic_$(Get-Date -Format 'yyyy-MM-dd').log"
    $ReportFile = "$LogDir\latest_report.txt"

    # Initialize log for this run
    Log-Message "====== GPU DIAGNOSTIC CHECK #$runCount ======"
    Log-Message "Starting system diagnostics..."

try {
    # 1. Quick GPU Status (Fast)
    Log-Message "Scanning GPU status..."
    $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Basic*" -and $_.Name -notlike "*Microsoft Remote Display Adapter*" } | Select-Object -First 1
    
    if ($gpu) {
        $vram = [math]::Round($gpu.AdapterRAM / 1GB, 2)
        Log-Message "GPU: $($gpu.Name) | Driver: $($gpu.DriverVersion) | VRAM: ${vram}GB"
    }
    else {
        Log-Message "No discrete GPU detected" "WARNING"
    }

    # 2. PCIe Device Status (Fast)
    Log-Message "Checking PCIe devices..."
    $pciDevices = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue
    
    foreach ($device in $pciDevices) {
        if ($device.Status -ne "OK") {
            Log-Message "PCIe Issue: $($device.Name) - Status: $($device.Status)" "ERROR"
        }
        else {
            Log-Message "PCIe OK: $($device.Name)"
        }
    }

    # 3. Critical Hardware Errors Only (Last 12 hours)
    Log-Message "Scanning Event Viewer for PCIe/GPU errors..."
    $cutoff = (Get-Date).AddHours(-12)
    
    $criticalErrors = Get-WinEvent -LogName System -FilterXPath "*[System[TimeCreated[@SystemTime>'$($cutoff.ToUniversalTime().ToString('o'))'] and (EventID=15 or EventID=46)]]" -ErrorAction SilentlyContinue | 
    Where-Object { $_.Message -like "*PCI*" -or $_.Message -like "*GPU*" -or $_.Message -like "*ProRes*" }
    
    if ($criticalErrors) {
        Log-Message "CRITICAL: PCIe/GPU errors detected!" "ERROR"
        foreach ($error in $criticalErrors | Select-Object -First 3) {
            $msg = $error.Message.Substring(0, [Math]::Min(100, $error.Message.Length))
            Log-Message "  - $msg" "ERROR"
        }
    }
    else {
        Log-Message "No critical PCIe/GPU errors in last 12 hours"
    }

    # 4. Memory Health (Quick)
    Log-Message "Checking system memory..."
    $mem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $usedPercent = [math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize * 100, 2)
    $usedMB = [math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / 1024, 0)
    
    Log-Message "Memory Usage: $usedPercent% (${usedMB}MB used)"
    
    if ($usedPercent -gt 90) {
        Log-Message "HIGH MEMORY USAGE DETECTED" "WARNING"
    }

    # 5. Disk Space (Quick)
    Log-Message "Checking disk space..."
    $systemDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
    
    if ($systemDrive) {
        $diskUsedPercent = [math]::Round(($systemDrive.Size - $systemDrive.FreeSpace) / $systemDrive.Size * 100, 2)
        $freeGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        Log-Message "C: Drive - $diskUsedPercent% used (${freeGB}GB free)"
        
        if ($diskUsedPercent -gt 90) {
            Log-Message "LOW DISK SPACE - Consider cleanup" "WARNING"
        }
    }

    # 6. Check for DaVinci Resolve Crashes (Last 6 hours)
    Log-Message "Checking for DaVinci Resolve issues..."
    $resolveErrors = Get-WinEvent -LogName Application -ErrorAction SilentlyContinue | 
    Where-Object { $_.TimeCreated -gt (Get-Date).AddHours(-6) -and $_.Message -like "*DaVinci*" } | 
    Select-Object -First 1
    
    if ($resolveErrors) {
        Log-Message "DaVinci Resolve errors detected in Application log" "WARNING"
    }
    else {
        Log-Message "No recent DaVinci Resolve errors"
    }

    Log-Message "====== DIAGNOSTIC COMPLETE ======"
    $nextCheck = (Get-Date).AddSeconds($CheckIntervalSeconds)
    Log-Message "Next check: $(Get-Date -Date $nextCheck -Format 'yyyy-MM-dd HH:mm:ss') (in $($CheckIntervalSeconds/60) minutes)"

}
catch {
    Log-Message "FATAL ERROR: $($_.Exception.Message)" "ERROR"
}

# Generate Human-Readable Report
try {
    $recents = if ($criticalErrors) { "WARNING: PCIe/GPU errors detected - Check Event Viewer!" } else { "OK: No critical errors" }
    
    $gpuName = if ($gpu) { $gpu.Name } else { "Unknown" }
    $driverVer = if ($gpu) { $gpu.DriverVersion } else { "Unknown" }
    $vramInfo = if ($gpu) { "$([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB" } else { "Unknown" }
    
    $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
    $diskInfo = if ($systemDrive) { "$([math]::Round(($systemDrive.Size - $systemDrive.FreeSpace) / $systemDrive.Size * 100, 2))%" } else { "Unknown" }

    $report = @"
GPU DIAGNOSTIC REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================
SYSTEM INFO:
- Computer: $($env:COMPUTERNAME)
- User: $($env:USERNAME)
- OS: $osInfo

LATEST GPU STATUS:
- GPU: $gpuName
- Driver Version: $driverVer
- VRAM: $vramInfo

SYSTEM RESOURCES:
- Memory Used: $usedPercent%
- Disk C: $diskInfo

RECENT ISSUES:
$recents

RECOMMENDATIONS:
1. Monitor GPU temperature - should stay below 80C during work
2. Keep drivers updated
3. Check Event Viewer regularly for PCIe errors
4. Reseat GPU if PCIe errors appear

FULL LOGS: $LogFile
"@
    
    $report | Out-File -FilePath $ReportFile -Force
    
}
catch {
    Log-Message "Failed to generate report: $($_.Exception.Message)" "ERROR"
}

# Cleanup old logs (keep only 30 days)
try {
    Get-ChildItem -Path $LogDir -Filter "diagnostic_*.log" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force -ErrorAction SilentlyContinue
}
catch {
    Log-Message "Cleanup error: $($_.Exception.Message)" "WARNING"
}

    # Wait for next check interval
    Log-Message "Waiting for next check cycle... (Press Ctrl+C to stop monitoring)"
    Start-Sleep -Seconds $CheckIntervalSeconds
}

# This line is only reached if $RunContinuously is set to $false
Log-Message "Monitoring stopped."
exit 0

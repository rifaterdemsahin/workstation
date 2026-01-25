# GPU Diagnostic Startup Service
# Runs at Windows startup and logs results
# Minimal performance impact - runs in background

# Configuration
$LogDir = "C:\ProgramData\GPU_Diagnostics"
$LogFile = "$LogDir\diagnostic_$(Get-Date -Format 'yyyy-MM-dd').log"
$ReportFile = "$LogDir\latest_report.txt"

# Create log directory if it doesn't exist
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Function to log messages
function Log-Message {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    Add-Content -Path $LogFile -Value $logEntry -Force
    if ($Type -eq "ERROR") {
        Write-Host $logEntry -ForegroundColor Red
    }
}

# Initialize log
Log-Message "====== GPU DIAGNOSTIC STARTUP SERVICE ======"
Log-Message "Starting system diagnostics..."

try {
    # 1. Quick GPU Status (Fast)
    Log-Message "Scanning GPU status..."
    $gpu = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue | Where-Object {$_.Name -notlike "*Basic*"} | Select-Object -First 1
    
    if ($gpu) {
        Log-Message "GPU: $($gpu.Name) | Driver: $($gpu.DriverVersion) | VRAM: $([math]::Round($gpu.AdapterRAM / 1GB, 2))GB"
    } else {
        Log-Message "No discrete GPU detected" "WARNING"
    }

    # 2. PCIe Device Status (Fast)
    Log-Message "Checking PCIe devices..."
    $pciDevices = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue
    
    foreach ($device in $pciDevices) {
        if ($device.Status -ne "OK") {
            Log-Message "PCIe Issue: $($device.Name) - Status: $($device.Status)" "ERROR"
        } else {
            Log-Message "PCIe OK: $($device.Name)"
        }
    }

    # 3. Critical Hardware Errors Only (Last 12 hours)
    Log-Message "Scanning Event Viewer for PCIe/GPU errors..."
    $cutoff = (Get-Date).AddHours(-12)
    
    $criticalErrors = Get-WinEvent -LogName System -FilterXPath "*[System[TimeCreated[@SystemTime>'$($cutoff.ToUniversalTime().ToString('o'))'] and (EventID=15 or EventID=46)]]" -ErrorAction SilentlyContinue | `
                      Where-Object {$_.Message -like "*PCI*" -or $_.Message -like "*GPU*" -or $_.Message -like "*ProRes*"}
    
    if ($criticalErrors) {
        Log-Message "⚠ CRITICAL: PCIe/GPU errors detected!" "ERROR"
        foreach ($error in $criticalErrors | Select-Object -First 3) {
            Log-Message "  - $($error.Message.Substring(0, [Math]::Min(100, $error.Message.Length)))" "ERROR"
        }
    } else {
        Log-Message "No critical PCIe/GPU errors in last 12 hours"
    }

    # 4. Memory Health (Quick)
    Log-Message "Checking system memory..."
    $mem = Get-WmiObject Win32_OperatingSystem -ErrorAction SilentlyContinue
    $usedPercent = [math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize * 100, 2)
    
    Log-Message "Memory Usage: $usedPercent% ($([math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / 1MB, 0))MB used)"
    
    if ($usedPercent -gt 90) {
        Log-Message "⚠ HIGH MEMORY USAGE DETECTED" "WARNING"
    }

    # 5. Disk Space (Quick)
    Log-Message "Checking disk space..."
    $systemDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
    
    if ($systemDrive) {
        $usedPercent = [math]::Round(($systemDrive.Size - $systemDrive.FreeSpace) / $systemDrive.Size * 100, 2)
        Log-Message "C: Drive - $usedPercent% used ($([math]::Round($systemDrive.FreeSpace / 1GB, 2))GB free)"
        
        if ($usedPercent -gt 90) {
            Log-Message "⚠ LOW DISK SPACE - Consider cleanup" "WARNING"
        }
    }

    # 6. GPU Temperature Check (if available)
    Log-Message "Checking GPU temperature..."
    try {
        $temps = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($temps) {
            $celsius = [math]::Round(($temps.CurrentTemperature / 10) - 273.15, 2)
            Log-Message "Thermal Zone: $celsius°C"
            if ($celsius -gt 85) {
                Log-Message "⚠ HIGH TEMPERATURE - Check GPU cooling" "WARNING"
            }
        }
    } catch {
        Log-Message "Temperature sensor unavailable"
    }

    # 7. Check for DaVinci Resolve Crashes (Last 6 hours)
    Log-Message "Checking for DaVinci Resolve issues..."
    $resolveErrors = Get-WinEvent -LogName Application -ErrorAction SilentlyContinue | `
                     Where-Object {$_.TimeCreated -gt (Get-Date).AddHours(-6) -and $_.Message -like "*DaVinci*"} | `
                     Select-Object -First 1
    
    if ($resolveErrors) {
        Log-Message "⚠ DaVinci Resolve errors detected in Application log" "WARNING"
    } else {
        Log-Message "No recent DaVinci Resolve errors"
    }

    Log-Message "====== DIAGNOSTIC COMPLETE ======"
    Log-Message "Next check: $(Get-Date -Date (Get-Date).AddDays(1) -Format 'yyyy-MM-dd HH:00:00')"

} catch {
    Log-Message "FATAL ERROR: $($_.Exception.Message)" "ERROR"
}

# Generate Human-Readable Report
try {
    $report = @"
GPU DIAGNOSTIC REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================

SYSTEM INFO:
- Computer: $($env:COMPUTERNAME)
- User: $($env:USERNAME)
- OS: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption)

LATEST GPU STATUS:
- GPU: $($gpu.Name)
- Driver Version: $($gpu.DriverVersion)
- VRAM: $([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB

SYSTEM RESOURCES:
- Memory Used: $usedPercent%
- Disk C: $([math]::Round(($systemDrive.Size - $systemDrive.FreeSpace) / $systemDrive.Size * 100, 2))%

RECENT ISSUES:
$( if ($criticalErrors) { "⚠ PCIe/GPU errors detected - Check Event Viewer!" } else { "✓ No critical errors" })

RECOMMENDATIONS:
1. Monitor GPU temperature - should stay below 80°C during work
2. Keep drivers updated (AMD.com)
3. Check Event Viewer regularly for PCIe errors
4. Reseat GPU if PCIe errors appear

FULL LOGS: $LogFile
"@

    $report | Out-File -FilePath $ReportFile -Force
    
} catch {
    Log-Message "Failed to generate report: $($_.Exception.Message)" "ERROR"
}

# Cleanup old logs (keep only 30 days)
try {
    Get-ChildItem -Path $LogDir -Filter "diagnostic_*.log" -ErrorAction SilentlyContinue | `
        Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | `
        Remove-Item -Force -ErrorAction SilentlyContinue
} catch {
    Log-Message "Cleanup error: $($_.Exception.Message)" "WARNING"
}

exit 0

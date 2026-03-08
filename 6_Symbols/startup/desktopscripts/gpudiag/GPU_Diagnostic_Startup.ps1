# GPU Diagnostic Startup Service
# Runs continuously every 5 minutes to monitor DaVinci Resolve and GPU health
# Minimal performance impact - runs in background

# Configuration
$LogDir = "C:\ProgramData\GPU_Diagnostics"
$CheckIntervalSeconds = 300  # Run every 5 minutes (300 seconds)
$RunContinuously = $true  # Set to $false for testing, $true for continuous monitoring

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

# Function to log messages with emojis and colors
function Log-Message {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Add emojis based on type (using proper Unicode for emojis)
    $emojiMap = @{
        "ERROR"   = [System.Char]::ConvertFromUtf32(0x1F534)  # Red circle
        "WARNING" = [System.Char]::ConvertFromUtf32(0x26A0)   # Warning sign
        "SUCCESS" = [System.Char]::ConvertFromUtf32(0x2705)   # Check mark
        "INFO"    = [System.Char]::ConvertFromUtf32(0x2139)   # Info
        "GPU"     = [System.Char]::ConvertFromUtf32(0x1F3AE)  # Game controller
        "MEMORY"  = [System.Char]::ConvertFromUtf32(0x1F9E0)  # Brain
        "DISK"    = [System.Char]::ConvertFromUtf32(0x1F4BE)  # Floppy disk
        "CHECK"   = [System.Char]::ConvertFromUtf32(0x1F50D)  # Magnifying glass
        "TIMER"   = [System.Char]::ConvertFromUtf32(0x23F0)   # Alarm clock
    }

    $emoji = if ($emojiMap.ContainsKey($Type)) { $emojiMap[$Type] } else { [System.Char]::ConvertFromUtf32(0x2139) }

    $logEntry = "[$timestamp] [$Type] $Message"
    $displayEntry = "$emoji [$timestamp] $Message"

    try {
        Add-Content -Path $LogFile -Value $logEntry -Force
    }
    catch {
        $cross = [System.Char]::ConvertFromUtf32(0x274C)
        Write-Host "$cross Error writing to log: $_" -ForegroundColor Red
    }

    # Enhanced color scheme
    $color = switch ($Type) {
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "GPU"     { "Cyan" }
        "MEMORY"  { "Magenta" }
        "DISK"    { "Blue" }
        "CHECK"   { "DarkCyan" }
        "TIMER"   { "DarkYellow" }
        default   { "Gray" }
    }

    Write-Host $displayEntry -ForegroundColor $color
}

# Helper: real VRAM from registry (Win32_VideoController caps at 4GB for >4GB cards)
function Get-RealVram {
    param([string]$DriverDesc)
    $base = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    try {
        foreach ($key in (Get-ChildItem $base -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' })) {
            $p = Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue
            if ($p -and $p.DriverDesc -and $DriverDesc -like "*$($p.DriverDesc)*") {
                # qwMemorySize is a QWORD (64-bit) — accurate for >4GB cards
                # MemorySize is a DWORD (32-bit) — caps at ~4GB, unreliable
                $mem = $p.'HardwareInformation.qwMemorySize'
                if (-not $mem) { $mem = $p.'HardwareInformation.MemorySize' }
                if ($mem -and [int64]$mem -gt 0) { return [math]::Round([int64]$mem / 1GB, 2) }
            }
        }
    } catch {}
    return $null
}

# Main monitoring loop
$runCount = 0
while ($RunContinuously) {
    $runCount++

    # Update log file path daily
    $LogFile = "$LogDir\diagnostic_$(Get-Date -Format 'yyyy-MM-dd').log"
    $ReportFile = "$LogDir\latest_report.txt"

    # Initialize log for this run
    $rocket = [System.Char]::ConvertFromUtf32(0x1F680)
    Write-Host "`n$rocket ====== GPU DIAGNOSTIC CHECK #$runCount ======" -ForegroundColor Cyan
    Log-Message "Starting system diagnostics..." "CHECK"

try {
    # 1. GPU Status - all GPUs
    Log-Message "Scanning GPU status..." "CHECK"
    $allGpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "*Basic*" -and $_.Name -notlike "*Microsoft Remote Display Adapter*" }

    # Use first discrete GPU for report summary (prefer AMD/NVIDIA over DisplayLink)
    $gpu = $allGpus | Where-Object { $_.Name -notlike "*DisplayLink*" } | Select-Object -First 1
    if (-not $gpu) { $gpu = $allGpus | Select-Object -First 1 }

    # GPU perf counters via Windows Performance Counters (keyed by adapter LUID)
    $gpuUtilByLuid = @{}
    $gpuMemByLuid  = @{}
    try {
        # Aggregate 3D utilization per LUID across all processes/engines
        $utilSamples = (Get-Counter "\GPU Engine(*engtype_3D)\Utilization Percentage" -ErrorAction SilentlyContinue).CounterSamples
        foreach ($s in $utilSamples) {
            if ($s.InstanceName -match 'luid_(0x[0-9a-fA-F]+_0x[0-9a-fA-F]+)') {
                $luid = $Matches[1]
                if (-not $gpuUtilByLuid.ContainsKey($luid)) { $gpuUtilByLuid[$luid] = 0.0 }
                $gpuUtilByLuid[$luid] += $s.CookedValue
            }
        }
        # Dedicated VRAM currently in use per LUID
        $memSamples = (Get-Counter "\GPU Adapter Memory(*)\Dedicated Usage" -ErrorAction SilentlyContinue).CounterSamples
        foreach ($s in $memSamples) {
            if ($s.InstanceName -match 'luid_(0x[0-9a-fA-F]+_0x[0-9a-fA-F]+)') {
                $luid = $Matches[1]
                $gpuMemByLuid[$luid] = [math]::Round($s.CookedValue / 1MB, 0)
            }
        }
    } catch {}

    # The LUID with the highest dedicated VRAM usage = discrete GPU (AMD).
    # DisplayLink uses shared memory only, so its dedicated usage is 0.
    $discreteLuid = $gpuMemByLuid.Keys | Sort-Object { $gpuMemByLuid[$_] } -Descending | Select-Object -First 1

    # Try rocm-smi / amd-smi for AMD temperature (check known install paths too)
    $rocmLines = @()
    $amdTool   = $null
    $amdArgs   = @()
    if     (Get-Command "rocm-smi" -ErrorAction SilentlyContinue) { $amdTool = "rocm-smi"; $amdArgs = @("--showtemp","--showuse","--showmemuse","--csv") }
    elseif (Get-Command "amd-smi"  -ErrorAction SilentlyContinue) { $amdTool = "amd-smi";  $amdArgs = @("metric","--gpu","0","--temperature","--usage") }
    else {
        foreach ($p in @("C:\Program Files\AMD\ROCm\bin\rocm-smi.exe","C:\Program Files\AMD\ROCm\bin\amd-smi.exe")) {
            if (Test-Path $p) { $amdTool = $p; $amdArgs = @("--showtemp","--showuse","--showmemuse","--csv"); break }
        }
    }
    if ($amdTool) {
        try {
            $rocmOut = & $amdTool @amdArgs 2>$null
            if ($rocmOut) { $rocmLines = $rocmOut | Select-Object -Skip 1 | Where-Object { $_.Trim() } }
        } catch {}
    }

    if ($allGpus) {
        foreach ($g in $allGpus) {
            $realVram = Get-RealVram $g.Name
            $vramDisplay = if ($realVram) { "${realVram}GB" } else { "$([math]::Round($g.AdapterRAM / 1GB, 2))GB" }

            $isDiscrete = $g.Name -notlike "*DisplayLink*"
            $utilStr = ""
            $memStr  = ""
            if ($isDiscrete -and $discreteLuid) {
                $util    = [math]::Round($gpuUtilByLuid[$discreteLuid], 1)
                $memUsed = $gpuMemByLuid[$discreteLuid]
                $utilStr = " | 3D Util: ${util}%"
                $memStr  = " | VRAM Used: ${memUsed}MB"
            }

            Log-Message "GPU: $($g.Name) | Driver: $($g.DriverVersion) | VRAM: ${vramDisplay}${utilStr}${memStr}" "GPU"
        }

        if ($rocmLines.Count -gt 0) {
            Log-Message "AMD temp ($amdTool):" "GPU"
            foreach ($line in $rocmLines) { Log-Message "  $line" "GPU" }
        } elseif ($allGpus | Where-Object { $_.Name -like "*AMD*" -or $_.Name -like "*Radeon*" }) {
            $scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
            Log-Message "AMD temp unavailable -- run: $scriptDir\Install-AMDTemp.ps1 (as Admin)" "WARNING"
        }
    }
    else {
        Log-Message "No discrete GPU detected" "WARNING"
    }

    # 2. PCIe Device Status (Fast)
    Log-Message "Checking PCIe devices..." "CHECK"
    $pciDevices = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue

    foreach ($device in $pciDevices) {
        if ($device.Status -ne "OK") {
            Log-Message "PCIe Issue: $($device.Name) - Status: $($device.Status)" "ERROR"
        }
        else {
            Log-Message "PCIe OK: $($device.Name)" "SUCCESS"
        }
    }

    # 3. Critical Hardware Errors Only (Last 12 hours)
    Log-Message "Scanning Event Viewer for PCIe/GPU errors..." "CHECK"
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
        Log-Message "No critical PCIe/GPU errors in last 12 hours" "SUCCESS"
    }

    # 4. Memory Health (Quick)
    Log-Message "Checking system memory..." "CHECK"
    $mem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $usedPercent = [math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize * 100, 2)
    $usedMB = [math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / 1024, 0)

    Log-Message "Memory Usage: $usedPercent% (${usedMB}MB used)" "MEMORY"

    if ($usedPercent -gt 90) {
        Log-Message "HIGH MEMORY USAGE DETECTED" "WARNING"
    }

    # 5. Disk Space (Quick)
    Log-Message "Checking disk space..." "CHECK"
    $systemDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue

    if ($systemDrive) {
        $diskUsedPercent = [math]::Round(($systemDrive.Size - $systemDrive.FreeSpace) / $systemDrive.Size * 100, 2)
        $freeGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        Log-Message "C: Drive - $diskUsedPercent% used (${freeGB}GB free)" "DISK"

        if ($diskUsedPercent -gt 90) {
            Log-Message "LOW DISK SPACE - Consider cleanup" "WARNING"
        }
    }

    # 6. Check for DaVinci Resolve Crashes (Last 6 hours)
    Log-Message "Checking for DaVinci Resolve issues..." "CHECK"
    $resolveErrors = Get-WinEvent -LogName Application -ErrorAction SilentlyContinue |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddHours(-6) -and $_.Message -like "*DaVinci*" } |
    Select-Object -First 1

    if ($resolveErrors) {
        Log-Message "DaVinci Resolve errors detected in Application log" "WARNING"
    }
    else {
        Log-Message "No recent DaVinci Resolve errors" "SUCCESS"
    }

    $sparkles = [System.Char]::ConvertFromUtf32(0x2728)
    Write-Host "`n$sparkles ====== DIAGNOSTIC COMPLETE ======" -ForegroundColor Green
    $nextCheck = (Get-Date).AddSeconds($CheckIntervalSeconds)
    Log-Message "Next check: $(Get-Date -Date $nextCheck -Format 'yyyy-MM-dd HH:mm:ss') (in $($CheckIntervalSeconds/60) minutes)" "TIMER"

}
catch {
    Log-Message "FATAL ERROR: $($_.Exception.Message)" "ERROR"
}

# Generate Human-Readable Report
try {
    $warningEmoji = [System.Char]::ConvertFromUtf32(0x26A0)
    $checkEmoji = [System.Char]::ConvertFromUtf32(0x2705)
    $recents = if ($criticalErrors) { "$warningEmoji WARNING: PCIe/GPU errors detected - Check Event Viewer!" } else { "$checkEmoji OK: No critical errors" }

    $gpuLines = if ($allGpus) {
        ($allGpus | ForEach-Object {
            $rv = Get-RealVram $_.Name
            $v  = if ($rv) { "${rv}GB" } else { "$([math]::Round($_.AdapterRAM / 1GB, 2))GB" }
            "- $($_.Name) | Driver: $($_.DriverVersion) | VRAM: $v"
        }) -join "`n"
    } else { "- Unknown" }
    $osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
    $diskInfo = if ($systemDrive) { "$([math]::Round(($systemDrive.Size - $systemDrive.FreeSpace) / $systemDrive.Size * 100, 2))%" } else { "Unknown" }

    $gamepad = [System.Char]::ConvertFromUtf32(0x1F3AE)
    $computer = [System.Char]::ConvertFromUtf32(0x1F4BB)
    $chart = [System.Char]::ConvertFromUtf32(0x1F4CA)
    $magnify = [System.Char]::ConvertFromUtf32(0x1F50D)
    $bulb = [System.Char]::ConvertFromUtf32(0x1F4A1)
    $thermometer = [System.Char]::ConvertFromUtf32(0x1F321)
    $arrows = [System.Char]::ConvertFromUtf32(0x1F504)
    $clipboard = [System.Char]::ConvertFromUtf32(0x1F4CB)
    $wrench = [System.Char]::ConvertFromUtf32(0x1F527)
    $folder = [System.Char]::ConvertFromUtf32(0x1F4C1)

    $report = @"
$gamepad GPU DIAGNOSTIC REPORT $gamepad
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================
$computer SYSTEM INFO:
- Computer: $($env:COMPUTERNAME)
- User: $($env:USERNAME)
- OS: $osInfo

$gamepad ALL GPUs:
$gpuLines

$chart SYSTEM RESOURCES:
- Memory Used: $usedPercent%
- Disk C: $diskInfo

$magnify RECENT ISSUES:
$recents

$bulb RECOMMENDATIONS:
1. $thermometer Monitor GPU temperature - should stay below 80C during work
2. $arrows Keep drivers updated
3. $clipboard Check Event Viewer regularly for PCIe errors
4. $wrench Reseat GPU if PCIe errors appear

$folder FULL LOGS: $LogFile
"@

    $report | Out-File -FilePath $ReportFile -Force
    Log-Message "Report generated successfully" "SUCCESS"

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
    $sleep = [System.Char]::ConvertFromUtf32(0x1F4A4)
    Write-Host "`n$sleep Waiting for next check cycle... (Press Ctrl+C to stop monitoring)" -ForegroundColor DarkGray
    Start-Sleep -Seconds $CheckIntervalSeconds
}

# This line is only reached if $RunContinuously is set to $false
$stop = [System.Char]::ConvertFromUtf32(0x1F6D1)
Write-Host "`n$stop Monitoring stopped." -ForegroundColor Red
exit 0

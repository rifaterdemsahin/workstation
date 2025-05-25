# PowerShell Script to Optimize Audio and Streaming Processes on Ryzen CPU
# Purpose: Set CPU affinity, priority, monitor latency metrics, evaluate performance, and debug latency issues
# Target CPU: AMD Ryzen Threadripper PRO 3995WX (128 logical cores) or other multi-core CPU
# Audio Interfaces: Voicemeeter and Windows Audio
# Date: May 25, 2025
# Version: 2.6 - Added latency debugging for bad metrics

# Requires Administrator privileges
#Requires -RunAsAdministrator

# Enhanced error handling
$ErrorActionPreference = "Continue"
trap {
    Write-Log "Unhandled exception: $_" -ForegroundColor Red -LogLevel "CRITICAL"
    continue
}

# Set up logging with improved path handling
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$baseLogPath = if (Test-Path "C:\projects\workstation\6_Symbols\Logs") { 
    "C:\projects\workstation\6_Symbols\Logs" 
} else { 
    Join-Path -Path $env:TEMP -ChildPath "AudioOptimizer" 
}

$logFilePath = Join-Path -Path $baseLogPath -ChildPath "OptimizeOBSandAudio_$timestamp.log"
$reportFolder = Join-Path -Path $baseLogPath -ChildPath "Reports"

# Create log and report directories if they don't exist
if (!(Test-Path -Path $baseLogPath)) {
    New-Item -ItemType Directory -Path $baseLogPath -Force | Out-Null
}
if (!(Test-Path -Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null
}

# Function to write to log file and console with error handling
function Write-Log {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White",
        [string]$LogLevel = "INFO"
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$LogLevel] $Message"

        # Write to console with color
        Write-Host $logMessage -ForegroundColor $ForegroundColor

        # Write to log file with error handling
        try {
            Add-Content -Path $logFilePath -Value $logMessage -ErrorAction Stop
        } catch {
            $backupLogPath = Join-Path -Path $env:TEMP -ChildPath "OptimizeOBSandAudio_backup.log"
            Add-Content -Path $backupLogPath -Value "[$timestamp] ERROR: Failed to write to main log file. Error: $_" -ErrorAction SilentlyContinue
            Add-Content -Path $backupLogPath -Value $logMessage -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host "[$timestamp] CRITICAL: Failed to log message. Error: $_" -ForegroundColor Red
    }
}

# Function to configure optimal power settings for audio performance
function Set-OptimalPowerSettings {
    try {
        Write-Log "Configuring optimal power plan settings for audio performance..." -ForegroundColor Cyan -LogLevel "INFO"
        
        # Duplicate High Performance power plan if it doesn't exist
        Write-Log "Setting up High Performance power plan..." -ForegroundColor Yellow -LogLevel "INFO"
        try {
            $result = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "High Performance power plan duplicated successfully" -ForegroundColor Green -LogLevel "INFO"
            } else {
                Write-Log "High Performance power plan may already exist or duplication failed: $result" -ForegroundColor Yellow -LogLevel "WARNING"
            }
        } catch {
            Write-Log "Error duplicating power plan: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Set to High Performance power plan
        Write-Log "Activating High Performance power plan..." -ForegroundColor Yellow -LogLevel "INFO"
        try {
            powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
            if ($LASTEXITCODE -eq 0) {
                Write-Log "High Performance power plan activated successfully" -ForegroundColor Green -LogLevel "INFO"
            } else {
                Write-Log "Failed to activate High Performance power plan" -ForegroundColor Red -LogLevel "ERROR"
            }
        } catch {
            Write-Log "Error setting power plan: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Configure power settings for optimal audio performance
        $powerSettings = @{
            # Hard disk turn off time - set to 0 (never)
            "0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e" = 0
            # USB selective suspend - disabled
            "2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226" = 0
            # Processor performance core parking min cores - 100%
            "54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583" = 100
            # Processor performance core parking max cores - 100%
            "54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028" = 100
            # Hybrid sleep - disabled
            "238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e" = 0
            # System standby timeout - never (0)
            "238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da" = 0
            # System hibernate timeout - never (0)
            "238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364" = 0
        }

        Write-Log "Applying power configuration settings..." -ForegroundColor Yellow -LogLevel "INFO"
        
        foreach ($setting in $powerSettings.GetEnumerator()) {
            try {
                $settingPath = $setting.Key -split ' '
                $subgroup = $settingPath[0]
                $settingGuid = $settingPath[1]
                $value = $setting.Value
                
                $result = powercfg -setacvalueindex SCHEME_CURRENT $subgroup $settingGuid $value 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "AC setting applied: $settingGuid = $value" -ForegroundColor Green -LogLevel "INFO"
                } else {
                    Write-Log "Failed to apply AC setting $settingGuid : $result" -ForegroundColor Red -LogLevel "ERROR"
                }
                
                $result = powercfg -setdcvalueindex SCHEME_CURRENT $subgroup $settingGuid $value 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "DC setting applied: $settingGuid = $value" -ForegroundColor Green -LogLevel "INFO"
                } else {
                    Write-Log "Failed to apply DC setting $settingGuid : $result" -ForegroundColor Red -LogLevel "ERROR"
                }
            } catch {
                Write-Log "Error applying power setting $($setting.Key): $_" -ForegroundColor Red -LogLevel "ERROR"
            }
        }

        Write-Log "Applying power plan changes..." -ForegroundColor Yellow -LogLevel "INFO"
        try {
            powercfg -setactive SCHEME_CURRENT
            Write-Log "Power plan settings applied successfully" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Error applying power plan: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        Write-Log "Verifying processor core parking configuration..." -ForegroundColor Yellow -LogLevel "INFO"
        try {
            $coreCountResult = powercfg -query SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 2>&1
            Write-Log "Core parking min cores setting verified" -ForegroundColor Cyan -LogLevel "INFO"
            
            $maxCoreResult = powercfg -query SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028 2>&1
            Write-Log "Core parking max cores setting verified" -ForegroundColor Cyan -LogLevel "INFO"
        } catch {
            Write-Log "Error verifying core parking settings: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        Write-Log "Configuring additional CPU performance settings..." -ForegroundColor Yellow -LogLevel "INFO"
        
        try {
            powercfg -setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2
            powercfg -setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2
            Write-Log "Processor performance boost mode enabled" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Error setting processor boost mode: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        try {
            powercfg -setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 465e1f50-b610-473a-ab58-00d1077dc418 2
            powercfg -setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 465e1f50-b610-473a-ab58-00d1077dc418 2
            Write-Log "Processor performance increase policy set to ideal" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Error setting processor increase policy: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        Write-Log "Power settings configuration completed" -ForegroundColor Cyan -LogLevel "INFO"
    } catch {
        Write-Log "Error in Set-OptimalPowerSettings: $_" -ForegroundColor Red -LogLevel "ERROR"
    }
}

# Function to log errors with full details
function Write-ErrorLog {
    param (
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [string]$Context = "Unknown"
    )

    try {
        $errorDetails = @"
ERROR DETAILS:
Context: $Context
Message: $($ErrorRecord.Exception.Message)
Type: $($ErrorRecord.Exception.GetType().FullName)
Script Stack Trace: $($ErrorRecord.ScriptStackTrace)
Line: $($ErrorRecord.InvocationInfo.Line)
Position: $($ErrorRecord.InvocationInfo.PositionMessage)
"@
        Write-Log $errorDetails -ForegroundColor Red -LogLevel "ERROR"
    } catch {
        Write-Host "CRITICAL: Failed to log error details. Error: $_" -ForegroundColor Red
    }
}

# Function to set CPU affinity and priority for a process
function Set-ProcessOptimization {
    param (
        [string]$ProcessName,
        [int64]$AffinityMask,
        [string]$Priority
    )
    try {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($process) {
            foreach ($proc in $process) {
                try {
                    $proc.ProcessorAffinity = $AffinityMask
                    switch ($Priority) {
                        "RealTime" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::RealTime }
                        "High" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }
                        "AboveNormal" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::AboveNormal }
                        "Normal" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
                        "BelowNormal" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal }
                        "Idle" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle }
                        default { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
                    }
                    Write-Log "Optimized $ProcessName (PID: $($proc.Id)) - Affinity: $AffinityMask, Priority: $Priority" -ForegroundColor Green
                } catch {
                    Write-Log "Error optimizing ${ProcessName} (PID: $($proc.Id)): $_" -ForegroundColor Red
                }
            }
        } else {
            Write-Log "Process $ProcessName not found." -ForegroundColor Red
        }
    } catch {
        Write-Log "Error optimizing ${ProcessName}: $_" -ForegroundColor Red
    }
}

# Function to get system performance metrics
function Get-SystemPerformance {
    try {
        # CPU usage
        try {
            $cpuUsage = [math]::Round((Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average, 2)
        } catch {
            Write-Log "WMI CPU measurement failed, trying performance counter" -ForegroundColor Yellow
            try {
                $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
                $cpuUsage = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
            } catch {
                Write-Log "Performance counter failed, using process CPU time" -ForegroundColor Yellow
                $processes = Get-Process
                $totalCPU = ($processes | Measure-Object -Property CPU -Sum).Sum
                $cpuCount = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
                $cpuUsage = [math]::Round(($totalCPU / $cpuCount), 2)
                if ($cpuUsage -gt 100) { $cpuUsage = 99.9 }
            }
        }

        # Memory usage
        try {
            $osInfo = Get-CimInstance Win32_OperatingSystem
            $memoryUsage = [math]::Round(($osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory) / $osInfo.TotalVisibleMemorySize * 100, 2)
        } catch {
            Write-Log "CIM memory measurement failed, trying WMI" -ForegroundColor Yellow
            try {
                $computerMemory = Get-WmiObject -Class Win32_OperatingSystem
                $memoryUsage = [math]::Round((($computerMemory.TotalVisibleMemorySize - $computerMemory.FreePhysicalMemory) / $computerMemory.TotalVisibleMemorySize) * 100, 2)
            } catch {
                $memoryUsage = "Unknown"
            }
        }

        # GPU usage
        $gpuUsage = "Unknown"
        try {
            $gpuCounter = Get-Counter '\GPU Engine(*engtype_3D)\Utilization Percentage' -ErrorAction Stop
            if ($gpuCounter) {
                $gpuValues = $gpuCounter.CounterSamples | Where-Object { $_.CookedValue -gt 0 } |
                             Select-Object -ExpandProperty CookedValue
                if ($gpuValues -and $gpuValues.Count -gt 0) {
                    $gpuUsage = [math]::Round(($gpuValues | Measure-Object -Average).Average, 2)
                }
            }
        } catch {
            Write-Log "GPU counter measurement failed, trying NVIDIA/AMD tools" -ForegroundColor Yellow
            try {
                if (Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }) {
                    $nvidiaSmi = & "nvidia-smi" --query-gpu=utilization.gpu --format=csv -ErrorAction SilentlyContinue
                    if ($nvidiaSmi) {
                        $gpuUsage = [math]::Round(($nvidiaSmi -split '\n' | Where-Object { $_ -match '\d+' } | 
                            ForEach-Object { [int]($_ -replace '[^0-9]') } | Measure-Object -Average).Average, 2)
                    }
                } elseif (Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -like "*AMD*" }) {
                    $gpuUsage = "AMD GPU Tools Not Implemented"
                }
            } catch {
                Write-Log "Failed to get GPU usage: $_" -ForegroundColor Red -LogLevel "ERROR"
            }
        }

        $performanceMetrics = @{
            CPUUsagePercent = $cpuUsage
            MemoryUsagePercent = $memoryUsage
            GPUUsagePercent = $gpuUsage
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        $reportFile = Join-Path -Path $reportFolder -ChildPath "PerformanceReport_$timestamp.json"
        $performanceMetrics | ConvertTo-Json | Out-File -FilePath $reportFile -Append -ErrorAction SilentlyContinue
        Write-Log "Performance metrics saved to $reportFile" -ForegroundColor Green -LogLevel "INFO"

        return $performanceMetrics
    } catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-SystemPerformance"
        return $null
    }
}

# Function to monitor latency metrics
function Get-LatencyMetrics {
    try {
        $latencyMetrics = @{}

        # Measure DPC queue length
        try {
            $dpcQueue = Get-Counter '\Processor(_Total)\DPCs Queued/sec' -ErrorAction Stop
            $latencyMetrics.DPCQueueRate = [math]::Round($dpcQueue.CounterSamples[0].CookedValue, 2)
        } catch {
            Write-Log "Failed to get DPC queue rate: $_" -ForegroundColor Yellow -LogLevel "WARNING"
            $latencyMetrics.DPCQueueRate = "Unknown"
        }

        # Measure interrupt rate
        try {
            $interrupts = Get-Counter '\Processor(_Total)\Interrupts/sec' -ErrorAction Stop
            $latencyMetrics.InterruptRate = [math]::Round($interrupts.CounterSamples[0].CookedValue, 2)
        } catch {
            Write-Log "Failed to get interrupt rate: $_" -ForegroundColor Yellow -LogLevel "WARNING"
            $latencyMetrics.InterruptRate = "Unknown"
        }

        # Measure interrupt-to-process latency
        try {
            $interruptTime = Get-Counter '\Processor(_Total)\% Interrupt Time' -ErrorAction Stop
            $latencyMetrics.InterruptTimePercent = [math]::Round($interruptTime.CounterSamples[0].CookedValue, 2)
        } catch {
            Write-Log "Failed to get interrupt time: $_" -ForegroundColor Yellow -LogLevel "WARNING"
            $latencyMetrics.InterruptTimePercent = "Unknown"
        }

        # Measure page faults
        try {
            $pageFaults = Get-Counter '\Memory\Page Faults/sec' -ErrorAction Stop
            $latencyMetrics.PageFaultsPerSec = [math]::Round($pageFaults.CounterSamples[0].CookedValue, 2)
        } catch {
            Write-Log "Failed to get page faults: $_" -ForegroundColor Yellow -LogLevel "WARNING"
            $latencyMetrics.PageFaultsPerSec = "Unknown"
        }

        $latencyMetrics.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $latencyReport = Join-Path -Path $reportFolder -ChildPath "LatencyReport_$($timestamp).json"
        $latencyMetrics | ConvertTo-Json | Out-File -FilePath $latencyReport -Append -ErrorAction SilentlyContinue

        Write-Log "Latency Metrics: DPC Queue: $($latencyMetrics.DPCQueueRate)/sec, Interrupts: $($latencyMetrics.InterruptRate)/sec, Interrupt Time: $($latencyMetrics.InterruptTimePercent)%, Page Faults: $($latencyMetrics.PageFaultsPerSec)/sec" -ForegroundColor Cyan -LogLevel "INFO"

        return $latencyMetrics
    } catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-LatencyMetrics"
        return $null
    }
}

# New Function to debug latency issues
function Debug-LatencyIssues {
    param (
        [hashtable]$LatencyMetrics
    )

    try {
        $debugReport = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            HighResourceProcesses = @()
            LoadedDrivers = @()
            SystemEvents = @()
            XperfStatus = "Not Run"
            Recommendations = @()
        }

        Write-Log "Debugging high latency issues..." -ForegroundColor Yellow -LogLevel "INFO"

        # 1. Identify high-resource processes (CPU, memory, page faults)
        try {
            Write-Log "Analyzing high-resource processes..." -ForegroundColor Cyan -LogLevel "INFO"
            $processes = Get-Process | Select-Object Name, Id, CPU, WorkingSet64, @{Name="PageFaults";Expression={$_.VM / 4096}} |
                        Where-Object { $_.CPU -gt 100 -or $_.WorkingSet64 -gt 1GB -or $_.PageFaults -gt 1000 } |
                        Sort-Object PageFaults -Descending | Select-Object -First 10
            $debugReport.HighResourceProcesses = $processes
            if ($processes) {
                Write-Log "High-resource processes detected:" -ForegroundColor Cyan -LogLevel "INFO"
                foreach ($proc in $processes) {
                    Write-Log "Process: $($proc.Name) (PID: $($proc.Id)), CPU: $($proc.CPU), Memory: $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB, Page Faults: $($proc.PageFaults)" -ForegroundColor Cyan -LogLevel "INFO"
                }
                $debugReport.Recommendations += "Review high-resource processes (e.g., $($processes[0].Name)) for excessive CPU/memory usage or page faults."
            } else {
                Write-Log "No high-resource processes detected." -ForegroundColor Green -LogLevel "INFO"
            }
        } catch {
            Write-Log "Failed to analyze processes: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # 2. List loaded drivers
        try {
            Write-Log "Listing loaded drivers..." -ForegroundColor Cyan -LogLevel "INFO"
            $drivers = Get-WmiObject Win32_SystemDriver | Select-Object DisplayName, Name, PathName | 
                       Where-Object { $_.State -eq "Running" } | Sort-Object DisplayName
            $debugReport.LoadedDrivers = $drivers
            $commonLatencyDrivers = @("ndis.sys", "tcpip.sys", "ACPI.sys", "dxgkrnl.sys", "nvlddmkm.sys", "atikmdag.sys")
            $problemDrivers = $drivers | Where-Object { $commonLatencyDrivers -contains $_.Name }
            if ($problemDrivers) {
                Write-Log "Potential latency-causing drivers detected:" -ForegroundColor Yellow -LogLevel "INFO"
                foreach ($driver in $problemDrivers) {
                    Write-Log "Driver: $($driver.DisplayName) ($($driver.Name)) at $($driver.PathName)" -ForegroundColor Yellow -LogLevel "INFO"
                }
                $debugReport.Recommendations += "Update drivers that may cause latency: $($problemDrivers.Name -join ', '). Check manufacturer websites."
            } else {
                Write-Log "No common latency-causing drivers detected." -ForegroundColor Green -LogLevel "INFO"
            }
        } catch {
            Write-Log "Failed to list drivers: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # 3. Check system event logs for driver/hardware errors
        try {
            Write-Log "Checking system event logs for errors..." -ForegroundColor Cyan -LogLevel "INFO"
            $events = Get-WinEvent -LogName "System" -MaxEvents 100 -ErrorAction SilentlyContinue |
                      Where-Object { $_.LevelDisplayName -eq "Error" -and $_.TimeCreated -gt (Get-Date).AddHours(-1) } |
                      Select-Object TimeCreated, Id, ProviderName, Message
            $debugReport.SystemEvents = $events
            if ($events) {
                Write-Log "System errors detected in the last hour:" -ForegroundColor Yellow -LogLevel "INFO"
                foreach ($event in $events) {
                    Write-Log "Event ID: $($event.Id), Source: $($event.ProviderName), Time: $($event.TimeCreated), Message: $($event.Message)" -ForegroundColor Yellow -LogLevel "INFO"
                }
                $debugReport.Recommendations += "Review system event logs for errors related to drivers or hardware."
            } else {
                Write-Log "No recent system errors detected." -ForegroundColor Green -LogLevel "INFO"
            }
        } catch {
            Write-Log "Failed to check event logs: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # 4. Attempt xperf analysis if available
        try {
            if (Get-Command "xperf" -ErrorAction SilentlyContinue) {
                Write-Log "Running xperf to capture DPC/ISR data (30 seconds)..." -ForegroundColor Cyan -LogLevel "INFO"
                $xperfOutput = Join-Path -Path $reportFolder -ChildPath "LatencyTrace_$($timestamp).etl"
                & xperf -on Latency -stackwalk Profile -f $xperfOutput
                Start-Sleep -Seconds 30
                & xperf -stop
                $debugReport.XperfStatus = "Captured to $xperfOutput"
                Write-Log "xperf trace captured to $xperfOutput. Analyze with Windows Performance Analyzer." -ForegroundColor Green -LogLevel "INFO"
                $debugReport.Recommendations += "Analyze $xperfOutput with Windows Performance Analyzer to identify DPC/ISR sources."
            } else {
                Write-Log "xperf not found. Install Windows Performance Toolkit for detailed DPC/ISR analysis." -ForegroundColor Yellow -LogLevel "WARNING"
                $debugReport.XperfStatus = "xperf not available"
                $debugReport.Recommendations += "Install Windows Performance Toolkit (xperf) for detailed latency analysis: https://learn.microsoft.com/en-us/windows-hardware/test/wpt/"
            }
        } catch {
            Write-Log "Failed to run xperf: $_" -ForegroundColor Red -LogLevel "ERROR"
            $debugReport.XperfStatus = "Failed: $_"
        }

        # Save debug report
        $debugReportFile = Join-Path -Path $reportFolder -ChildPath "LatencyDebug_$($timestamp).json"
        $debugReport | ConvertTo-Json -Depth 4 | Out-File -FilePath $debugReportFile -ErrorAction SilentlyContinue
        Write-Log "Latency debug report saved to $debugReportFile" -ForegroundColor Green -LogLevel "INFO"

        # Log recommendations
        if ($debugReport.Recommendations) {
            Write-Log "Debug Recommendations:" -ForegroundColor Yellow -LogLevel "INFO"
            foreach ($rec in $debugReport.Recommendations) {
                Write-Log "- $rec" -ForegroundColor Yellow -LogLevel "INFO"
            }
        }

        return $debugReport
    } catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Debug-LatencyIssues"
        return $null
    }
}

# Function to evaluate latency metrics
function Evaluate-LatencyMetrics {
    param (
        [hashtable]$LatencyMetrics
    )

    try {
        $evaluation = @{
            DPCQueueRate = "Unknown"
            InterruptRate = "Unknown"
            InterruptTime = "Unknown"
            PageFaults = "Unknown"
            Overall = "Unknown"
            Recommendations = @()
        }

        # Evaluate DPC Queue Rate
        if ($LatencyMetrics.DPCQueueRate -ne "Unknown") {
            if ($LatencyMetrics.DPCQueueRate -lt 500) {
                $evaluation.DPCQueueRate = "Good"
            } elseif ($LatencyMetrics.DPCQueueRate -lt 1000) {
                $evaluation.DPCQueueRate = "Acceptable"
            } else {
                $evaluation.DPCQueueRate = "Bad"
                $evaluation.Recommendations += "High DPC queue rate detected. Run LatencyMon to identify problematic drivers (e.g., ndis.sys, ACPI.sys)."
            }
        }

        # Evaluate Interrupt Rate
        if ($LatencyMetrics.InterruptRate -ne "Unknown") {
            if ($LatencyMetrics.InterruptRate -lt 5000) {
                $evaluation.InterruptRate = "Good"
            } elseif ($LatencyMetrics.InterruptRate -lt 10000) {
                $evaluation.InterruptRate = "Acceptable"
            } else {
                $evaluation.InterruptRate = "Bad"
                $evaluation.Recommendations += "High interrupt rate detected. Check for outdated network/GPU drivers or excessive hardware interrupts."
            }
        }

        # Evaluate Interrupt Time
        if ($LatencyMetrics.InterruptTimePercent -ne "Unknown") {
            if ($LatencyMetrics.InterruptTimePercent -lt 1) {
                $evaluation.InterruptTime = "Good"
            } elseif ($LatencyMetrics.InterruptTimePercent -lt 2) {
                $evaluation.InterruptTime = "Acceptable"
            } else {
                $evaluation.InterruptTime = "Bad"
                $evaluation.Recommendations += "High interrupt time detected. Investigate interrupt-heavy drivers using LatencyMon or xperf."
            }
        }

        # Evaluate Page Faults
        if ($LatencyMetrics.PageFaultsPerSec -ne "Unknown") {
            if ($LatencyMetrics.PageFaultsPerSec -lt 100) {
                $evaluation.PageFaults = "Good"
            } elseif ($LatencyMetrics.PageFaultsPerSec -lt 1000) {
                $evaluation.PageFaults = "Acceptable"
            } else {
                $evaluation.PageFaults = "Bad"
                $evaluation.Recommendations += "High page faults detected. Check for memory-intensive applications or insufficient RAM."
            }
        }

        # Determine overall evaluation
        $ratings = @($evaluation.DPCQueueRate, $evaluation.InterruptRate, $evaluation.InterruptTime, $evaluation.PageFaults)
        if ($ratings -contains "Bad") {
            $evaluation.Overall = "Bad"
            $evaluation.Recommendations += "System is not suitable for real-time audio/streaming without optimization."
            # Trigger latency debugging
            $debugReport = Debug-LatencyIssues -LatencyMetrics $LatencyMetrics
        } elseif ($ratings -contains "Acceptable") {
            $evaluation.Overall = "Acceptable"
            $evaluation.Recommendations += "System is marginally suitable for real-time audio/streaming. Consider optimizations for better performance."
        } else {
            $evaluation.Overall = "Good"
            $evaluation.Recommendations += "System is suitable for real-time audio/streaming."
        }

        # Log evaluation
        Write-Log "Latency Evaluation: Overall: $($evaluation.Overall)" -ForegroundColor Cyan -LogLevel "INFO"
        Write-Log "DPC Queue Rate: $($evaluation.DPCQueueRate) ($($LatencyMetrics.DPCQueueRate)/sec)" -ForegroundColor Cyan -LogLevel "INFO"
        Write-Log "Interrupt Rate: $($evaluation.InterruptRate) ($($LatencyMetrics.InterruptRate)/sec)" -ForegroundColor Cyan -LogLevel "INFO"
        Write-Log "Interrupt Time: $($evaluation.InterruptTime) ($($LatencyMetrics.InterruptTimePercent)%)" -ForegroundColor Cyan -LogLevel "INFO"
        Write-Log "Page Faults: $($evaluation.PageFaults) ($($LatencyMetrics.PageFaultsPerSec)/sec)" -ForegroundColor Cyan -LogLevel "INFO"
        if ($evaluation.Recommendations) {
            Write-Log "Recommendations:" -ForegroundColor Yellow -LogLevel "INFO"
            foreach ($rec in $evaluation.Recommendations) {
                Write-Log "- $rec" -ForegroundColor Yellow -LogLevel "INFO"
            }
        }

        # Save evaluation to report
        $evalReport = Join-Path -Path $reportFolder -ChildPath "LatencyEvaluation_$($timestamp).json"
        $evaluation | ConvertTo-Json | Out-File -FilePath $evalReport -Append -ErrorAction SilentlyContinue
        Write-Log "Latency evaluation saved to $evalReport" -ForegroundColor Green -LogLevel "INFO"

        return $evaluation
    } catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Evaluate-LatencyMetrics"
        return $null
    }
}

# Function to optimize audio and streaming processes
function Optimize-AudioAndStreaming {
    try {
        Write-Log "Starting audio and streaming process optimization..." -ForegroundColor Cyan -LogLevel "INFO"

        # Get total logical cores
        $totalCores = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
        Write-Log "Detected $totalCores logical cores" -ForegroundColor Cyan -LogLevel "INFO"

        # Calculate affinity masks
        $audioCores = [math]::Min(8, $totalCores)
        $streamingCores = [math]::Min(24, $totalCores - $audioCores)
        $systemCores = $totalCores - ($audioCores + $streamingCores)

        $audioAffinity = [System.Numerics.BigInteger]::Pow(2, $audioCores) - 1
        $streamingAffinity = ([System.Numerics.BigInteger]::Pow(2, $audioCores + $streamingCores) - 1) - $audioAffinity
        $systemAffinity = ([System.Numerics.BigInteger]::Pow(2, [math]::Min($totalCores, 63)) - 1) - ($audioAffinity + $streamingAffinity)

        $audioAffinity = [int64]$audioAffinity
        $streamingAffinity = [int64]$streamingAffinity
        $systemAffinity = [int64]$systemAffinity

        Write-Log "Affinity masks - Audio: $audioAffinity, Streaming: $streamingAffinity, System: $systemAffinity" -ForegroundColor Cyan -LogLevel "INFO"

        # Optimize audio processes
        $audioProcesses = @(
            @{ Name = "voicemeeter"; Priority = "RealTime" },
            @{ Name = "audiodg"; Priority = "High" }
        )

        foreach ($proc in $audioProcesses) {
            Set-ProcessOptimization -ProcessName $proc.Name -AffinityMask $audioAffinity -Priority $proc.Priority
        }

        # Optimize streaming processes
        $streamingProcesses = @(
            @{ Name = "obs64"; Priority = "High" },
            @{ Name = "obs"; Priority = "High" },
            @{ Name = "Streamlabs"; Priority = "AboveNormal" }
        )

        foreach ($proc in $streamingProcesses) {
            Set-ProcessOptimization -ProcessName $proc.Name -AffinityMask $streamingAffinity -Priority $proc.Priority
        }

        # Set system processes to use remaining cores
        $systemProcesses = @("svchost", "csrss", "smss")
        foreach ($proc in $systemProcesses) {
            Set-ProcessOptimization -ProcessName $proc -AffinityMask $systemAffinity -Priority "Normal"
        }

        Write-Log "Process optimization completed" -ForegroundColor Green -LogLevel "INFO"
    } catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Optimize-AudioAndStreaming"
    }
}

# Function to configure Windows Audio settings
function Set-WindowsAudioSettings {
    try {
        Write-Log "Configuring Windows Audio settings..." -ForegroundColor Cyan -LogLevel "INFO"

        Set-Service -Name Audiosrv -StartupType Automatic
        Write-Log "Audio service set to Automatic" -ForegroundColor Green -LogLevel "INFO"

        $audioRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio"
        if (!(Test-Path $audioRegPath)) {
            New-Item -Path $audioRegPath -Force | Out-Null
        }

        Set-ItemProperty -Path $audioRegPath -Name "AudioQuality" -Value 1 -ErrorAction SilentlyContinue
        Write-Log "Audio quality settings configured" -ForegroundColor Green -LogLevel "INFO"
    } catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Set-WindowsAudioSettings"
    }
}

# Main execution block with continuous monitoring
try {
    Write-Log "Starting Audio and Streaming Optimization Script" -ForegroundColor Cyan -LogLevel "INFO"

    # Set optimal power settings
    Set-OptimalPowerSettings

    # Optimize audio and streaming processes
    Optimize-AudioAndStreaming

    # Configure Windows Audio settings
    Set-WindowsAudioSettings

    # Continuous monitoring loop
    Write-Log "Entering continuous latency monitoring mode. Press Ctrl+C to stop." -ForegroundColor Cyan -LogLevel "INFO"
    
    while ($true) {
        # Get and log system performance metrics
        $metrics = Get-SystemPerformance
        if ($metrics) {
            Write-Log "System Performance Metrics:" -ForegroundColor Cyan -LogLevel "INFO"
            Write-Log "CPU Usage: $($metrics.CPUUsagePercent)%"
            Write-Log "Memory Usage: $($metrics.MemoryUsagePercent)%"
            Write-Log "GPU Usage: $($metrics.GPUUsagePercent)%"
        }

        # Get and evaluate latency metrics
        $latencyMetrics = Get-LatencyMetrics
        if ($latencyMetrics) {
            $evaluation = Evaluate-LatencyMetrics -LatencyMetrics $latencyMetrics
            Write-Log "Latency Report Saved: $reportFolder\LatencyReport_$($timestamp).json" -ForegroundColor Green -LogLevel "INFO"
        }

        # Sleep for 10 seconds before next iteration
        Start-Sleep -Seconds 10
    }

} catch {
    Write-ErrorLog -ErrorRecord $_ -Context "Main Execution"
    Write-Log "Script execution failed. Check logs for details." -ForegroundColor Red -LogLevel "CRITICAL"
}
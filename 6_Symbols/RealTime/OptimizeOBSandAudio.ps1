# PowerShell Script to Optimize Audio and Streaming Processes on Ryzen CPU
# Purpose: Set CPU affinity and priority to reduce audio cracking and improve streaming performance
# Target CPU: AMD Ryzen Threadripper PRO 3995WX (128 logical cores) or other multi-core CPU
# Audio Interfaces: Voicemeeter and Windows Audio
# Date: May 10, 2025
# Version: 2.2 - Enhanced with break button, final reporting, and timestamped report files

# Requires Administrator privileges
#Requires -RunAsAdministrator

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFilePath = "C:\projects\workstation\6_Symbols\Logs\OptimizeOBSandAudio_$timestamp.log"
$logFolder = Split-Path -Path $logFilePath -Parent
$reportFolder = Join-Path -Path $logFolder -ChildPath "Reports"

# Create log and report directories if they don't exist
if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}
if (!(Test-Path -Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null
}

# Function to write to log file and console
function Write-Log {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"

    # Write to console with color
    Write-Host $logMessage -ForegroundColor $ForegroundColor

    # Write to log file
    Add-Content -Path $logFilePath -Value $logMessage
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
                # Set CPU affinity
                $proc.ProcessorAffinity = $AffinityMask
                # Set priority
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
            }
        } else {
            Write-Log "Process $ProcessName not found." -ForegroundColor Red
        }
    } catch {
        Write-Log "Error optimizing ${ProcessName}: $_" -ForegroundColor Red
    }
}

# Function to get system performance metrics with alternative methods
function Get-SystemPerformance {
    try {
        # Method 1: Try using WMI to get CPU usage (more reliable for many-core systems)
        try {
            $cpuUsage = [math]::Round((Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average, 2)
        } catch {
            Write-Log "WMI CPU measurement failed, trying alternative method" -ForegroundColor Yellow

            # Method 2: Try performance counters if WMI fails
            try {
                $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
                $cpuUsage = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
            } catch {
                Write-Log "Performance counter for CPU failed. Using Process CPU time as fallback." -ForegroundColor Yellow

                # Method 3: Fallback to process CPU time calculation
                $processes = Get-Process
                $totalCPU = ($processes | Measure-Object -Property CPU -Sum).Sum
                $cpuCount = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
                $cpuUsage = [math]::Round(($totalCPU / $cpuCount), 2)
                if ($cpuUsage -gt 100) { $cpuUsage = 99.9 } # Cap at 100%
            }
        }

        # Get memory usage - try different methods
        try {
            $osInfo = Get-CimInstance Win32_OperatingSystem
            $memoryUsage = [math]::Round(($osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory) / $osInfo.TotalVisibleMemorySize * 100, 2)
        } catch {
            Write-Log "CIM memory measurement failed, trying alternative method" -ForegroundColor Yellow

            # Fallback method for memory
            try {
                $computerMemory = Get-WmiObject -Class Win32_OperatingSystem
                $memoryUsage = [math]::Round((($computerMemory.TotalVisibleMemorySize - $computerMemory.FreePhysicalMemory) / $computerMemory.TotalVisibleMemorySize) * 100, 2)
            } catch {
                # Last resort
                $memoryUsage = "Unknown"
            }
        }

        # Get GPU usage with multiple fallback mechanisms
        $gpuUsage = "Unknown"

        # Method 1: Try GPU performance counters
        try {
            $gpuCounter = Get-Counter '\GPU Engine(*engtype_3D)\Utilization Percentage' -ErrorAction Stop
            if ($gpuCounter) {
                $gpuValues = $gpuCounter.CounterSamples | Where-Object { $_.CookedValue -gt 0 } |
                             Select-Object -ExpandProperty CookedValue
                if ($gpuValues -and $gpuValues.Count -gt 0) {
                    $gpuUsage = [math]::Round(($gpuValues | Measure-Object -Maximum).Maximum, 2)
                }
            }
        } catch {
            # Method 2: Try WMI for GPU information
            try {
                # Get GPU load via WMI (works on some systems)
                $gpuInfo = Get-WmiObject -Namespace "root\CIMV2" -Class "Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine" -ErrorAction Stop |
                           Where-Object { $_.Name -like "*3D*" }

                if ($gpuInfo) {
                    $gpuUsage = [math]::Round(($gpuInfo | Measure-Object -Property UtilizationPercentage -Average).Average, 2)
                } else {
                    # Get basic GPU name info at least
                    $gpuName = (Get-WmiObject -Class Win32_VideoController).Name
                    $gpuUsage = "N/A (GPU: $gpuName)"
                }
            } catch {
                # Final fallback
                $gpuUsage = "N/A (Counters unavailable)"
            }
        }

        # Calculate system responsiveness estimate (very basic)
        # Lower scores are better - based on CPU availability for UI thread
        $responsivenessScore = 0

        if ($cpuUsage -gt 90) {
            $responsiveness = "Poor"
            $responsivenessScore = 3
        } elseif ($cpuUsage -gt 70) {
            $responsiveness = "Fair"
            $responsivenessScore = 2
        } elseif ($cpuUsage -gt 40) {
            $responsiveness = "Good"
            $responsivenessScore = 1
        } else {
            $responsiveness = "Excellent"
            $responsivenessScore = 0
        }

        # Return performance data
        return @{
            CPUUsage = $cpuUsage
            MemoryUsage = $memoryUsage
            GPUUsage = $gpuUsage
            Responsiveness = $responsiveness
            ResponsivenessScore = $responsivenessScore
            Timestamp = Get-Date
        }
    } catch {
        Write-Log "Error getting system performance: $_" -ForegroundColor Red

        # Return a minimal object with error state
        return @{
            CPUUsage = "Error"
            MemoryUsage = "Error"
            GPUUsage = "Error"
            Responsiveness = "Unknown"
            ResponsivenessScore = 9 # High error score
            Timestamp = Get-Date
            ErrorMessage = $_
        }
    }
}

# Function to generate and save a final performance report
function Save-PerformanceReport {
    param (
        [array]$PerformanceHistory,
        [datetime]$StartTime,
        [string]$ReportFolder,
        [switch]$Final = $false
    )

    try {
        # Create a timestamp for the report filename
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFilePath = Join-Path -Path $ReportFolder -ChildPath "PerformanceReport_$timestamp.txt"

        # Create report content
        $reportContent = New-Object System.Text.StringBuilder

        # Add header
        [void]$reportContent.AppendLine("======================================================")
        [void]$reportContent.AppendLine("   SYSTEM OPTIMIZATION PERFORMANCE REPORT")
        [void]$reportContent.AppendLine("======================================================")
        [void]$reportContent.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        [void]$reportContent.AppendLine("Session Duration: $(((Get-Date) - $StartTime).ToString('hh\:mm\:ss'))")
        [void]$reportContent.AppendLine("Report Type: $(if ($Final) { 'Final Report' } else { 'Break Button Report' })")
        [void]$reportContent.AppendLine("======================================================")
        [void]$reportContent.AppendLine("")

        # Add system information
        [void]$reportContent.AppendLine("SYSTEM INFORMATION:")
        [void]$reportContent.AppendLine("------------------")

        # Get CPU info
        $cpuInfo = Get-WmiObject -Class Win32_Processor
        [void]$reportContent.AppendLine("CPU: $($cpuInfo.Name)")
        [void]$reportContent.AppendLine("Logical Processors: $($cpuInfo.NumberOfLogicalProcessors)")

        # Try to get memory info
        try {
            $memoryInfo = Get-WmiObject -Class Win32_ComputerSystem
            $totalMemoryGB = [math]::Round($memoryInfo.TotalPhysicalMemory / 1GB, 2)
            [void]$reportContent.AppendLine("Total Memory: $totalMemoryGB GB")
        } catch {
            [void]$reportContent.AppendLine("Total Memory: Unable to retrieve")
        }

        # Try to get GPU info
        try {
            $gpuInfo = Get-WmiObject -Class Win32_VideoController
            [void]$reportContent.AppendLine("GPU(s):")
            foreach ($gpu in $gpuInfo) {
                [void]$reportContent.AppendLine("   - $($gpu.Name)")
            }
        } catch {
            [void]$reportContent.AppendLine("GPU: Unable to retrieve")
        }

        [void]$reportContent.AppendLine("")

        # Performance metrics summary
        if ($PerformanceHistory.Count -gt 0) {
            # Calculate performance metrics
            $validCpuMeasurements = $PerformanceHistory | Where-Object { $_.CPUUsage -is [double] -or $_.CPUUsage -is [int] }
            $validMemoryMeasurements = $PerformanceHistory | Where-Object { $_.MemoryUsage -is [double] -or $_.MemoryUsage -is [int] }
            $validGpuMeasurements = $PerformanceHistory | Where-Object { $_.GPUUsage -is [double] -or $_.GPUUsage -is [int] }

            $avgCPU = if ($validCpuMeasurements.Count -gt 0) { ($validCpuMeasurements | Measure-Object -Property CPUUsage -Average).Average } else { "N/A" }
            $maxCPU = if ($validCpuMeasurements.Count -gt 0) { ($validCpuMeasurements | Measure-Object -Property CPUUsage -Maximum).Maximum } else { "N/A" }
            $minCPU = if ($validCpuMeasurements.Count -gt 0) { ($validCpuMeasurements | Measure-Object -Property CPUUsage -Minimum).Minimum } else { "N/A" }

            $avgMem = if ($validMemoryMeasurements.Count -gt 0) { ($validMemoryMeasurements | Measure-Object -Property MemoryUsage -Average).Average } else { "N/A" }
            $maxMem = if ($validMemoryMeasurements.Count -gt 0) { ($validMemoryMeasurements | Measure-Object -Property MemoryUsage -Maximum).Maximum } else { "N/A" }

            $avgGPU = if ($validGpuMeasurements.Count -gt 0) { ($validGpuMeasurements | Measure-Object -Property GPUUsage -Average).Average } else { "N/A" }

            $avgResponsiveness = ($PerformanceHistory | Measure-Object -Property ResponsivenessScore -Average).Average

            [void]$reportContent.AppendLine("PERFORMANCE SUMMARY:")
            [void]$reportContent.AppendLine("--------------------")
            [void]$reportContent.AppendLine("Total Measurements: $($PerformanceHistory.Count)")
            [void]$reportContent.AppendLine("")

            # Format numeric values with proper percentage signs
            $avgCPUDisplay = if ($avgCPU -is [double] -or $avgCPU -is [int]) { "$([math]::Round($avgCPU, 2))%" } else { $avgCPU }
            $maxCPUDisplay = if ($maxCPU -is [double] -or $maxCPU -is [int]) { "$([math]::Round($maxCPU, 2))%" } else { $maxCPU }
            $minCPUDisplay = if ($minCPU -is [double] -or $minCPU -is [int]) { "$([math]::Round($minCPU, 2))%" } else { $minCPU }
            $avgMemDisplay = if ($avgMem -is [double] -or $avgMem -is [int]) { "$([math]::Round($avgMem, 2))%" } else { $avgMem }
            $maxMemDisplay = if ($maxMem -is [double] -or $maxMem -is [int]) { "$([math]::Round($maxMem, 2))%" } else { $maxMem }
            $avgGPUDisplay = if ($avgGPU -is [double] -or $avgGPU -is [int]) { "$([math]::Round($avgGPU, 2))%" } else { $avgGPU }

            [void]$reportContent.AppendLine("CPU Performance:")
            [void]$reportContent.AppendLine("   Average CPU Usage: $avgCPUDisplay")
            [void]$reportContent.AppendLine("   Maximum CPU Usage: $maxCPUDisplay")
            [void]$reportContent.AppendLine("   Minimum CPU Usage: $minCPUDisplay")
            [void]$reportContent.AppendLine("")

            [void]$reportContent.AppendLine("Memory Performance:")
            [void]$reportContent.AppendLine("   Average Memory Usage: $avgMemDisplay")
            [void]$reportContent.AppendLine("   Maximum Memory Usage: $maxMemDisplay")
            [void]$reportContent.AppendLine("")

            [void]$reportContent.AppendLine("GPU Performance:")
            [void]$reportContent.AppendLine("   Average GPU Usage: $avgGPUDisplay")
            [void]$reportContent.AppendLine("")

            [void]$reportContent.AppendLine("System Responsiveness:")
            [void]$reportContent.AppendLine("   Average Responsiveness Score: $([math]::Round($avgResponsiveness, 2)) (Lower is better)")

            # Get current state
            $currentPerf = $PerformanceHistory | Select-Object -Last 1
            if ($currentPerf) {
                [void]$reportContent.AppendLine("")
                [void]$reportContent.AppendLine("CURRENT SYSTEM STATE:")
                [void]$reportContent.AppendLine("--------------------")

                $cpuDisplay = if ($currentPerf.CPUUsage -is [double] -or $currentPerf.CPUUsage -is [int]) { "$($currentPerf.CPUUsage)%" } else { $currentPerf.CPUUsage }
                $memDisplay = if ($currentPerf.MemoryUsage -is [double] -or $currentPerf.MemoryUsage -is [int]) { "$($currentPerf.MemoryUsage)%" } else { $currentPerf.MemoryUsage }
                $gpuDisplay = if ($currentPerf.GPUUsage -is [double] -or $currentPerf.GPUUsage -is [int]) { "$($currentPerf.GPUUsage)%" } else { $currentPerf.GPUUsage }

                [void]$reportContent.AppendLine("Current CPU Usage: $cpuDisplay")
                [void]$reportContent.AppendLine("Current Memory Usage: $memDisplay")
                [void]$reportContent.AppendLine("Current GPU Usage: $gpuDisplay")
                [void]$reportContent.AppendLine("Current System Responsiveness: $($currentPerf.Responsiveness)")
            }

            # Add process information
            [void]$reportContent.AppendLine("")
            [void]$reportContent.AppendLine("CURRENT PROCESS INFORMATION:")
            [void]$reportContent.AppendLine("--------------------------")
            [void]$reportContent.AppendLine("Total Process Count: $((Get-Process).Count)")
            [void]$reportContent.AppendLine("Total Thread Count: $((Get-Process | Measure-Object -Property Threads -Sum).Sum)")

            # Get info about key processes
            $targetProcesses = @("obs64", "audiodg", "voicemeeter8", "voicemeeter", "audiorepeater", "VBCable_ControlPanel", "Discord", "chrome")
            [void]$reportContent.AppendLine("")
            [void]$reportContent.AppendLine("KEY MONITORED PROCESSES:")
            [void]$reportContent.AppendLine("----------------------")

            foreach ($procName in $targetProcesses) {
                $processes = Get-Process -Name $procName -ErrorAction SilentlyContinue
                if ($processes) {
                    foreach ($proc in $processes) {
                        [void]$reportContent.AppendLine("$($proc.ProcessName) (PID: $($proc.Id))")
                        [void]$reportContent.AppendLine("   CPU Usage: $([math]::Round($proc.CPU, 2)) seconds")
                        [void]$reportContent.AppendLine("   Memory: $([math]::Round($proc.WorkingSet / 1MB, 2)) MB")
                        [void]$reportContent.AppendLine("   Threads: $($proc.Threads.Count)")
                        [void]$reportContent.AppendLine("   Priority: $($proc.PriorityClass)")
                        [void]$reportContent.AppendLine("")
                    }
                }
            }
        } else {
            [void]$reportContent.AppendLine("No performance history available.")
        }

        # Save report to file
        $reportContent.ToString() | Out-File -FilePath $reportFilePath -Force

        # Return the report path and content
        return @{
            Path = $reportFilePath
            Content = $reportContent.ToString()
        }
    } catch {
        Write-Log "Error generating performance report: $_" -ForegroundColor Red
        return $null
    } finally {
        Write-Log "Optimization loop ended." -ForegroundColor Cyan

        # Generate final performance report
        Write-Log "Generating performance report..." -ForegroundColor Cyan
        $report = Save-PerformanceReport -PerformanceHistory $perfHistory -StartTime $startTime -ReportFolder $reportFolder -Final

        if ($report) {
            Write-Log "Report saved to: $($report.Path)" -ForegroundColor Green

            # Display summary from report
            Write-Log "===== PERFORMANCE SUMMARY =====" -ForegroundColor Yellow
            Write-Log "Session Duration: $(((Get-Date) - $startTime).ToString('hh\:mm\:ss'))" -ForegroundColor Yellow

            # Calculate summary stats
            $validCpuMeasurements = $perfHistory | Where-Object { $_.CPUUsage -is [double] -or $_.CPUUsage -is [int] }
            if ($validCpuMeasurements.Count -gt 0) {
                $avgCPU = ($validCpuMeasurements | Measure-Object -Property CPUUsage -Average).Average
                $maxCPU = ($validCpuMeasurements | Measure-Object -Property CPUUsage -Maximum).Maximum
                Write-Log "Average CPU Usage: $([math]::Round($avgCPU, 2))%" -ForegroundColor Yellow
                Write-Log "Maximum CPU Usage: $([math]::Round($maxCPU, 2))%" -ForegroundColor Yellow
            }

            # Try to restore original priority levels
            Write-Log "Attempting to restore original priority levels..." -ForegroundColor Cyan
            $originalPriority = Get-Process -Name "obs64" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PriorityClass
            if ($originalPriority) {
                Write-Log "Original priority: $originalPriority" -ForegroundColor Yellow

                # Restore original priority for all processes
                foreach ($procName in $targetProcesses) {
                    Set-ProcessOptimization -ProcessName $procName -AffinityMask $backgroundAffinity -Priority $backgroundPriority
                }
            } else {
                Write-Log "Failed to restore original priority levels." -ForegroundColor Red
            }
        } else {
            Write-Log "Failed to generate performance report." -ForegroundColor Red
        }
    }
}

# Function to display a form with a break button
function Show-BreakButton {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Audio and Streaming Optimization"
    $form.Size = New-Object System.Drawing.Size(400, 200)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(350, 40)
    $label.Text = "Optimization is running in the background.`nPress the button below to stop and generate a report."
    $form.Controls.Add($label)

    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(100, 80)
    $button.Size = New-Object System.Drawing.Size(200, 50)
    $button.Text = "Break and Show Report"
    $button.BackColor = [System.Drawing.Color]::FromArgb(192, 0, 0)
    $button.ForeColor = [System.Drawing.Color]::White
    $button.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $button.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($button)

    # Create a status label that will update
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 140)
    $statusLabel.Size = New-Object System.Drawing.Size(350, 20)
    $statusLabel.Text = "Running for: 00:00:00"
    $form.Controls.Add($statusLabel)

    # Create a timer to update the status
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000 # Update every second
    $startTime = Get-Date
    $timer.Add_Tick({
        $runTime = (Get-Date) - $startTime
        $statusLabel.Text = "Running for: " + $runTime.ToString("hh\:mm\:ss")
    })
    $timer.Start()

    # Show the form as a dialog (blocking until closed)
    $result = $form.ShowDialog()

    # Clean up
    $timer.Stop()
    $timer.Dispose()
    $form.Dispose()

    return $result -eq [System.Windows.Forms.DialogResult]::OK
}

# Start the log file with system information
Write-Log "=== Starting Audio and Streaming Optimization Script ===" -ForegroundColor Cyan
Write-Log "Log File: $logFilePath" -ForegroundColor Cyan
Write-Log "Press Ctrl+C to exit the script at any time" -ForegroundColor Yellow

# Set up Ctrl+C handler
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Log "Script interrupted by user (Ctrl+C)" -ForegroundColor Yellow
    Write-Log "Generating final report before exit..." -ForegroundColor Yellow
    if ($report) {
        Write-Log "Report saved to: $($report.Path)" -ForegroundColor Green
    }
    Write-Log "=== Script terminated by user ===" -ForegroundColor Red
}

# Get system information
$cpuInfo = Get-WmiObject -Class Win32_Processor
Write-Log "CPU: $($cpuInfo.Name)" -ForegroundColor Cyan
Write-Log "Number of logical processors: $($cpuInfo.NumberOfLogicalProcessors)" -ForegroundColor Cyan

# Try to get GPU information
try {
    $gpuInfo = Get-WmiObject -Class Win32_VideoController
    foreach ($gpu in $gpuInfo) {
        Write-Log "GPU: $($gpu.Name) - $($gpu.VideoModeDescription)" -ForegroundColor Cyan
    }
} catch {
    Write-Log "Could not retrieve GPU information: $_" -ForegroundColor Red
}

# List all running processes before optimization for debugging
Write-Log "Listing target processes before optimization..." -ForegroundColor Cyan
$targetProcesses = @("obs64", "audiodg", "voicemeeter8", "voicemeeter", "audiorepeater", "VBCable_ControlPanel", "Discord", "chrome")
foreach ($procName in $targetProcesses) {
    try {
        $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
        if ($process) {
            foreach ($p in $process) {
                Write-Log "Found: $procName (PID: $($p.Id))" -ForegroundColor Green
            }
        } else {
            Write-Log "Not Found: $procName" -ForegroundColor Red
        }
    } catch {
        Write-Log "Error occurred while checking $procName" -ForegroundColor Red
    }
}
Write-Log "Process listing complete. Starting optimizations..." -ForegroundColor Cyan

# Log initial system performance
$initialPerf = Get-SystemPerformance
if ($initialPerf) {
    Write-Log "Initial System State:" -ForegroundColor Yellow

    # Check if values are numeric or error strings
    $cpuDisplay = if ($initialPerf.CPUUsage -is [double] -or $initialPerf.CPUUsage -is [int]) { "$($initialPerf.CPUUsage)%" } else { $initialPerf.CPUUsage }
    $memDisplay = if ($initialPerf.MemoryUsage -is [double] -or $initialPerf.MemoryUsage -is [int]) { "$($initialPerf.MemoryUsage)%" } else { $initialPerf.MemoryUsage }
    $gpuDisplay = if ($initialPerf.GPUUsage -is [double] -or $initialPerf.GPUUsage -is [int]) { "$($initialPerf.GPUUsage)%" } else { $initialPerf.GPUUsage }

    Write-Log "   CPU Usage: $cpuDisplay" -ForegroundColor Yellow
    Write-Log "   Memory Usage: $memDisplay" -ForegroundColor Yellow
    Write-Log "   GPU Usage: $gpuDisplay" -ForegroundColor Yellow
    Write-Log "   System Responsiveness: $($initialPerf.Responsiveness)" -ForegroundColor Yellow

    # Additional hardware info
    Write-Log "   Number of Chrome instances: $((Get-Process chrome -ErrorAction SilentlyContinue).Count)" -ForegroundColor Yellow
    Write-Log "   Number of Firefox instances: $((Get-Process firefox -ErrorAction SilentlyContinue).Count)" -ForegroundColor Yellow
}

# Automatically detect number of logical processors
$cpuCount = $cpuInfo.NumberOfLogicalProcessors

# Calculate appropriate affinity masks based on system configuration
function Calculate-OptimalAffinityMasks {
    param (
        [int]$TotalProcessors
    )

    # For large systems like yours with 128 threads, we need to be careful with affinity mask calculations
    # PowerShell's Int64 can't handle extremely large bitmasks for 128+ threads

    if ($TotalProcessors -gt 64) {
        # For very large systems (>64 cores), use smaller segments
        # OBS: Cores 0-3
        $script:obsAffinity = 0xF

        # Windows Audio (audiodg): Cores 4-7
        $script:audioAffinity = 0xF0

        # Voicemeeter: Cores 8-11
        $script:voicemeeterAffinity = 0xF00

        # Game (optional): Cores 12-15
        $script:gameAffinity = 0xF000

        # Background apps: Cores 16-23 (avoid using all cores to prevent overflow)
        $script:backgroundAffinity = 0xFF0000
    }
    elseif ($TotalProcessors -lt 16) {
        # Small system (4-8 cores)
        $script:obsAffinity = 0x3       # Cores 0-1
        $script:audioAffinity = 0xC     # Cores 2-3
        $script:voicemeeterAffinity = 0x30 # Cores 4-5
        $script:gameAffinity = 0xF0     # Cores 4-7
        $script:backgroundAffinity = 0xF  # Cores 0-3
    }
    else {
        # Mid-size system (16-64 cores)
        $script:obsAffinity = 0xF       # Cores 0-3
        $script:audioAffinity = 0xF0     # Cores 4-7
        $script:voicemeeterAffinity = 0xF00 # Cores 8-11
        $script:gameAffinity = 0xF000    # Cores 12-15
        $script:backgroundAffinity = 0xFF0000 # Cores 16-23
    }

    Write-Log "Affinity masks calculated for $TotalProcessors logical processors" -ForegroundColor Yellow
}

# Calculate affinity masks based on system configuration
Calculate-OptimalAffinityMasks -TotalProcessors $cpuCount

# Set priority levels
$obsPriority = "High"
$audioPriority = "High"
$voicemeeterPriority = "High"
$gamePriority = "Normal"
$backgroundPriority = "BelowNormal"

# Initialize tracking for newly detected processes
$processedBefore = New-Object System.Collections.Generic.HashSet[string]
foreach ($procName in $targetProcesses) {
    $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($process) {
        [void]$processedBefore.Add($procName)
    }
}

# Optimize processes
Write-Log "Applying initial optimizations..." -ForegroundColor Cyan

# Audio processes - critical for preventing audio crackling
Set-ProcessOptimization -ProcessName "audiodg" -AffinityMask $audioAffinity -Priority $audioPriority
Set-ProcessOptimization -ProcessName "voicemeeter" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
Set-ProcessOptimization -ProcessName "audiorepeater" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority

# OBS and streaming
Set-ProcessOptimization -ProcessName "obs64" -AffinityMask $obsAffinity -Priority $obsPriority

# Optional game process (if running)
# Add your game's process name here
# Set-ProcessOptimization -ProcessName "YourGameProcess" -AffinityMask $gameAffinity -Priority $gamePriority

# Background applications
Set-ProcessOptimization -ProcessName "Discord" -AffinityMask $backgroundAffinity -Priority $backgroundPriority
Set-ProcessOptimization -ProcessName "chrome" -AffinityMask $backgroundAffinity -Priority $backgroundPriority

# Start performance tracking
$startTime = Get-Date
$perfHistory = @()
$perfHistory += $initialPerf

# Start the UI with the break button in a separate thread
$breakButtonPressed = $false
$uiThread = New-Object System.Threading.Thread([System.Threading.ThreadStart]{
    $breakButtonPressed = Show-BreakButton
})
$uiThread.SetApartmentState([System.Threading.ApartmentState]::STA)
$uiThread.Start()

# Start the monitoring loop
Write-Log "Starting continuous optimization and monitoring loop..." -ForegroundColor Cyan
$iteration = 0

try {
    while (-not $breakButtonPressed) {
        $iteration++

        # Check for new instances of target processes every 5 iterations
        if ($iteration % 5 -eq 0) {
            foreach ($procName in $targetProcesses) {
                $process = Get-Process -Name $procName -ErrorAction SilentlyContinue

                # If process exists and we haven't processed it before in this session
                if ($process -and -not $processedBefore.Contains($procName)) {
                    Write-Log "Detected new process: $procName" -ForegroundColor Yellow

                    # Apply appropriate optimization based on process type
                    switch ($procName) {
                        "audiodg" {
                            Set-ProcessOptimization -ProcessName $procName -AffinityMask $audioAffinity -Priority $audioPriority
                        }
                        "voicemeeter8" {
                            Set-ProcessOptimization -ProcessName $procName -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
                        }
                        "voicemeeter" {
                            Set-ProcessOptimization -ProcessName $procName -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
                        }
                        "audiorepeater" {
                            Set-ProcessOptimization -ProcessName $procName -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
                        }
                        "VBCable_ControlPanel" {
                            Set-ProcessOptimization -ProcessName $procName -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
                        }
                        "obs64" {
                            Set-ProcessOptimization -ProcessName $procName -AffinityMask $obsAffinity -Priority $obsPriority
                        }
                        default {
                            Set-ProcessOptimization -ProcessName $procName -AffinityMask $backgroundAffinity -Priority $backgroundPriority
                        }
                    }

                    # Mark as processed
                    [void]$processedBefore.Add($procName)
                }
            }
        }

        # Get current performance metrics
        $currentPerf = Get-SystemPerformance
        if ($currentPerf) {
            # Add to history
            $perfHistory += $currentPerf

            # Display current performance every 10 iterations
            if ($iteration % 10 -eq 0) {
                $cpuDisplay = if ($currentPerf.CPUUsage -is [double] -or $currentPerf.CPUUsage -is [int]) { "$($currentPerf.CPUUsage)%" } else { $currentPerf.CPUUsage }
                $memDisplay = if ($currentPerf.MemoryUsage -is [double] -or $currentPerf.MemoryUsage -is [int]) { "$($currentPerf.MemoryUsage)%" } else { $currentPerf.MemoryUsage }
                $gpuDisplay = if ($currentPerf.GPUUsage -is [double] -or $currentPerf.GPUUsage -is [int]) { "$($currentPerf.GPUUsage)%" } else { $currentPerf.GPUUsage }

                Write-Log "Current Performance:" -ForegroundColor Green
                Write-Log "   CPU: $cpuDisplay | Memory: $memDisplay | GPU: $gpuDisplay | Responsiveness: $($currentPerf.Responsiveness)" -ForegroundColor Green
                Write-Log "Running for: $((Get-Date) - $startTime)" -ForegroundColor Green
            }
        }

        # Check every second if the UI thread signals to stop
        Start-Sleep -Seconds 1
        $breakButtonPressed = $uiThread.Join(0)
    }
} catch {
    Write-Log "Error in monitoring loop: $_" -ForegroundColor Red
} finally {
    Write-Log "Optimization loop ended." -ForegroundColor Cyan

    # Generate final performance report
    Write-Log "Generating performance report..." -ForegroundColor Cyan
    $report = Save-PerformanceReport -PerformanceHistory $perfHistory -StartTime $startTime -ReportFolder $reportFolder -Final

    if ($report) {
        Write-Log "Report saved to: $($report.Path)" -ForegroundColor Green

        # Display summary from report
        Write-Log "===== PERFORMANCE SUMMARY =====" -ForegroundColor Yellow
        Write-Log "Session Duration: $(((Get-Date) - $startTime).ToString('hh\:mm\:ss'))" -ForegroundColor Yellow

        # Calculate summary stats
        $validCpuMeasurements = $perfHistory | Where-Object { $_.CPUUsage -is [double] -or $_.CPUUsage -is [int] }
        if ($validCpuMeasurements.Count -gt 0) {
            $avgCPU = ($validCpuMeasurements | Measure-Object -Property CPUUsage -Average).Average
            $maxCPU = ($validCpuMeasurements | Measure-Object -Property CPUUsage -Maximum).Maximum
            Write-Log "Average CPU Usage: $([math]::Round($avgCPU, 2))%" -ForegroundColor Yellow
            Write-Log "Maximum CPU Usage: $([math]::Round($maxCPU, 2))%" -ForegroundColor Yellow
        }

        # Try to restore original priority levels
        Write-Log "Attempting to restore original priority levels..." -ForegroundColor Cyan
        $originalPriority = Get-Process -Name "obs64" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PriorityClass
        if ($originalPriority) {
            Write-Log "Original priority: $originalPriority" -ForegroundColor Yellow

            # Restore original priority for all processes
            foreach ($procName in $targetProcesses) {
                Set-ProcessOptimization -ProcessName $procName -AffinityMask $backgroundAffinity -Priority $backgroundPriority
            }
        } else {
            Write-Log "Failed to restore original priority levels." -ForegroundColor Red
        }
    } else {
        Write-Log "Failed to generate performance report." -ForegroundColor Red
    }
}


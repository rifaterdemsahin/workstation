# PowerShell Script to Optimize Audio and Streaming Processes on Ryzen CPU
# Purpose: Set CPU affinity and priority to reduce audio cracking and improve streaming performance
# Target CPU: AMD Ryzen Threadripper PRO 3995WX (128 logical cores) or other multi-core CPU
# Audio Interfaces: Voicemeeter and Windows Audio
# Date: May 10, 2025
# Version: 2.1 - Enhanced with robust performance monitoring and logging

# Requires Administrator privileges
#Requires -RunAsAdministrator

# Set up logging
$logFilePath = "C:\projects\workstation\6_Symbols\Logs\OptimizeOBSandAudio.log"
$logFolder = Split-Path -Path $logFilePath -Parent

# Create log directory if it doesn't exist
if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
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

# Start the log file with system information
Write-Log "=== Starting Audio and Streaming Optimization Script ===" -ForegroundColor Cyan
Write-Log "Log File: $logFilePath" -ForegroundColor Cyan

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
    
    Write-Log "  CPU Usage: $cpuDisplay" -ForegroundColor Yellow
    Write-Log "  Memory Usage: $memDisplay" -ForegroundColor Yellow
    Write-Log "  GPU Usage: $gpuDisplay" -ForegroundColor Yellow
    Write-Log "  System Responsiveness: $($initialPerf.Responsiveness)" -ForegroundColor Yellow
    
    # Additional hardware info
    Write-Log "  Number of Chrome instances: $((Get-Process chrome -ErrorAction SilentlyContinue).Count)" -ForegroundColor Yellow
    Write-Log "  Number of Firefox instances: $((Get-Process firefox -ErrorAction SilentlyContinue).Count)" -ForegroundColor Yellow
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
        $script:obsAffinity = 0x3        # Cores 0-1
        $script:audioAffinity = 0xC      # Cores 2-3
        $script:voicemeeterAffinity = 0x30 # Cores 4-5
        $script:gameAffinity = 0xF0      # Cores 4-7
        $script:backgroundAffinity = 0xF  # Cores 0-3
    }
    else {
        # Mid-size system (16-64 cores)
        $script:obsAffinity = 0xF        # Cores 0-3
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
Set-ProcessOptimization -ProcessName "voicemeeter8" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
Set-ProcessOptimization -ProcessName "voicemeeter" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
Set-ProcessOptimization -ProcessName "audiorepeater" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
Set-ProcessOptimization -ProcessName "VBCable_ControlPanel" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority

# Streaming/Recording
Set-ProcessOptimization -ProcessName "obs64" -AffinityMask $obsAffinity -Priority $obsPriority

# Define and optimize background apps
$backgroundApps = @("Discord", "chrome", "msedge", "firefox", "brave")
foreach ($app in $backgroundApps) {
    Set-ProcessOptimization -ProcessName $app -AffinityMask $backgroundAffinity -Priority $backgroundPriority
}

# Check if game process name was provided and optimize if it exists
$gameName = $null
if ($args.Count -gt 0) {
    $gameName = $args[0]
    Set-ProcessOptimization -ProcessName $gameName -AffinityMask $gameAffinity -Priority $gamePriority
}

# Store performance metrics history
$performanceHistory = @()

# Monitor and reapply every 30 seconds
Write-Log "Initial optimization complete! Monitoring and reapplying every 30 seconds..." -ForegroundColor Green
Write-Log "Press Ctrl+C to stop." -ForegroundColor Yellow

try {
    $intervalSeconds = 30
    $iteration = 0
    $startTime = Get-Date
    
    while ($true) {
        Start-Sleep -Seconds $intervalSeconds
        $iteration++
        
        # Get performance metrics
        $performance = Get-SystemPerformance
        if ($performance) {
            # Store metrics history (keep last 10)
            $performanceHistory += $performance
            if ($performanceHistory.Count -gt 10) {
                $performanceHistory = $performanceHistory | Select-Object -Last 10
            }
            
            # Calculate average responsiveness
            $avgResponsiveness = ($performanceHistory | Measure-Object -Property ResponsivenessScore -Average).Average
            $runTime = (Get-Date) - $startTime
            $runTimeFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $runTime.Hours, $runTime.Minutes, $runTime.Seconds
            
            # Log performance data
            Write-Log "Iteration $iteration - Run Time: $runTimeFormatted" -ForegroundColor Yellow
            
            # Check if values are numeric or error strings
            $cpuDisplay = if ($performance.CPUUsage -is [double] -or $performance.CPUUsage -is [int]) { "$($performance.CPUUsage)%" } else { $performance.CPUUsage }
            $memDisplay = if ($performance.MemoryUsage -is [double] -or $performance.MemoryUsage -is [int]) { "$($performance.MemoryUsage)%" } else { $performance.MemoryUsage }
            $gpuDisplay = if ($performance.GPUUsage -is [double] -or $performance.GPUUsage -is [int]) { "$($performance.GPUUsage)%" } else { $performance.GPUUsage }
            
            Write-Log "  CPU Usage: $cpuDisplay" -ForegroundColor Cyan
            Write-Log "  Memory Usage: $memDisplay" -ForegroundColor Cyan
            Write-Log "  GPU Usage: $gpuDisplay" -ForegroundColor Cyan
            Write-Log "  Current System Responsiveness: $($performance.Responsiveness)" -ForegroundColor Cyan
            Write-Log "  Average Responsiveness Score: $([math]::Round($avgResponsiveness, 2)) (Lower is better)" -ForegroundColor Cyan
            
            # Additional system metrics for better diagnostics
            $processCount = (Get-Process).Count
            $chromeProcesses = (Get-Process chrome -ErrorAction SilentlyContinue).Count
            $threadCount = (Get-Process | Measure-Object -Property Threads -Sum).Sum
            
            Write-Log "  Total Processes: $processCount" -ForegroundColor Cyan
            Write-Log "  Chrome Processes: $chromeProcesses" -ForegroundColor Cyan  
            Write-Log "  Total Threads: $threadCount" -ForegroundColor Cyan
        }
        
        Write-Log "Reapplying optimizations... (Iteration $iteration)" -ForegroundColor Yellow
        
        # Audio processes - highest priority
        Set-ProcessOptimization -ProcessName "audiodg" -AffinityMask $audioAffinity -Priority $audioPriority
        Set-ProcessOptimization -ProcessName "voicemeeter8" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
        Set-ProcessOptimization -ProcessName "voicemeeter" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
        Set-ProcessOptimization -ProcessName "audiorepeater" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
        Set-ProcessOptimization -ProcessName "VBCable_ControlPanel" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
        
        # Streaming/Recording
        Set-ProcessOptimization -ProcessName "obs64" -AffinityMask $obsAffinity -Priority $obsPriority
        
        # Background apps
        foreach ($app in $backgroundApps) {
            Set-ProcessOptimization -ProcessName $app -AffinityMask $backgroundAffinity -Priority $backgroundPriority
        }
        
        # Game process if specified
        if ($gameName) {
            Set-ProcessOptimization -ProcessName $gameName -AffinityMask $gameAffinity -Priority $gamePriority
        }
        
        # Check for newly launched target processes every 5 iterations
        if ($iteration % 5 -eq 0) {
            Write-Log "Checking for newly launched processes..." -ForegroundColor Cyan
            foreach ($procName in $targetProcesses) {
                $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
                if ($process -and -not $processedBefore.Contains($procName)) {
                    Write-Log "Found new process: $procName" -ForegroundColor Green
                    [void]$processedBefore.Add($procName)
                    
                    # Apply appropriate optimization based on process type
                    if ($procName -eq "obs64") {
                        Set-ProcessOptimization -ProcessName $procName -AffinityMask $obsAffinity -Priority $obsPriority
                    } elseif ($procName -in @("audiodg")) {
                        Set-ProcessOptimization -ProcessName $procName -AffinityMask $audioAffinity -Priority $audioPriority
                    } elseif ($procName -in @("voicemeeter8", "voicemeeter", "audiorepeater", "VBCable_ControlPanel")) {
                        Set-ProcessOptimization -ProcessName $procName -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
                    } elseif ($procName -in $backgroundApps) {
                        Set-ProcessOptimization -ProcessName $procName -AffinityMask $backgroundAffinity -Priority $backgroundPriority
                    }
                }
            }
        }
    }
} catch {
    Write-Log "Script stopped: $_" -ForegroundColor Red
} finally {
    # Get final performance metrics
    $finalPerf = Get-SystemPerformance
    if ($finalPerf) {
        Write-Log "Final System State:" -ForegroundColor Yellow
        
        # Check if values are numeric or error strings
        $cpuDisplay = if ($finalPerf.CPUUsage -is [double] -or $finalPerf.CPUUsage -is [int]) { "$($finalPerf.CPUUsage)%" } else { $finalPerf.CPUUsage }
        $memDisplay = if ($finalPerf.MemoryUsage -is [double] -or $finalPerf.MemoryUsage -is [int]) { "$($finalPerf.MemoryUsage)%" } else { $finalPerf.MemoryUsage }
        $gpuDisplay = if ($finalPerf.GPUUsage -is [double] -or $finalPerf.GPUUsage -is [int]) { "$($finalPerf.GPUUsage)%" } else { $finalPerf.GPUUsage }
        
        Write-Log "  CPU Usage: $cpuDisplay" -ForegroundColor Yellow
        Write-Log "  Memory Usage: $memDisplay" -ForegroundColor Yellow
        Write-Log "  GPU Usage: $gpuDisplay" -ForegroundColor Yellow
        Write-Log "  System Responsiveness: $($finalPerf.Responsiveness)" -ForegroundColor Yellow
        Write-Log "  Process Count: $((Get-Process).Count)" -ForegroundColor Yellow
        Write-Log "  Thread Count: $((Get-Process | Measure-Object -Property Threads -Sum).Sum)" -ForegroundColor Yellow
    }
    
    # Calculate overall performance statistics if we have history
    if ($performanceHistory.Count -gt 0) {
        $avgCPU = ($performanceHistory | Measure-Object -Property CPUUsage -Average).Average
        $avgResponsiveness = ($performanceHistory | Measure-Object -Property ResponsivenessScore -Average).Average
        
        Write-Log "Performance Summary:" -ForegroundColor Green
        Write-Log "  Average CPU Usage: $([math]::Round($avgCPU, 2))%" -ForegroundColor Green
        Write-Log "  Average Responsiveness Score: $([math]::Round($avgResponsiveness, 2)) (Lower is better)" -ForegroundColor Green
        Write-Log "  Session Duration: $(((Get-Date) - $startTime).ToString("hh\:mm\:ss"))" -ForegroundColor Green
    }
    
    Write-Log "Optimization monitoring ended." -ForegroundColor Cyan
    Write-Log "Log file saved at: $logFilePath" -ForegroundColor Cyan
}


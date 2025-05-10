# PowerShell Script to Optimize Audio and Streaming Processes on Ryzen CPU
# Purpose: Set CPU affinity and priority to reduce audio cracking and improve streaming performance
# Target CPU: AMD Ryzen Threadripper or other multi-core CPU
# Audio Interfaces: Voicemeeter and Windows Audio
# Date: May 10, 2025

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

# Function to get system performance metrics
function Get-SystemPerformance {
    try {
        # Get CPU usage
        $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        $cpuUsage = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
        
        # Get memory usage
        $osInfo = Get-CimInstance Win32_OperatingSystem
        $memoryUsage = [math]::Round(($osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory) / $osInfo.TotalVisibleMemorySize * 100, 2)
        
        # Get GPU usage if available (requires admin rights)
        $gpuUsage = "N/A"
        try {
            $gpuCounter = Get-Counter '\GPU Engine(*engtype_3D)\Utilization Percentage' -ErrorAction SilentlyContinue
            if ($gpuCounter) {
                # This might capture multiple 3D engines, so we'll take the highest value
                $gpuValues = $gpuCounter.CounterSamples | Where-Object { $_.CookedValue -gt 0 } | 
                             Select-Object -ExpandProperty CookedValue
                if ($gpuValues -and $gpuValues.Count -gt 0) {
                    $gpuUsage = [math]::Round(($gpuValues | Measure-Object -Maximum).Maximum, 2)
                }
            }
        } catch {
            $gpuUsage = "Error: $_"
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
        return $null
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
    Write-Log "  CPU Usage: $($initialPerf.CPUUsage)%" -ForegroundColor Yellow
    Write-Log "  Memory Usage: $($initialPerf.MemoryUsage)%" -ForegroundColor Yellow
    Write-Log "  GPU Usage: $($initialPerf.GPUUsage)%" -ForegroundColor Yellow
    Write-Log "  System Responsiveness: $($initialPerf.Responsiveness)" -ForegroundColor Yellow
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
            Write-Log "  CPU Usage: $($performance.CPUUsage)%" -ForegroundColor Cyan
            Write-Log "  Memory Usage: $($performance.MemoryUsage)%" -ForegroundColor Cyan
            Write-Log "  GPU Usage: $($performance.GPUUsage)%" -ForegroundColor Cyan
            Write-Log "  Current System Responsiveness: $($performance.Responsiveness)" -ForegroundColor Cyan
            Write-Log "  Average Responsiveness Score: $([math]::Round($avgResponsiveness, 2)) (Lower is better)" -ForegroundColor Cyan
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
        Write-Log "  CPU Usage: $($finalPerf.CPUUsage)%" -ForegroundColor Yellow
        Write-Log "  Memory Usage: $($finalPerf.MemoryUsage)%" -ForegroundColor Yellow
        Write-Log "  GPU Usage: $($finalPerf.GPUUsage)%" -ForegroundColor Yellow
        Write-Log "  System Responsiveness: $($finalPerf.Responsiveness)" -ForegroundColor Yellow
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
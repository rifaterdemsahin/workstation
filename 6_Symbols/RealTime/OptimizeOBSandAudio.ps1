# PowerShell Script to Optimize Audio and Streaming Processes on Ryzen CPU
# Purpose: Set CPU affinity and priority to reduce audio cracking and improve streaming performance
# Target CPU: AMD Ryzen Threadripper or other multi-core CPU
# Audio Interfaces: Voicemeeter and Windows Audio
# Date: May 09, 2025

# Requires Administrator privileges
#Requires -RunAsAdministrator

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
                Write-Host "Optimized $ProcessName (PID: $($proc.Id)) - Affinity: $AffinityMask, Priority: $Priority" -ForegroundColor Green
            }
        } else {
            Write-Host "Process $ProcessName not found." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error optimizing ${ProcessName}: $_" -ForegroundColor Red
    }
}

# Get system information
$cpuInfo = Get-WmiObject -Class Win32_Processor
Write-Host "CPU: $($cpuInfo.Name)" -ForegroundColor Cyan
Write-Host "Number of logical processors: $($cpuInfo.NumberOfLogicalProcessors)" -ForegroundColor Cyan

# List all running processes before optimization for debugging
Write-Host "Listing target processes before optimization..." -ForegroundColor Cyan
$targetProcesses = @("obs64", "audiodg", "voicemeeter8", "voicemeeter", "audiorepeater", "VBCable_ControlPanel", "Discord", "chrome")
foreach ($procName in $targetProcesses) {
    try {
        $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
        if ($process) {
            foreach ($p in $process) {
                Write-Host "Found: $procName (PID: $($p.Id))" -ForegroundColor Green
            }
        } else {
            Write-Host "Not Found: $procName" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error occurred while checking $procName" -ForegroundColor Red
    }
}
Write-Host "Process listing complete. Starting optimizations..." -ForegroundColor Cyan

# Automatically detect number of logical processors
$cpuCount = $cpuInfo.NumberOfLogicalProcessors

# Calculate appropriate affinity masks based on system configuration
function Calculate-OptimalAffinityMasks {
    param (
        [int]$TotalProcessors
    )
    
    # For systems with fewer cores, use a different allocation strategy
    if ($TotalProcessors -lt 16) {
        # Small system (4-8 cores)
        $script:obsAffinity = 0x3        # Cores 0-1
        $script:audioAffinity = 0xC      # Cores 2-3
        $script:voicemeeterAffinity = 0x30 # Cores 4-5
        $script:gameAffinity = 0xF0      # Cores 4-7
        $script:backgroundAffinity = 0xF  # Cores 0-3
    }
    elseif ($TotalProcessors -lt 32) {
        # Mid-size system (16-24 cores)
        $script:obsAffinity = 0xF        # Cores 0-3
        $script:audioAffinity = 0xF0     # Cores 4-7
        $script:voicemeeterAffinity = 0xF00 # Cores 8-11
        $script:gameAffinity = 0xF000    # Cores 12-15
        $script:backgroundAffinity = 0xFF0000 # Cores 16-23
    }
    else {
        # Large system (32+ cores, like Threadripper)
        # OBS: CCX1, cores 0-3
        $script:obsAffinity = 0xF  
        
        # Windows Audio (audiodg): CCX2, cores 4-7
        $script:audioAffinity = 0xF0
        
        # Voicemeeter: CCX3, cores 8-11
        $script:voicemeeterAffinity = 0xF00
        
        # Game (optional): CCX4, cores 12-15
        $script:gameAffinity = 0xF000
        
        # Background apps (e.g., Discord, Chrome): remaining cores
        $script:backgroundAffinity = [Math]::Pow(2, $TotalProcessors) - 1 - 0xFFFF
    }
    
    Write-Host "Affinity masks calculated for $TotalProcessors logical processors" -ForegroundColor Yellow
}

# Calculate affinity masks based on system configuration
Calculate-OptimalAffinityMasks -TotalProcessors $cpuCount

# Set priority levels
$obsPriority = "High"
$audioPriority = "High"
$voicemeeterPriority = "High"
$gamePriority = "Normal"
$backgroundPriority = "BelowNormal"

# Optimize processes
Write-Host "Applying initial optimizations..." -ForegroundColor Cyan

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

# Monitor and reapply every 30 seconds
Write-Host "Initial optimization complete! Monitoring and reapplying every 30 seconds..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow

try {
    $intervalSeconds = 30
    $iteration = 0
    while ($true) {
        Start-Sleep -Seconds $intervalSeconds
        $iteration++
        Write-Host "Reapplying optimizations... (Iteration $iteration)" -ForegroundColor Yellow
        
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
            Write-Host "Checking for newly launched processes..." -ForegroundColor Cyan
            foreach ($procName in $targetProcesses) {
                $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
                if ($process -and -not $processedBefore.Contains($procName)) {
                    Write-Host "Found new process: $procName" -ForegroundColor Green
                }
            }
        }
    }
} catch {
    Write-Host "Script stopped: $_" -ForegroundColor Red
} finally {
    Write-Host "Optimization monitoring ended." -ForegroundColor Cyan
}
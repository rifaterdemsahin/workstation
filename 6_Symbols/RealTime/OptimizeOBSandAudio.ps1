# PowerShell Script to Optimize OBS, Audio, Voicemeeter, VB-Audio Cable A, and Focusrite Scarlett 2i2 on Ryzen 128-Thread CPU
# Purpose: Set CPU affinity and priority to reduce audio cracking and improve multi-scene OBS performance with Scarlett 2i2
# Target CPU: AMD Ryzen Threadripper (e.g., 3990X, 64 cores/128 threads)
# Audio Interface: Focusrite Scarlett 2i2 (3rd or 4th Gen)
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
                    "High" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }
                    "Normal" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
                    "BelowNormal" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal }
                    "Idle" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle }
                    default { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
                }
                Write-Host "Optimized $ProcessName (PID: $($proc.Id)) - Affinity: $AffinityMask, Priority: $Priority"
            }
        } else {
            Write-Host "Process $ProcessName not found."
        }
    } catch {
        Write-Host "Error optimizing $ProcessName: $_"
    }
}

# Core assignments for Ryzen Threadripper (128 threads, 64 physical cores)
# Assuming 8 CCXs, 8 cores per CCX (16 threads per CCX). Adjust AffinityMask based on your CPU's CCX layout.
# AffinityMask uses a bitmask where each bit represents a core (0-based index).
# Physical cores only (avoid SMT): Select even-numbered cores (e.g., 0,2,4,6 for CCX1).
# CCX layout: CCX1 (cores 0-7, threads 0-15), CCX2 (cores 8-15, threads 16-31), etc.

# OBS: CCX2, physical cores 8,10,12,14 (threads 16,18,20,22)
$obsAffinity = 0x5500  # Bitmask for cores 8,10,12,14 (0101 0101 0000 0000 binary, decimal 21760)
$obsPriority = "High"

# Windows Audio (audiodg.exe): CCX3, physical cores 16,18,20,22 (threads 32,34,36,38)
$audioAffinity = 0x550000  # Bitmask for cores 16,18,20,22 (0101 0101 0000 0000 0000 0000 binary, decimal 5570560)
$audioPriority = "High"

# Voicemeeter (voicemeeter8.exe or similar): CCX4, physical cores 24,26,28,30 (threads 48,50,52,54)
$voicemeeterAffinity = 0x55000000  # Bitmask for cores 24,26,28,30 (0101 0101 0000 0000 0000 0000 0000 0000 binary, decimal 1426063360)
$voicemeeterPriority = "High"

# VB-Audio Cable A (VBCable_A.exe or similar): CCX5, physical cores 32,34,36,38 (threads 64,66,68,70)
$cableAffinity = 0x5500000000  # Bitmask for cores 32,34,36,38 (0101 0101 0000 0000 0000 0000 0000 0000 0000 0000 binary, decimal 364071344128)
$cablePriority = "High"

# Focusrite Scarlett 2i2 (Focusrite USB Audio or similar): CCX6, physical cores 40,42,44,46 (threads 80,82,84,86)
$scarlettAffinity = 0x550000000000  # Bitmask for cores 40,42,44,46 (0101 0101 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 binary, decimal 93057365057536)
$scarlettPriority = "High"

# Optional: Game (e.g., EscapeFromTarkov.exe): CCX1, physical cores 0,2,4,6 (threads 0,2,4,6)
$gameAffinity = 0x55  # Bitmask for cores 0,2,4,6 (0101 0101 binary, decimal 85)
$gamePriority = "Normal"

# Optional: Background apps (e.g., Discord, Chrome): CCX7, cores 48-55 (threads 96-111)
$backgroundAffinity = 0xFF000000000000  # Bitmask for cores 48-55 (1111 1111 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 binary, decimal 280375465082880)
$backgroundPriority = "BelowNormal"

# Optimize OBS
Set-ProcessOptimization -ProcessName "obs64" -AffinityMask $obsAffinity -Priority $obsPriority

# Optimize Windows Audio
Set-ProcessOptimization -ProcessName "audiodg" -AffinityMask $audioAffinity -Priority $audioPriority

# Optimize Voicemeeter (verify process name in Task Manager, e.g., voicemeeter8, voicemeeterpro)
Set-ProcessOptimization -ProcessName "voicemeeter8" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority

# Optimize VB-Audio Cable A (verify process name in Task Manager, e.g., VBCable_A)
Set-ProcessOptimization -ProcessName "VBCable_A" -AffinityMask $cableAffinity -Priority $cablePriority

# Optimize Focusrite Scarlett 2i2 (process name may be FocusriteUSBAudio or similar; check Task Manager)
Set-ProcessOptimization -ProcessName "FocusriteUSBAudio" -AffinityMask $scarlettAffinity -Priority $scarlettPriority

# Optional: Optimize a specific game (uncomment and replace "GameName" with actual process name, e.g., "EscapeFromTarkov")
# Set-ProcessOptimization -ProcessName "GameName" -AffinityMask $gameAffinity -Priority $gamePriority

# Optional: Optimize background apps (e.g., Discord, Chrome)
$backgroundApps = @("Discord", "chrome")
foreach ($app in $backgroundApps) {
    Set-ProcessOptimization -ProcessName $app -AffinityMask $backgroundAffinity -Priority $backgroundPriority
}

# Monitor and reapply settings every 30 seconds for persistence
$runContinuously = $true
if ($runContinuously) {
    while ($true) {
        Write-Host "Reapplying optimizations..."
        Set-ProcessOptimization -ProcessName "obs64" -AffinityMask $obsAffinity -Priority $obsPriority
        Set-ProcessOptimization -ProcessName "audiodg" -AffinityMask $audioAffinity -Priority $audioPriority
        Set-ProcessOptimization -ProcessName "voicemeeter8" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
        Set-ProcessOptimization -ProcessName "VBCable_A" -AffinityMask $cableAffinity -Priority $cablePriority
        Set-ProcessOptimization -ProcessName "FocusriteUSBAudio" -AffinityMask $scarlettAffinity -Priority $scarlettPriority
        # Add game or background apps here if needed
        Start-Sleep -Seconds 30
    }
}

Write-Host "Optimization complete. Press Ctrl+C to stop continuous monitoring."
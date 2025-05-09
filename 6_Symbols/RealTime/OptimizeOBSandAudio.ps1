# PowerShell Script to Optimize OBS, Audio, Voicemeeter, VB-Audio Cable A, and Focusrite Scarlett 2i2 on Ryzen 128-Thread CPU
# Purpose: Set CPU affinity and priority to reduce audio cracking and improve multi-scene OBS performance with Scarlett 2i2
# Target CPU: AMD Ryzen Threadripper (e.g., 3990X, 64 cores/128 threads)
# Audio Interface: Focusrite Scarlett 2i2 (3rd or 4th Gen)
# Date: May 09, 2025
# Added: Colorful process listing before optimization for debugging 🟢🔴

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
                $proc.ProcessorAffinity = $AffinityMask
                switch ($Priority) {
                    "High" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }
                    "Normal" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
                    "BelowNormal" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal }
                    "Idle" { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle }
                    default { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
                }
                Write-Host "Optimized $ProcessName (PID: $($proc.Id)) - Affinity: $AffinityMask, Priority: $Priority" -ForegroundColor Green ✅
            }
        } else {
            Write-Host "Process $ProcessName not found." -ForegroundColor Red 🔴
        }
    } catch {
        Write-Host "Error optimizing ${ProcessName}: $_" -ForegroundColor Red ⚠️
    }
}

# List all running processes before optimization for debugging
Write-Host "Listing running processes before optimization... 🔍" -ForegroundColor Cyan
$targetProcesses = @("obs64", "audiodg", "voicemeeter8", "VBCable_A", "FocusriteUSBAudio", "Discord", "chrome")
Write-Host "Checking target processes:" -ForegroundColor Cyan
foreach ($procName in $targetProcesses) {
    $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($process) {
        foreach ($p in $process) {
            Write-Host "Found: $procName (PID: $($p.Id))" -ForegroundColor Green ✅
        }
    } else {
        Write-Host "Not Found: $procName" -ForegroundColor Red 🔴
    }
}
Write-Host "Process listing complete. Starting optimizations... 🚀" -ForegroundColor Cyan

# Core assignments for Ryzen Threadripper (128 threads, 64 physical cores)
# 8 CCXs, 8 cores per CCX. Physical cores only (avoid SMT).
# OBS: CCX2, cores 8,10,12,14
$obsAffinity = 0x5500  # Decimal 21760
$obsPriority = "High"

# Windows Audio (audiodg): CCX3, cores 16,18,20,22
$audioAffinity = 0x550000  # Decimal 5570560
$audioPriority = "High"

# Voicemeeter: CCX4, cores 24,26,28,30
$voicemeeterAffinity = 0x55000000  # Decimal 1426063360
$voicemeeterPriority = "High"

# VB-Audio Cable A: CCX5, cores 32,34,36,38
$cableAffinity = 0x5500000000  # Decimal 364071344128
$cablePriority = "High"

# Focusrite Scarlett 2i2: CCX6, cores 40,42,44,46
$scarlettAffinity = 0x550000000000  # Decimal 93057365057536
$scarlettPriority = "High"

# Game (optional): CCX1, cores 0,2,4,6
$gameAffinity = 0x55  # Decimal 85
$gamePriority = "Normal"

# Background apps (e.g., Discord, Chrome): CCX7, cores 48-55
$backgroundAffinity = 0xFF000000000000  # Decimal 280375465082880
$backgroundPriority = "BelowNormal"

# Optimize processes
Set-ProcessOptimization -ProcessName "obs64" -AffinityMask $obsAffinity -Priority $obsPriority
Set-ProcessOptimization -ProcessName "audiodg" -AffinityMask $audioAffinity -Priority $audioPriority
Set-ProcessOptimization -ProcessName "voicemeeter8" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
Set-ProcessOptimization -ProcessName "VBCable_A" -AffinityMask $cableAffinity -Priority $cablePriority
Set-ProcessOptimization -ProcessName "FocusriteUSBAudio" -AffinityMask $scarlettAffinity -Priority $scarlettPriority

# Optimize background apps
$backgroundApps = @("Discord", "chrome")
foreach ($app in $backgroundApps) {
    Set-ProcessOptimization -ProcessName $app -AffinityMask $backgroundAffinity -Priority $backgroundPriority
}

# Monitor and reapply every 30 seconds
$runContinuously = $true
if ($runContinuously) {
    while ($true) {
        Write-Host "Reapplying optimizations... 🔄" -ForegroundColor Yellow
        Set-ProcessOptimization -ProcessName "obs64" -AffinityMask $obsAffinity -Priority $obsPriority
        Set-ProcessOptimization -ProcessName "audiodg" -AffinityMask $audioAffinity -Priority $audioPriority
        Set-ProcessOptimization -ProcessName "voicemeeter8" -AffinityMask $voicemeeterAffinity -Priority $voicemeeterPriority
        Set-ProcessOptimization -ProcessName "VBCable_A" -AffinityMask $cableAffinity -Priority $cablePriority
        Set-ProcessOptimization -ProcessName "FocusriteUSBAudio" -AffinityMask $scarlettAffinity -Priority $scarlettPriority
        foreach ($app in $backgroundApps) {
            Set-ProcessOptimization -ProcessName $app -AffinityMask $backgroundAffinity -Priority $backgroundPriority
        }
        Start-Sleep -Seconds 30
    }
}

Write-Host "Optimization complete! 🎉 Press Ctrl+C to stop." -ForegroundColor Green
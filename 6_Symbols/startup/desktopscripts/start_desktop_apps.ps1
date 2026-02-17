# PowerShell Script to Start Desktop Applications
# Purpose: Automatically starts Epic Pen, Stream Deck, Insta360 Link Controller, Obsidian, and WhatsApp
# This script is designed to run at Windows startup

# Configuration
$LogFile = "$PSScriptRoot\start_desktop_apps.log"
$StartDelay = 2  # Delay between starting each app (in seconds)

# Function to write log messages
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Function to check if a process is already running
function Test-ProcessRunning {
    param([string]$ProcessName)
    
    try {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        return $null -ne $process
    }
    catch {
        return $false
    }
}

# Function to start an application
function Start-Application {
    param(
        [string]$AppName,
        [string]$ProcessName,
        [string]$ExePath
    )
    
    Write-Log "Attempting to start $AppName..."
    
    # Check if already running
    if (Test-ProcessRunning -ProcessName $ProcessName) {
        Write-Log "$AppName is already running."
        return $true
    }
    
    # Check if executable exists
    if (-not (Test-Path $ExePath)) {
        Write-Log "WARNING: $AppName not found at: $ExePath"
        Write-Log "Skipping $AppName..."
        return $false
    }
    
    try {
        Start-Process -FilePath $ExePath -ErrorAction Stop
        Write-Log "$AppName started successfully."
        Start-Sleep -Seconds $StartDelay
        return $true
    }
    catch {
        Write-Log "ERROR: Failed to start $AppName - $_"
        return $false
    }
}

# Define applications to start
# Note: These paths are common default installation locations
# Users may need to adjust paths based on their actual installation locations
$Applications = @(
    @{
        Name = "Epic Pen"
        ProcessName = "EpicPen"
        ExePath = "${env:ProgramFiles}\Epic Pen\EpicPen.exe"
    },
    @{
        Name = "Stream Deck"
        ProcessName = "StreamDeck"
        ExePath = "${env:ProgramFiles}\Elgato\StreamDeck\StreamDeck.exe"
    },
    @{
        Name = "Insta360 Link Controller"
        ProcessName = "Insta360LinkController"
        ExePath = "${env:ProgramFiles}\Insta360\Insta360 Link Controller\Insta360LinkController.exe"
    },
    @{
        Name = "Obsidian"
        ProcessName = "Obsidian"
        ExePath = "${env:LOCALAPPDATA}\Obsidian\Obsidian.exe"
    },
    @{
        Name = "WhatsApp"
        ProcessName = "WhatsApp"
        ExePath = "${env:LOCALAPPDATA}\WhatsApp\WhatsApp.exe"
    },
    @{
        Name = "MultiMonitorTool"
        ProcessName = "MultiMonitorTool"
        ExePath = "${env:ProgramFiles}\NirSoft\MultiMonitorTool\MultiMonitorTool.exe"
    },
    @{
        Name = "Blender"
        ProcessName = "blender"
        ExePath = "${env:ProgramFiles}\Blender Foundation\Blender 4.0\blender.exe"
    }
)

# Main execution
Write-Log "========================================="
Write-Log "Desktop Applications Startup Script Started"
Write-Log "========================================="

$successCount = 0
$failCount = 0

foreach ($app in $Applications) {
    $result = Start-Application -AppName $app.Name -ProcessName $app.ProcessName -ExePath $app.ExePath
    if ($result) {
        $successCount++
    }
    else {
        $failCount++
    }
}

Write-Log "========================================="
Write-Log "Startup completed: $successCount succeeded, $failCount failed/skipped"
Write-Log "========================================="

exit 0

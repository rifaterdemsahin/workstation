# Agent Temperature Monitor Setup Report - 2026-05-08

This report documents the creation and setup of a system temperature monitoring solution that runs automatically after Windows startup.

## Files Created:

1.  **`6_Symbols/startup/monitor_temperatures.ps1`**:
    *   **Purpose**: This PowerShell script is designed to read CPU and GPU temperatures. It waits for 5 minutes after startup to allow the system to settle. It then attempts to retrieve CPU temperature via WMI (Windows Management Instrumentation) and NVIDIA GPU temperature via `nvidia-smi`.
    *   **Features**:
        *   Configurable thresholds for normal, elevated, and critical temperatures.
        *   Visual warnings in the terminal (using `Write-Host` with color coding) for temperature status.
        *   Provides guidance if temperature data cannot be retrieved.
        *   Keeps the terminal window open for 10 seconds to display results before closing.

2.  **`6_Symbols/startup/install_temperature_monitor_task.ps1`**:
    *   **Purpose**: This PowerShell script automates the setup of `monitor_temperatures.ps1` as a scheduled task to ensure it runs automatically at system startup.
    *   **Features**:
        *   Requires Administrator privileges for execution.
        *   Creates a scheduled task named "MonitorTemperaturesAtStartup".
        *   Configures the task to run `monitor_temperatures.ps1` using `powershell.exe -NoProfile -WindowStyle Hidden -File` at system startup.
        *   Redirects all script output (stdout and stderr) to a log file: `C:\projects\workstation\6_Symbols\Logs	emperature_monitor_task.log`.
        *   The task is set to run under the "SYSTEM" user, providing necessary permissions.
        *   Handles updating the task if it already exists.

## Installation Instructions:

To activate the temperature monitoring:

1.  **Open PowerShell as Administrator**:
    *   Search for "PowerShell" in the Start Menu.
    *   Right-click on "Windows PowerShell" (or "PowerShell") and select "Run as Administrator".
    2.  **Navigate to the script directory**:
        ```powershell
        cd "C:\projects\workstation\6_Symbols\startup"
        ```
    3.  **Execute the installation script**:
        ```powershell
        .\install_temperature_monitor_task.ps1
        ```

After successful execution, the scheduled task will be set up. The `monitor_temperatures.ps1` script will then run 5 minutes after every Windows startup, and its output will be logged to `C:\projects\workstation\6_Symbols\Logs	emperature_monitor_task.log`.

## Sanity Check and Visual Warnings:

The `monitor_temperatures.ps1` script includes pre-defined thresholds for CPU and GPU. If temperatures exceed these, warnings or critical alerts will be displayed in the terminal window that briefly appears. The log file will also contain this information. You can customize the `$CPUNormalThreshold`, `$CPUElevatedThreshold`, `$CPUCriticalThreshold`, `$GPUNormalThreshold`, `$GPUElevatedThreshold`, and `$GPUCriticalThreshold` variables directly in `monitor_temperatures.ps1` to suit your system's specific operating ranges.

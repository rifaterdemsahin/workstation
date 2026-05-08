# PowerShell Script to Monitor CPU and GPU Temperatures at Startup
# Purpose: Read CPU and GPU temperatures after a delay and provide visual warnings.

#region Configuration
$StartupDelaySeconds = 300 # 5 minutes
$CPUNormalThreshold = 60   # Celsius
$CPUElevatedThreshold = 75 # Celsius
$CPUCriticalThreshold = 90 # Celsius

$GPUNormalThreshold = 65   # Celsius
$GPUElevatedThreshold = 80 # Celsius
$GPUCriticalThreshold = 95 # Celsius
#endregion

# Wait for system to settle
Write-Host "Monitoring temperatures will start in $($StartupDelaySeconds / 60) minutes..." -ForegroundColor Yellow
Start-Sleep -Seconds $StartupDelaySeconds

Write-Host "Starting temperature monitoring..." -ForegroundColor Green

#region Function to Get CPU Temperature
function Get-CPUTemperature {
    try {
        $tempObject = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction Stop
        if ($tempObject) {
            # WMI returns temperature in Kelvin * 10, convert to Celsius
            $celsius = ($tempObject.CurrentTemperature / 10) - 273.15
            return [math]::Round($celsius, 2)
        } else {
            Write-Warning "Could not retrieve CPU temperature via WMI. This method may not be supported on your system."
            return $null
        }
    }
    catch {
        Write-Warning "Error retrieving CPU temperature: $($_.Exception.Message). WMI method might not be supported."
        return $null
    }
}
#endregion

#region Function to Get NVIDIA GPU Temperature
function Get-NVIDIAGPUTemperature {
    if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
        try {
            $gpuTemp = (nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader).Trim()
            return [int]$gpuTemp
        }
        catch {
            Write-Warning "Error retrieving NVIDIA GPU temperature: $($_.Exception.Message)"
            return $null
        }
    } else {
        Write-Warning "nvidia-smi not found. NVIDIA GPU temperature cannot be retrieved."
        return $null
    }
}
#endregion

#region Temperature Monitoring Logic
$cpuTemp = Get-CPUTemperature
if ($cpuTemp -ne $null) {
    Write-Host "CPU Temperature: $($cpuTemp)°C" -ForegroundColor DarkCyan
    if ($cpuTemp -ge $CPUCriticalThreshold) {
        Write-Host "CRITICAL: CPU temperature is dangerously high!" -ForegroundColor Red
    } elseif ($cpuTemp -ge $CPUElevatedThreshold) {
        Write-Host "WARNING: CPU temperature is elevated." -ForegroundColor Magenta
    } elseif ($cpuTemp -ge $CPUNormalThreshold) {
        Write-Host "INFO: CPU temperature is normal but watch it." -ForegroundColor Yellow
    } else {
        Write-Host "INFO: CPU temperature is good." -ForegroundColor Green
    }
}

$gpuTemp = Get-NVIDIAGPUTemperature
if ($gpuTemp -ne $null) {
    Write-Host "GPU Temperature: $($gpuTemp)°C" -ForegroundColor DarkCyan
    if ($gpuTemp -ge $GPUCriticalThreshold) {
        Write-Host "CRITICAL: GPU temperature is dangerously high!" -ForegroundColor Red
    } elseif ($gpuTemp -ge $GPUElevatedThreshold) {
        Write-Host "WARNING: GPU temperature is elevated." -ForegroundColor Magenta
    } elseif ($gpuTemp -ge $GPUNormalThreshold) {
        Write-Host "INFO: GPU temperature is normal but watch it." -ForegroundColor Yellow
    } else {
        Write-Host "INFO: GPU temperature is good." -ForegroundColor Green
    }
}

# Provide guidance if temperatures couldn't be retrieved
if ($cpuTemp -eq $null -and $gpuTemp -eq $null) {
    Write-Host "Could not retrieve any temperature data directly." -ForegroundColor Red
    Write-Host "Consider installing third-party tools like HWiNFO or CoreTemp for more reliable sensor readings." -ForegroundColor White
}

# Keep the terminal open briefly to show results
Write-Host "Monitoring complete. Closing in 10 seconds..." -ForegroundColor DarkGray
Start-Sleep -Seconds 10
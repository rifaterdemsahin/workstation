# AnalyzeETL.ps1
# Script to analyze an xperf ETL file for DPC/ISR latency and performance metrics

# Configuration
$etlFilePath = "C:\projects\workstation\6_Symbols\Logs\Reports\LatencyTrace_20250525_222616.etl"
$outputDir = "C:\projects\workstation\6_Symbols\Logs\Reports"
$outputFile = "$outputDir\LatencyAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$csvFile = "$outputDir\LatencyAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$xperfPath = "C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\xperf.exe"

# Ensure output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force
}

# Check if xperf is installed
if (-not (Test-Path $xperfPath)) {
    Write-Error "xperf.exe not found at $xperfPath. Please install the Windows Performance Toolkit from the Windows ADK."
    exit 1
}

# Check if ETL file exists
if (-not (Test-Path $etlFilePath)) {
    Write-Error "ETL file not found at $etlFilePath."
    exit 1
}

# Function to log messages
function Write-Log {
    param ($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [INFO] $Message"
    Write-Output $logMessage
    Add-Content -Path $outputFile -Value $logMessage
}

# Initialize output file
New-Item -ItemType File -Path $outputFile -Force | Out-Null
Write-Log "Starting ETL analysis for $etlFilePath"

# Run xperf to extract DPC/ISR summary
Write-Log "Extracting DPC/ISR summary..."
$dpcIsrOutput = & $xperfPath -i $etlFilePath -a dpcisr -summary 2>&1
Add-Content -Path $outputFile -Value "`n=== DPC/ISR Summary ===`n$dpcIsrOutput"

# Run xperf to extract process summary
Write-Log "Extracting process summary..."
$processOutput = & $xperfPath -i $etlFilePath -a process -summary 2>&1
Add-Content -Path $outputFile -Value "`n=== Process Summary ===`n$processOutput"

# Run xperf to extract CPU usage
Write-Log "Extracting CPU usage..."
$cpuOutput = & $xperfPath -i $etlFilePath -a cpudisk -summary 2>&1
Add-Content -Path $outputFile -Value "`n=== CPU Usage Summary ===`n$cpuOutput"

# Extract DPC/ISR details to CSV for easier analysis
Write-Log "Generating DPC/ISR CSV report..."
$csvOutput = & $xperfPath -i $etlFilePath -a dpcisr -detail -csv 2>&1
$csvOutput | Out-File -FilePath $csvFile -Encoding UTF8

# Analyze DPC/ISR data for high-latency drivers
Write-Log "Analyzing high-latency drivers..."
$dpcIsrLines = $dpcIsrOutput -split "`n"
$highLatencyDrivers = @()
foreach ($line in $dpcIsrLines) {
    if ($line -match "(\S+\.sys)\s.*\s(\d+\.\d+)\s(us)") {
        $driver = $matches[1]
        $duration = [float]$matches[2]
        if ($duration -gt 100) {  # Flag drivers with DPC/ISR duration > 100us
            $highLatencyDrivers += [PSCustomObject]@{
                Driver = $driver
                DurationUs = $duration
            }
        }
    }
}

# Log high-latency drivers
if ($highLatencyDrivers.Count -gt 0) {
    Write-Log "High-latency drivers detected (DPC/ISR duration > 100us):"
    $highLatencyDrivers | ForEach-Object {
        Write-Log "Driver: $($_.Driver), Duration: $($_.DurationUs) us"
    }
} else {
    Write-Log "No high-latency drivers detected (DPC/ISR duration > 100us)."
}

# Recommendations based on analysis
Write-Log "Generating recommendations..."
Add-Content -Path $outputFile -Value "`n=== Recommendations ===`n"
if ($highLatencyDrivers.Count -gt 0) {
    Write-Log "High-latency drivers detected. Consider the following:"
    Write-Log "- Update or replace the following drivers: $($highLatencyDrivers.Driver -join ', ')"
    Write-Log "- Use LatencyMon to monitor driver latency in real-time."
    Write-Log "- Check manufacturer websites for updated drivers (e.g., NVIDIA/AMD for GPU, Realtek for network/audio)."
} else {
    Write-Log "No significant DPC/ISR latency issues detected in drivers."
}

# Check for high CPU usage processes
$processLines = $processOutput -split "`n"
$highCpuProcesses = @()
foreach ($line in $processLines) {
    if ($line -match "(\S+\.exe)\s.*\s(\d+\.\d+)\s%") {
        $process = $matches[1]
        $cpuUsage = [float]$matches[2]
        if ($cpuUsage -gt 10) {  # Flag processes with CPU usage > 10%
            $highCpuProcesses += [PSCustomObject]@{
                Process = $process
                CpuUsagePercent = $cpuUsage
            }
        }
    }
}

if ($highCpuProcesses.Count -gt 0) {
    Write-Log "High CPU usage processes detected:"
    $highCpuProcesses | ForEach-Object {
        Write-Log "Process: $($_.Process), CPU Usage: $($_.CpuUsagePercent)%"
    }
    Write-Log "Recommendation: Close or optimize high-CPU processes (e.g., chrome.exe) to reduce system load."
} else {
    Write-Log "No high CPU usage processes detected."
}

# Finalize
Write-Log "Analysis complete. Results saved to $outputFile and $csvFile."
Write-Log "For detailed analysis, open $etlFilePath in Windows Performance Analyzer (WPA)."
Write-Log "To view the CSV report, open $csvFile in Excel or a text editor."
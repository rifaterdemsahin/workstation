# Define the Snagit application name or source
$snagitSource = "Snagit"

# Define the event log where Snagit logs its errors
$eventLog = "Application"

# Get current date for logging purposes
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Create a log file to store the Snagit errors
$logFile = "C:\SnagitErrors_$currentDate.log"

# Get the errors from the event log
$snagitErrors = Get-WinEvent -LogName $eventLog | Where-Object {
    $_.ProviderName -eq $snagitSource -and $_.LevelDisplayName -eq "Error"
}

# Check if there are any Snagit errors
if ($snagitErrors.Count -gt 0) {
    # Export the errors to a log file
    $snagitErrors | ForEach-Object {
        "TimeCreated: $($_.TimeCreated) - Message: $($_.Message)" | Out-File -FilePath $logFile -Append
    }
    Write-Output "Snagit errors found and logged to $logFile"
} else {
    Write-Output "No Snagit errors found in the event log."
}

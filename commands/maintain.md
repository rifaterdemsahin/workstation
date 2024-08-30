# PowerShell Script to Display Errors and Startup Events from Application and System Logs

This script retrieves and displays errors from the Application and System logs for the last 8 hours. It outputs the errors in a table format, summarizes the most frequent errors, highlights the longest duration tasks, and includes startup events.

## PowerShell Script

```powershell
# Fetch errors from the last 8 hours
$errors = Get-WinEvent -FilterHashtable @{LogName='Application','System'; Level=2; StartTime=(Get-Date).AddHours(-8)}

# Display errors in a table format
$errors | 
    Select-Object -Property TimeCreated, ProviderName, Id, Message |
    Sort-Object TimeCreated |
    Format-Table -AutoSize 

# Summary of the most frequent errors
$mostFrequentErrors = $errors | 
    Group-Object -Property Id | 
    Sort-Object Count -Descending | 
    Select-Object -First 5

Write-Host "Most Frequent Errors:" -ForegroundColor Yellow
$mostFrequentErrors | ForEach-Object {
    $errorSample = $_.Group[0]
    [PSCustomObject]@{
        ErrorID      = $_.Name
        Count        = $_.Count
        Source       = $errorSample.ProviderName
        LastOccurred = $errorSample.TimeCreated
        Message      = $errorSample.Message
    }
} | Format-Table -AutoSize

# Summary of the longest tasks (assumed as latest time occurrences)
$longestTasks = $errors |
    Sort-Object TimeCreated -Descending |
    Select-Object -First 5

Write-Host "Longest Duration Tasks (by TimeCreated):" -ForegroundColor Yellow
$longestTasks | Select-Object TimeCreated, ProviderName, Id, Message | Format-Table -AutoSize

# Fetch startup events from the System log
$startupEvents = Get-WinEvent -FilterHashtable @{LogName='System'; Id=6005,6006,6008; StartTime=(Get-Date).AddHours(-8)}

# Display startup events in a table format
$startupEvents | 
    Select-Object -Property TimeCreated, Id, Message |
    Sort-Object TimeCreated |
    Format-Table -AutoSize 

Write-Host "Startup Events:" -ForegroundColor Yellow
$startupEvents | ForEach-Object {
    [PSCustomObject]@{
        EventID      = $_.Id
        TimeCreated  = $_.TimeCreated
        Message      = $_.Message
    }
} | Format-Table -AutoSize

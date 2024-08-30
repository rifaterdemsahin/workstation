# PowerShell Script to Display Errors from Application and System Logs

This script retrieves and displays errors from the Application and System logs for the last 8 hours. It outputs the errors in a table format, summarizes the most frequent errors, and highlights the longest duration tasks.

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

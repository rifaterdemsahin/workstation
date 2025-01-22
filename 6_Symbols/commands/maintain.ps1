# Define the base time range (last 8 hours)
$timeRange = (Get-Date).AddHours(-8)

# Fetch errors from the last 8 hours in Application and System logs
$errors = Get-WinEvent -FilterHashtable @{
    LogName = 'Application', 'System'; 
    Level = 2; 
    StartTime = $timeRange
} -ErrorAction SilentlyContinue

# Check and display errors if found
if ($errors) {
    $errors | 
        Select-Object -Property TimeCreated, ProviderName, Id, Message |
        Sort-Object TimeCreated |
        Format-Table -AutoSize

    # Summary of the most frequent errors
    $mostFrequentErrors = $errors | 
        Group-Object -Property Id | 
        Sort-Object Count -Descending | 
        Select-Object -First 5

    Write-Host "`nMost Frequent Errors:" -ForegroundColor Yellow
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

    # Summary of the most recent errors
    $recentErrors = $errors |
        Sort-Object TimeCreated -Descending |
        Select-Object -First 5

    Write-Host "`nMost Recent Errors:" -ForegroundColor Yellow
    $recentErrors | 
        Select-Object -Property TimeCreated, ProviderName, Id, Message | 
        Format-Table -AutoSize
} else {
    Write-Host "No errors found in the Application and System logs for the last 8 hours." -ForegroundColor Yellow
}

# Fetch startup events from the System log
$startupEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'System'; 
    Id = 6005, 6006, 6008; 
    StartTime = $timeRange
} -ErrorAction SilentlyContinue

# Display startup events if found
if ($startupEvents) {
    Write-Host "`nStartup Events:" -ForegroundColor Yellow
    $startupEvents | 
        Select-Object -Property TimeCreated, Id, Message |
        Sort-Object TimeCreated |
        Format-Table -AutoSize
} else {
    Write-Host "No startup events found in the System log for the last 8 hours." -ForegroundColor Yellow

    # Optional: Provide a prompt to adjust the time range if no startup events are found
    $userInput = Read-Host "Would you like to extend the time range to 24 hours to check for startup events? (y/n)"
    if ($userInput -eq 'y') {
        $timeRange = (Get-Date).AddHours(-24)
        $startupEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'System'; 
            Id = 6005, 6006, 6008; 
            StartTime = $timeRange
        } -ErrorAction SilentlyContinue

        if ($startupEvents) {
            Write-Host "`nStartup Events (last 24 hours):" -ForegroundColor Yellow
            $startupEvents | 
                Select-Object -Property TimeCreated, Id, Message |
                Sort-Object TimeCreated |
                Format-Table -AutoSize
        } else {
            Write-Host "No startup events found in the System log for the last 24 hours." -ForegroundColor Yellow
        }
    }
}

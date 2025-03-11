# Enable debug output
$DebugPreference = "Continue"

# Log start of script
Write-Debug "Starting script execution"
Write-Debug "Working directory set to: C:\Program Files\Google\Chrome\Application"

try {
    # Record start time
    $startTime = Get-Date
    Write-Debug "Process start time: $startTime"

    # Define the Draw.io URL
    $drawIoUrl = "https://app.diagrams.net/#Hrifaterdemsahin%2Fsecondbrain%2Fmain%2Fsecondbrain%2F3_Resources%F0%9F%94%A7%2Fmymaindiagram.drawio#%7B%22pageId%22%3A%22c9-pmYIP-jNAxjsCjYgP%22%7D"

    # Start Chrome with the specific URL and profile
    Start-Process -FilePath "C:\Program Files\Google\Chrome\Application\chrome.exe" `
                  -ArgumentList "--profile-directory=`"Profile 21`" `"$drawIoUrl`"" `
                  -WorkingDirectory "C:\Program Files\Google\Chrome\Application"

    # Log successful launch
    Write-Debug "Chrome process launched successfully with Draw.io URL"
    Write-Debug "Process runtime: $((Get-Date) - $startTime)"
}
catch {
    # Error handling
    Write-Debug "Error occurred: $($_.Exception.Message)"
    Write-Debug "Stack trace: $($_.ScriptStackTrace)"
}
finally {
    # Display completion message and wait for key press
    Write-Host "Script completed. Press any key to exit..." -ForegroundColor Green
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Debug "Script terminated by user keypress"
}
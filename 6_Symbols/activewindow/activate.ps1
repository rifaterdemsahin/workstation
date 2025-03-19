# Add necessary types for clipboard and drawing functionalities
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to activate a window based on a partial title or process name
function Activate-Window {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    # Create a new instance of the WScript.Shell COM object
    $shell = New-Object -ComObject WScript.Shell

    # Attempt to find a process with a window title matching the pattern
    $process = Get-Process | Where-Object { $_.MainWindowTitle -like "*$Pattern*" } | Select-Object -First 1

    if ($process) {
        # Attempt to activate the window associated with the process ID
        if ($shell.AppActivate($process.Id)) {
            Write-Output "Activated window with title: '$($process.MainWindowTitle)'"
        } else {
            Write-Output "Failed to activate window with title: '$($process.MainWindowTitle)'"
        }
    } else {
        # If no window title matches, attempt to find a process with a name matching the pattern
        $process = Get-Process | Where-Object { $_.Name -like "*$Pattern*" } | Select-Object -First 1

        if ($process) {
            # Attempt to activate the window associated with the process ID
            if ($shell.AppActivate($process.Id)) {
                Write-Output "Activated window for process: '$($process.Name)'"
            } else {
                Write-Output "Failed to activate window for process: '$($process.Name)'"
            }
        } else {
            Write-Output "No process found matching the pattern: '$Pattern'"
        }
    }
}

# # Example usage:
# # Prompt the user to enter a search pattern
# $pattern = Read-Host "Enter the window title or process name pattern to search for"
# Activate-Window -Pattern $pattern
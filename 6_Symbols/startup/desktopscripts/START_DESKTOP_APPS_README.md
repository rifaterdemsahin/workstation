# Desktop Applications Startup Script

## Overview

`start_desktop_apps.ps1` is a PowerShell script that automatically launches your essential desktop applications at Windows startup.

## Applications Launched

This script starts the following applications:

1. **Epic Pen** - Digital annotation and drawing tool for presentations
2. **Stream Deck** - Elgato Stream Deck control software
3. **Insta360 Link Controller** - Controller for Insta360 webcam
4. **Obsidian** - Knowledge management and note-taking application
5. **WhatsApp** - WhatsApp desktop messenger

## Features

- ✅ **Automatic Startup** - Runs at Windows login
- ✅ **Duplicate Prevention** - Checks if apps are already running before launching
- ✅ **Path Validation** - Verifies executable paths before attempting to start
- ✅ **Error Handling** - Gracefully handles missing applications
- ✅ **Logging** - Creates detailed logs for troubleshooting
- ✅ **Sequential Launch** - Starts apps with a 2-second delay between each

## Installation

### Quick Install

1. Navigate to `6_Symbols/startup/desktopscripts/`
2. Double-click `copy_startup_scripts.bat`
3. The script will be automatically added to Windows Startup

### Manual Install

1. Open PowerShell as Administrator
2. Navigate to the scripts directory:
   ```powershell
   cd C:\path\to\workstation\6_Symbols\startup\desktopscripts
   ```
3. Run the installer:
   ```powershell
   .\install_startup_shortcuts.ps1
   ```

## Default Installation Paths

The script assumes the following default installation paths:

| Application | Default Path |
|------------|-------------|
| Epic Pen | `C:\Program Files\Epic Pen\EpicPen.exe` |
| Stream Deck | `C:\Program Files\Elgato\StreamDeck\StreamDeck.exe` |
| Insta360 Link Controller | `C:\Program Files\Insta360\Insta360 Link Controller\Insta360LinkController.exe` |
| Obsidian | `%LOCALAPPDATA%\Obsidian\Obsidian.exe` |
| WhatsApp | `%LOCALAPPDATA%\WhatsApp\WhatsApp.exe` |

## Customizing Application Paths

If your applications are installed in different locations:

1. Open `start_desktop_apps.ps1` in a text editor (Notepad, VS Code, etc.)
2. Locate the `$Applications` array (around line 66)
3. Update the `ExePath` values to match your installation paths
4. Save the file

### Example

```powershell
@{
    Name = "Epic Pen"
    ProcessName = "EpicPen"
    ExePath = "D:\MyApps\Epic Pen\EpicPen.exe"  # Custom path
}
```

## Adding More Applications

To add additional applications to the startup script:

1. Open `start_desktop_apps.ps1` in a text editor
2. Add a new entry to the `$Applications` array:

```powershell
@{
    Name = "Your App Name"
    ProcessName = "AppProcessName"  # Name as it appears in Task Manager
    ExePath = "C:\Path\To\Your\App.exe"
}
```

3. Save the file

## Removing Applications

To prevent certain applications from starting:

1. Open `start_desktop_apps.ps1` in a text editor
2. Comment out or remove the application entry from the `$Applications` array
3. Save the file

Example:
```powershell
# @{
#     Name = "Epic Pen"
#     ProcessName = "EpicPen"
#     ExePath = "${env:ProgramFiles}\Epic Pen\EpicPen.exe"
# },
```

## Verification

After installation:

1. **Check Startup Folder**:
   - Press `Win + R`
   - Type `shell:startup`
   - Verify the "start_desktop_apps" shortcut is present

2. **Test the Script**:
   - Log out and log back in, or restart your computer
   - Check if the applications launch automatically

3. **Check the Log**:
   - Open `start_desktop_apps.log` in the desktopscripts folder
   - Review for any errors or warnings

## Troubleshooting

### Applications Not Starting

1. **Check Installation**: Verify all applications are installed on your system
2. **Verify Paths**: Ensure the paths in the script match your actual installation locations
3. **Review Logs**: Check `start_desktop_apps.log` for error messages
4. **Manual Test**: Run the script manually to see real-time output:
   ```powershell
   cd C:\path\to\workstation\6_Symbols\startup\desktopscripts
   .\start_desktop_apps.ps1
   ```
5. **Check Permissions**: Ensure you have permissions to run the applications

### Script Not Running at Startup

1. **Execution Policy**: Set PowerShell execution policy:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
2. **Verify Shortcut**: Check that the shortcut exists in the Startup folder (`shell:startup`)
3. **Check Shortcut Properties**: Ensure the shortcut target is correct

### Some Apps Start, Others Don't

This is normal behavior. The script:
- Skips applications that aren't installed
- Skips applications that are already running
- Continues with remaining apps even if one fails

Check the log file to see which apps were skipped and why.

## Uninstallation

To stop the script from running at startup:

1. Press `Win + R`
2. Type `shell:startup`
3. Delete the "start_desktop_apps" shortcut
4. The script will no longer run at startup

## Configuration

The script has the following configurable parameters at the top:

```powershell
$LogFile = "$PSScriptRoot\start_desktop_apps.log"  # Log file location
$StartDelay = 2  # Delay between starting each app (in seconds)
```

You can adjust these values to customize the script's behavior.

## Log File

The script creates a log file (`start_desktop_apps.log`) that records:
- Timestamp for each action
- Which applications were started successfully
- Which applications were skipped (not found or already running)
- Any errors that occurred
- Summary of successes and failures

### Example Log Output

```
[2024-02-17 08:15:30] =========================================
[2024-02-17 08:15:30] Desktop Applications Startup Script Started
[2024-02-17 08:15:30] =========================================
[2024-02-17 08:15:30] Attempting to start Epic Pen...
[2024-02-17 08:15:30] Epic Pen started successfully.
[2024-02-17 08:15:32] Attempting to start Stream Deck...
[2024-02-17 08:15:32] Stream Deck is already running.
[2024-02-17 08:15:32] Attempting to start Insta360 Link Controller...
[2024-02-17 08:15:32] WARNING: Insta360 Link Controller not found at: C:\Program Files\Insta360\...
[2024-02-17 08:15:32] Skipping Insta360 Link Controller...
[2024-02-17 08:15:32] =========================================
[2024-02-17 08:15:32] Startup completed: 3 succeeded, 2 failed/skipped
[2024-02-17 08:15:32] =========================================
```

## Security Considerations

- The script runs with your user permissions (no admin rights required)
- Applications are started in the user's security context
- No sensitive information is stored or transmitted
- Review the script code before running to ensure it meets your security requirements

## Support

For issues or questions:
1. Check the log file for detailed error messages
2. Verify application paths match your installation
3. Try running the script manually to identify issues
4. Review the troubleshooting section above

---

**Note**: This script is designed to be minimal and efficient. It only logs essential information and runs quickly at startup to avoid delaying your Windows login process.

# System Update Script

## Overview

`run_updates_admin.ps1` - Automated system update script that runs Winget, Chocolatey, and Windows Update.

## Features

- **Winget Package Updates**: Automatically upgrades packages while skipping those with "Unknown" versions to prevent unnecessary updates
- **Chocolatey Updates**: Upgrades all Chocolatey packages
- **Windows Updates**: Installs available Windows updates using PSWindowsUpdate module
- **Admin Privilege Check**: Automatically elevates to administrator if needed

## Installation

**Copy this file to Windows Startup folder to make it work:**

```powershell
# Copy to your user's Startup folder
copy "C:\projects\workstation\6_Symbols\startup\desktopscripts\run_updates_admin.ps1" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\"
```

Or manually:
1. Press `Win + R`
2. Type `shell:startup` and press Enter
3. Copy `run_updates_admin.ps1` to the opened folder

## Behavior

### Winget Updates
- Parses winget upgrade list
- **Skips packages with "Unknown" versions** (e.g., Roblox, Wondershare Filmora)
- Displays skipped packages in yellow
- Upgrades only packages with known version numbers

### Example Output
```
Starting Winget package upgrades...

Skipping packages with Unknown versions:
  - Roblox.Roblox
  - Wondershare.Filmora

Upgrading packages with known versions...
Upgrading: Microsoft.VisualStudio.2022.BuildTools
Upgrading: ElementLabs.LMStudio
...
```

## Requirements

- PowerShell 5.1 or later
- Administrator privileges
- Winget (Windows Package Manager)
- Chocolatey (optional)
- PSWindowsUpdate module (auto-installed if missing)

## Notes

- Auto-reboot is disabled for safety
- Script pauses at the end to show output
- Press Enter to close after completion

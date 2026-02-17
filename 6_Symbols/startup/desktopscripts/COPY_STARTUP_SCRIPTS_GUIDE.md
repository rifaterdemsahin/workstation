# Windows Startup Scripts - Copy & Installation Guide

## Overview

This guide explains how to copy and install Windows startup scripts that will run automatically when Windows starts. The scripts include automation for Chrome, Gemini Second Brain, system updates, Windows event scanning, and Ollama AI service.

## Prerequisites

Before installing the startup scripts, ensure you have:

1. **PowerShell** - Already included with Windows
2. **Ollama** (for start_ollama.ps1) - Download from [https://ollama.ai](https://ollama.ai)
3. **Chrome** (for launch_chrome_urls.ps1) - If you use this script
4. **Admin Rights** - Some scripts may require administrator privileges

## Installation Methods

### Method 1: Using the Batch File (Easiest)

1. Navigate to the `6_Symbols/startup/desktopscripts/` directory
2. Double-click `copy_startup_scripts.bat`
3. Follow the on-screen prompts
4. The batch file will automatically run the PowerShell installer

### Method 2: Using PowerShell Directly

1. Open PowerShell as Administrator
2. Navigate to the scripts directory:
   ```powershell
   cd C:\path\to\workstation\6_Symbols\startup\desktopscripts
   ```
3. Run the installer:
   ```powershell
   .\install_startup_shortcuts.ps1
   ```

### Method 3: Manual Copy

If you prefer to manually install specific scripts:

1. Press `Win + R`, type `shell:startup`, and press Enter
2. This opens the Windows Startup folder
3. Right-click in the folder > New > Shortcut
4. For the location, enter:
   ```
   powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\path\to\workstation\6_Symbols\startup\desktopscripts\[SCRIPT_NAME].ps1"
   ```
5. Replace `[SCRIPT_NAME]` with the desired script name
6. Click Next, give it a name, and click Finish

## Scripts Available

| Script Name | Description | Window Style |
|------------|-------------|--------------|
| **start_ollama.ps1** | Starts Ollama service with nomic-embed-text model | Hidden |
| **launch_chrome_urls.ps1** | Opens Chrome with specific URLs and profiles | Hidden |
| **start_gemini_secondbrain.ps1** | Starts Gemini AI agent in terminal | Hidden |
| **run_updates_admin.ps1** | Checks and runs system updates | Hidden |
| **scan_windows_events.ps1** | Scans Windows event logs for errors | Normal (Visible) |
| **start_desktop_apps.ps1** | Starts Epic Pen, Stream Deck, Insta360 Link Controller, Obsidian, and WhatsApp | Hidden |
| **GPU_Diagnostic_Startup.ps1** | Runs GPU diagnostics | Hidden |

## Ollama Startup Script Details

The `start_ollama.ps1` script performs the following actions:

1. **Checks if Ollama is installed** - Verifies Ollama is in the system PATH
2. **Starts Ollama service** - Launches the Ollama service in the background
3. **Ensures model availability** - Checks if nomic-embed-text model exists
4. **Pulls model if needed** - Downloads the model automatically if not present
5. **Logs all actions** - Creates a log file (`start_ollama.log`) for troubleshooting

### Ollama Configuration

- **Service Port**: 11434 (default)
- **Model**: nomic-embed-text (used for text embeddings)
- **Log File**: `6_Symbols/startup/desktopscripts/start_ollama.log`
- **Max Retries**: 3 attempts with 5-second delays

### Installing Ollama

If Ollama is not installed:

1. Download from [https://ollama.ai](https://ollama.ai)
2. Run the installer
3. Verify installation by opening Command Prompt and typing:
   ```cmd
   ollama --version
   ```
4. The startup script will automatically pull the nomic-embed-text model on first run

## Desktop Applications Startup Script Details

The `start_desktop_apps.ps1` script performs the following actions:

1. **Checks if applications are already running** - Avoids duplicate instances
2. **Verifies application paths** - Checks if executables exist before launching
3. **Starts applications sequentially** - Launches each app with a 2-second delay
4. **Logs all actions** - Creates a log file (`start_desktop_apps.log`) for troubleshooting

### Applications Configured

The script starts the following applications:

- **Epic Pen** - Digital annotation and drawing tool
- **Stream Deck** - Elgato Stream Deck control software
- **Insta360 Link Controller** - Insta360 webcam controller
- **Obsidian** - Knowledge management and note-taking app
- **WhatsApp** - WhatsApp desktop messenger

### Default Installation Paths

The script uses these common default paths:

- Epic Pen: `C:\Program Files\Epic Pen\EpicPen.exe`
- Stream Deck: `C:\Program Files\Elgato\StreamDeck\StreamDeck.exe`
- Insta360 Link Controller: `C:\Program Files\Insta360\Insta360 Link Controller\Insta360LinkController.exe`
- Obsidian: `%LOCALAPPDATA%\Obsidian\Obsidian.exe`
- WhatsApp: `%LOCALAPPDATA%\WhatsApp\WhatsApp.exe`

### Customizing Application Paths

If your applications are installed in different locations:

1. Open `start_desktop_apps.ps1` in a text editor
2. Locate the `$Applications` array (around line 66)
3. Update the `ExePath` values to match your installation paths
4. Save the file

Example:
```powershell
@{
    Name = "Epic Pen"
    ProcessName = "EpicPen"
    ExePath = "D:\MyApps\Epic Pen\EpicPen.exe"  # Custom path
}
```

## Verification

After installation, verify the scripts:

1. **Check Startup Folder**:
   - Press `Win + R`
   - Type `shell:startup`
   - Verify shortcuts are present

2. **Test Scripts**:
   - Log out and log back in, or restart your computer
   - Check if the scripts run automatically

3. **Check Logs**:
   - For Ollama: Check `start_ollama.log` in the desktopscripts folder
   - For Desktop Apps: Check `start_desktop_apps.log` in the desktopscripts folder
   - For other scripts: Check their respective log files

## Troubleshooting

### Script Not Running

- **Execution Policy**: Ensure PowerShell execution policy allows scripts
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
  
- **Path Issues**: Verify the script paths in the shortcuts are correct

### Desktop Applications Not Starting

- **Installation Check**: Verify all applications are installed
- **Path Verification**: Check that application paths in the script match your installations
- **Log Review**: Check `start_desktop_apps.log` for specific error messages
- **Manual Test**: Try running the script manually:
  ```powershell
  cd C:\path\to\workstation\6_Symbols\startup\desktopscripts
  .\start_desktop_apps.ps1
  ```
- **Individual App Issues**: The script will skip apps that aren't found and continue with others

### Ollama Service Not Starting

- **Installation**: Verify Ollama is installed and in PATH
- **Port Conflicts**: Check if port 11434 is already in use
- **Logs**: Review `start_ollama.log` for error messages
- **Manual Test**: Try running `ollama serve` manually in Command Prompt

### Model Download Issues

- **Internet Connection**: Ensure you have an active internet connection
- **Disk Space**: Verify sufficient disk space (models can be several GB)
- **Manual Download**: Try manually pulling the model:
  ```cmd
  ollama pull nomic-embed-text
  ```

## Uninstallation

To remove startup scripts:

1. Press `Win + R`, type `shell:startup`, press Enter
2. Delete the shortcuts you want to remove
3. The scripts will no longer run at startup

## Customization

### Adding New Scripts

To add more scripts to the startup:

1. Create your PowerShell script in `6_Symbols/startup/desktopscripts/`
2. Edit `install_startup_shortcuts.ps1`
3. Add your script name to the `$ScriptsToInstall` array
4. Run the installer again

### Changing Ollama Model

To use a different Ollama model:

1. Edit `start_ollama.ps1`
2. Change the `$ModelName` variable (line 7):
   ```powershell
   $ModelName = "your-model-name"
   ```
3. Reinstall the shortcut using the batch file or PowerShell script

## Security Considerations

- **Execution Policy**: Scripts run with bypass policy for convenience
- **Hidden Windows**: Most scripts run hidden to avoid clutter
- **Admin Rights**: Some scripts may request admin privileges when needed
- **Log Files**: Review log files regularly for any issues

## Additional Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Nomic Embed Text Model](https://ollama.ai/library/nomic-embed-text)
- [PowerShell Startup Scripts Guide](https://docs.microsoft.com/en-us/powershell/)
- [Windows Startup Folder Location](https://support.microsoft.com/en-us/windows/add-an-app-to-run-automatically-at-startup-in-windows-10-150da165-dcd9-7230-517b-cf3c295d89dd)

## Support

If you encounter issues:

1. Check the log files in the desktopscripts directory
2. Verify all prerequisites are installed
3. Try running scripts manually to identify issues
4. Review the troubleshooting section above

---

**Note**: Always review scripts before running them at startup to ensure they meet your security and operational requirements.

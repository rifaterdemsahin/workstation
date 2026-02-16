# Startup Script Installation Formula

## Overview

This document describes how to configure the workstation startup scripts to run automatically when Windows starts.

## Scripts Included

1. **launch_chrome_urls.ps1**: Launches Chrome with a specific profile and opens a set of defined URLs (Telegram, Gemini, etc.).
2. **start_gemini_secondbrain.ps1**: Opens a new terminal, navigates to the Second Brain repository, and launches the Gemini agent.
3. **run_updates_admin.ps1**: Checks for updates (Winget, Chocolatey, Windows Update) and runs them. Automatically prompts for Admin privileges if needed.
4. **start_ollama.ps1**: Starts Ollama service automatically at Windows startup and ensures the nomic-embed-text model is available for text embeddings.

## Installation Instructions

To install these scripts into your Windows Startup folder, run the `install_startup_shortcuts.ps1` script located in this directory.

### run via PowerShell

```powershell
.\install_startup_shortcuts.ps1
```

### Manual Installation (Alternative)

If you prefer to manually create shortcuts:

1. Press `Win + R`, type `shell:startup`, and press Enter.
2. Right-click in the folder > New > Shortcut.
3. Target: `powershell.exe -ExecutionPolicy Bypass -File "C:\projects\workstation\6_Symbols\startup\desktopscripts\launch_chrome_urls.ps1"`
4. Repeat for the Gemini script.

## Verification

1. Restart your computer or log out and log back in.
2. Verify that Chrome opens with the tabs and a PowerShell window opens with Gemini.

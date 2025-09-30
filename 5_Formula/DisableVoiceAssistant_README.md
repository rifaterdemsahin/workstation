# Disable Voice Assistant Formula

## Overview
This formula provides a comprehensive solution to disable Windows voice assistant features at startup, including Cortana, voice services, and related voice activation features.

## Files Included
- `DisableVoiceAssistant.ps1` - Main PowerShell script
- `DisableVoiceAssistant_Startup.ps1` - Startup script (auto-generated)
- `DisableVoiceAssistant.bat` - Batch file for easy execution
- `DisableVoiceAssistant_README.md` - This documentation

## What This Formula Does

### 1. Disables Voice Services
- Cortana service
- Speech Runtime service
- Speech Service
- Windows Speech Platform
- Voice Activation Service

### 2. Registry Modifications
- Disables Cortana in Windows Search policy
- Disables web search integration
- Disables Cortana consent
- Disables voice activation
- Disables speech recognition
- Denies microphone access for voice assistant

### 3. Windows Hello Voice Features
- Disables Windows Hello biometrics
- Disables voice wake-up features

### 4. Microsoft Edge Integration
- Disables Cortana in Edge browser
- Disables voice search in Edge

### 5. Startup Persistence
- Creates a scheduled task to run at Windows startup
- Ensures voice assistant remains disabled after reboots

## Usage Instructions

### Method 1: Run as Administrator (Recommended)
1. Right-click on `DisableVoiceAssistant.bat`
2. Select "Run as administrator"
3. Follow the prompts

### Method 2: PowerShell Execution
1. Open PowerShell as Administrator
2. Navigate to the script directory
3. Run: `.\DisableVoiceAssistant.ps1`

### Method 3: Direct Execution
1. Double-click `DisableVoiceAssistant.bat`
2. If prompted, click "Yes" to run as administrator

## Requirements
- Windows 10 or Windows 11
- Administrator privileges
- PowerShell 5.0 or later

## Features

### Comprehensive Disabling
- **Services**: Disables all voice-related Windows services
- **Registry**: Modifies registry keys to prevent voice assistant activation
- **Startup**: Creates persistent startup script
- **Verification**: Tests and reports on the success of disabling operations

### Logging
- Creates detailed logs with timestamps
- Logs all operations and their results
- Saves logs to the script directory

### Error Handling
- Continues execution even if some operations fail
- Provides detailed error messages
- Logs all errors for troubleshooting

## Verification
The script includes built-in verification that checks:
- Service status (disabled/enabled)
- Registry settings
- Overall voice assistant status

## Troubleshooting

### If Voice Assistant Still Works
1. Check the log file for errors
2. Ensure you ran the script as Administrator
3. Restart your computer
4. Check if Windows updates re-enabled features

### If Services Won't Disable
1. Some services may be protected by Windows
2. Try running the script multiple times
3. Check Windows Defender or antivirus interference

### If Registry Changes Don't Take Effect
1. Restart your computer
2. Check if Group Policy is overriding settings
3. Verify you have administrator privileges

## Re-enabling Voice Assistant (If Needed)
To re-enable voice assistant features:
1. Run PowerShell as Administrator
2. Execute the following commands:
```powershell
# Re-enable Cortana service
Set-Service -Name "Cortana" -StartupType Automatic
Start-Service -Name "Cortana"

# Re-enable voice services
$voiceServices = @("SpeechRuntime", "SpeechService", "WindowsSpeechPlatform", "VoiceActivationService")
foreach ($service in $voiceServices) {
    Set-Service -Name $service -StartupType Automatic
    Start-Service -Name $service
}

# Remove scheduled task
Unregister-ScheduledTask -TaskName "DisableVoiceAssistant" -Confirm:$false
```

## Security Notes
- This script modifies system registry and services
- Always run as Administrator
- Create a system restore point before running
- Test in a non-production environment first

## Compatibility
- Windows 10 (all versions)
- Windows 11 (all versions)
- Works with both Home and Pro editions

## Support
If you encounter issues:
1. Check the generated log file
2. Ensure all requirements are met
3. Try running the script in Safe Mode
4. Contact system administrator for enterprise environments

## Version History
- v1.0: Initial release with comprehensive voice assistant disabling

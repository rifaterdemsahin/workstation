# Telegram & Gemini Chrome Launcher

This directory contains startup scripts to automatically launch Chrome with a specific profile and open the Telegram and Gemini URLs.

## Files

- `launch_telegram_gemini.ps1` - PowerShell version (recommended)
- `launch_telegram_gemini.ahk` - AutoHotkey version (alternative)
- `launch_telegram_gemini.bat` - Batch wrapper (tries PowerShell first, then AutoHotkey)
- `README_telegram_gemini.md` - This documentation file

## URLs Opened

1. **Telegram**: https://web.telegram.org/a/#-1002793496878
2. **Gemini**: https://gemini.google.com/app/a4012a0daa4ad70d

## Configuration

### Chrome Profile
The scripts are configured to use Chrome Profile 21. To change this:

**PowerShell version**: Edit line 12 in `launch_telegram_gemini.ps1`:
```powershell
ChromeProfile = "--profile-directory=`"Profile 21`""  # Change "Profile 21" to your desired profile
```

**AutoHotkey version**: Edit line 8 in `launch_telegram_gemini.ahk`:
```autohotkey
ChromeProfile := "--profile-directory=`"Profile 21`""  ; Change "Profile 21" to your desired profile
```

### Chrome Path
The scripts automatically detect Chrome in standard locations:
- `C:\Program Files\Google\Chrome\Application\chrome.exe`
- `C:\Program Files (x86)\Google\Chrome\Application\chrome.exe`

## Usage

### Method 1: Batch File (Easiest)
Double-click `launch_telegram_gemini.bat`

### Method 2: PowerShell (Recommended)
```powershell
.\launch_telegram_gemini.ps1
```

### Method 3: AutoHotkey
```autohotkey
# Run the .ahk file with AutoHotkey
```

## Logging

Both scripts create log files in:
- **PowerShell**: `%USERPROFILE%\Desktop\StartupLog\TelegramGemini_Log_YYYYMMDD_HHMMSS.txt`
- **AutoHotkey**: `%USERPROFILE%\Desktop\StartupLog\TelegramGemini_Log_YYYYMMDD_HHMMSS.txt`

## Features

- ✅ Automatic Chrome detection
- ✅ Profile validation
- ✅ Error handling and logging
- ✅ Process monitoring
- ✅ Cross-platform compatibility (PowerShell works on Windows 7+)
- ✅ Fallback mechanisms

## Troubleshooting

### Chrome Not Found
- Install Google Chrome
- Update the Chrome path in the script if installed in a non-standard location

### Profile Not Found
- The script will fall back to the default Chrome profile
- Create the desired profile in Chrome first

### Permission Issues
- Run PowerShell as Administrator if needed
- Check execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Integration with Existing Workflow

These scripts can be integrated into your existing startup automation:

1. **Add to Windows Startup**: Place a shortcut in `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`
2. **Add to existing startup script**: Include the PowerShell script in your main startup automation
3. **Scheduled Task**: Create a Windows scheduled task to run at startup

## Customization

To add more URLs, edit the URLs array:

**PowerShell**:
```powershell
URLs = @(
    "https://web.telegram.org/a/#-1002793496878",
    "https://gemini.google.com/app/a4012a0daa4ad70d",
    "https://your-additional-url.com"  # Add more URLs here
)
```

**AutoHotkey**:
```autohotkey
; Add more URL variables and launch calls
AdditionalURL := "https://your-additional-url.com"
LaunchChromeWithURL(AdditionalURL, 3000)
```

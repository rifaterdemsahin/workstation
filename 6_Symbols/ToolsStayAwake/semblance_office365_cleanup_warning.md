# Office 365 Chocolatey Upgrade Cleanup Warning

## What Happened During Update

The upgrade actually **succeeded** — Office 365 Business was updated to version 19628.20192.0 successfully.

The only "error" is this harmless cleanup warning:

```
Cannot remove item ...chocolatey\Office365Business:
The process cannot access the file because it is being used by another process.
```

However, you'll see this confirmation line:
```
The upgrade of office365business was successful
```

---

## Why This Happens

After installation, Office processes (OfficeClickToRun, etc.) are still running and have a lock on the temp folder, so Chocolatey can't delete it immediately.

**This does NOT affect the upgrade** — the installation completed successfully.

---

## Is Action Required?

**No** — This is a harmless warning. The upgrade completed successfully despite the cleanup error.

---

## How to Clean It Up (Optional)

If you want to remove the leftover temp files:

### Option 1: Reboot (Easiest)

Simply **reboot** your computer. Windows will release the file locks and the temp folder will be automatically removable.

### Option 2: Manual Cleanup

After closing all Office applications:

```powershell
# Stop Office processes
Get-Process | Where-Object { $_.Name -like "*Office*" } | Stop-Process -Force

# Wait a few seconds
Start-Sleep -Seconds 5

# Remove the temp folder
Remove-Item -Path "$env:LOCALAPPDATA\Temp\chocolatey\Office365Business" -Recurse -Force
```

Or using Command Prompt:

```cmd
rmdir /s /q "C:\Users\Pexabo\AppData\Local\Temp\chocolatey\Office365Business"
```

---

## Verification

Check if Office was updated successfully:

```powershell
# Check installed Office version
choco list --local-only office365business

# Or check via Windows
Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Office 365*" }
```

---

## Prevention

To avoid this cleanup warning in the future:

1. **Close all Office apps before updating**
   ```powershell
   # Close all Office processes before upgrade
   Get-Process | Where-Object { $_.Name -like "*Office*" -or $_.Name -like "*WINWORD*" -or $_.Name -like "*EXCEL*" -or $_.Name -like "*POWERPNT*" } | Stop-Process -Force

   # Then run the upgrade
   choco upgrade office365business -y
   ```

2. **Or simply ignore the warning** — It doesn't affect functionality

---

## Related Office Processes That May Lock Files

- `OfficeClickToRun.exe` - Office update service
- `WINWORD.EXE` - Microsoft Word
- `EXCEL.EXE` - Microsoft Excel
- `POWERPNT.EXE` - Microsoft PowerPoint
- `OUTLOOK.EXE` - Microsoft Outlook
- `ONENOTE.EXE` - Microsoft OneNote
- `MSACCESS.EXE` - Microsoft Access
- `MSPUB.EXE` - Microsoft Publisher

---

## Common Chocolatey Upgrade Cleanup Issues

This same issue can occur with other applications:

```powershell
# General cleanup for all Chocolatey temp folders (run after reboot)
Remove-Item -Path "$env:LOCALAPPDATA\Temp\chocolatey\*" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## Summary

✅ **Upgrade Status**: Successful
✅ **Office Version**: 19628.20192.0
⚠️ **Cleanup Warning**: Harmless - temp files locked by Office processes
🔧 **Fix**: Reboot or manually delete after closing Office apps
💡 **Prevention**: Close Office apps before running updates

---

**Created**: 2026-02-28
**Application**: Office 365 Business
**Update Method**: Chocolatey
**System**: Windows 11

# GPU DIAGNOSTIC STARTUP SERVICE - INSTALLATION GUIDE

## Overview
This service automatically runs GPU diagnostics at Windows startup with minimal performance impact. It logs results to `C:\ProgramData\GPU_Diagnostics\` for monitoring hardware stability.

---

## FILES INCLUDED

1. **GPU_Diagnostic_Startup.ps1**
   - Main diagnostic script
   - Runs automatically at startup (2-minute delay)
   - Logs to: C:\ProgramData\GPU_Diagnostics\diagnostic_YYYY-MM-DD.log
   - Generates human-readable report

2. **Install_GPU_Diagnostic_Task.bat**
   - Installation script (creates Windows scheduled task)
   - Must run as Administrator
   - One-time setup required

3. **GPU_Diagnostic_Manager.ps1**
   - Management and monitoring tool
   - View logs, reports, task status
   - Run diagnostics on-demand
   - Enable/disable/remove the service

---

## INSTALLATION (EASY)

### Step 1: Download Files
Copy all three files to a folder:
- C:\Temp\GPU_Diagnostics\ (or any location)

### Step 2: Run Installer
1. Right-click **Install_GPU_Diagnostic_Task.bat**
2. Select **"Run as administrator"**
3. Wait for completion (should see success message)
4. Close the window

### Step 3: Verify Installation
1. Right-click **GPU_Diagnostic_Manager.ps1**
2. Select **"Run with PowerShell"**
3. Should show task status and latest report

**That's it! The service will now run at every Windows startup.**

---

## USAGE

### View Diagnostic Status
```powershell
.\GPU_Diagnostic_Manager.ps1 -Action status
```
Shows: Task status, last run time, next run time, enabled/disabled state

### View Latest Report
```powershell
.\GPU_Diagnostic_Manager.ps1 -Action report
```
Shows: Human-readable summary of GPU status, memory, disk, errors

### View Recent Logs (Last 20 lines)
```powershell
.\GPU_Diagnostic_Manager.ps1 -Action logs
```

### View More Log Lines (Last 50 lines)
```powershell
.\GPU_Diagnostic_Manager.ps1 -Action logs -Lines 50
```

### Run Diagnostic Now (On-Demand)
```powershell
.\GPU_Diagnostic_Manager.ps1 -Action test
```
Useful for testing after GPU reseat or driver update

### Disable Automatic Startup
```powershell
.\GPU_Diagnostic_Manager.ps1 -Action disable
```
Diagnostic will stop running at startup (can be re-enabled)

### Enable Automatic Startup
```powershell
.\GPU_Diagnostic_Manager.ps1 -Action enable
```
Re-enable if previously disabled

### Remove Service Completely
```powershell
.\GPU_Diagnostic_Manager.ps1 -Action remove
```
Uninstalls the scheduled task (can be reinstalled anytime)

---

## LOG FILES LOCATION

**Automatic Logs:**
- C:\ProgramData\GPU_Diagnostics\diagnostic_YYYY-MM-DD.log
- One log file per day
- Logs kept for 30 days automatically

**Report File:**
- C:\ProgramData\GPU_Diagnostics\latest_report.txt
- Updated after each diagnostic run
- Human-readable format

**Example Log Entry:**
```
[2026-01-25 08:15:34] [INFO] GPU: AMD Radeon RX 6900 XT | Driver: 31.0.12061 | VRAM: 16GB
[2026-01-25 08:15:34] [INFO] PCIe OK: AMD Radeon RX 6900 XT
[2026-01-25 08:15:34] [INFO] No critical PCIe/GPU errors in last 12 hours
[2026-01-25 08:15:34] [INFO] Memory Usage: 35% (23456MB used)
```

---

## WHAT GETS CHECKED

✓ GPU Detection & Driver Version
✓ PCIe Device Status
✓ Critical Hardware Errors (PCIe, GPU-related)
✓ System Memory Usage
✓ Disk Space (C: drive)
✓ Thermal Status (if available)
✓ DaVinci Resolve Crash Detection
✓ Generates Human-Readable Report

---

## PERFORMANCE IMPACT

⚡ **Minimal** - Runs 2 minutes after startup
⏱️ **Duration**: 5-10 seconds
💾 **Memory**: <50 MB
📊 **CPU**: <1% during check
🎯 **No impact** on DaVinci Resolve performance during normal work

---

## TROUBLESHOOTING

### Task Won't Install
```
ERROR: This script must run as Administrator!
```
→ Right-click cmd.exe → "Run as administrator" → Run Install_GPU_Diagnostic_Task.bat

### Can't View Logs
```powershell
# Try opening log directory directly:
explorer.exe "C:\ProgramData\GPU_Diagnostics"
```

### Task Not Running at Startup
1. Run Manager: `.\GPU_Diagnostic_Manager.ps1 -Action status`
2. Check "Enabled:" line - should say "Yes"
3. If disabled, run: `.\GPU_Diagnostic_Manager.ps1 -Action enable`
4. Check Event Viewer → Windows Logs → System for scheduled task errors

### PowerShell Won't Run Scripts
```powershell
# Run as Administrator PowerShell, then:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## WHAT TO DO IF ERRORS ARE DETECTED

### PCIe Errors
- Physically reseat your GPU (remove and reinstall firmly)
- Clean PCIe slot with compressed air
- Update AMD GPU drivers from: https://www.amd.com/en/support
- Update motherboard chipset drivers

### GPU Not Detected
- Check Device Manager for unknown devices
- Update chipset drivers
- Try different PCIe slot if available
- Check power connectors are fully seated

### High Temperature
- Check GPU heatsink for dust
- Clean fans with compressed air
- Check case airflow
- Lower DaVinci Resolve timeline quality if needed

### Memory or Disk Usage High
- Close unnecessary applications
- Clear temporary files: `Disk Cleanup` utility
- Check what's using disk space in File Explorer

---

## AFTER GPU RESEAT

1. Physically reseat GPU in PCIe x16 slot closest to CPU
2. Run diagnostic on-demand:
   ```powershell
   .\GPU_Diagnostic_Manager.ps1 -Action test
   ```
3. Check logs for any PCIe errors:
   ```powershell
   .\GPU_Diagnostic_Manager.ps1 -Action logs
   ```
4. Test DaVinci Resolve proxy media creation
5. Monitor for errors over next few hours

---

## CHECKING WINDOWS EVENT VIEWER

For detailed error information:
1. Press Windows Key + R
2. Type: `eventvwr.msc`
3. Go to Windows Logs → System
4. Look for "Corrected Hardware Error" events
5. Filter by Source: "Microsoft-Windows-WHEA-Logger"

---

## AUTOMATIC CLEANUP

⏰ **Old logs deleted automatically after 30 days**
📁 **Space used**: ~50 KB per day per log file
🧹 **No manual cleanup needed**

---

## SUPPORT / MANUAL CHECKS

### Run Comprehensive System Test
```powershell
# Full system diagnostic with FFmpeg stress test:
.\GPU_System_Diagnostic_Test.ps1

# Quick diagnostic without FFmpeg:
.\GPU_Quick_Diagnostic.ps1
```

### Check GPU Driver Health
```powershell
Get-WmiObject Win32_VideoController | Format-List Name, DriverVersion, AdapterRAM
```

### Monitor Real-Time Temperatures
- Download HWiNFO64 from hwinfo.com
- Or GPU-Z from techpowerup.com

---

## NEXT STEPS

1. **Install the service** using Install_GPU_Diagnostic_Task.bat
2. **Reseat your GPU** following the video guide
3. **Run on-demand test** after GPU reseat:
   ```powershell
   .\GPU_Diagnostic_Manager.ps1 -Action test
   ```
4. **Check the report** for any PCIe errors
5. **Update drivers** if errors are detected
6. **Monitor for DaVinci Resolve stability** during proxy media creation

---

## FAQ

**Q: Will this slow down my computer?**
A: No, it runs 2 minutes after startup and takes ~5 seconds. Zero impact on DaVinci Resolve performance.

**Q: How often does it run?**
A: At every Windows startup automatically. You can also run it on-demand anytime.

**Q: Can I uninstall it?**
A: Yes, run: `.\GPU_Diagnostic_Manager.ps1 -Action remove`

**Q: Where are logs stored?**
A: C:\ProgramData\GPU_Diagnostics\

**Q: What if PCIe errors are detected?**
A: Reseat GPU, clean with compressed air, update drivers, check power connectors.

---

## CONTACT / ISSUES

For issues:
1. Check logs: `C:\ProgramData\GPU_Diagnostics\`
2. Check Event Viewer: `eventvwr.msc` → Windows Logs → System
3. Run manual diagnostic: `.\GPU_System_Diagnostic_Test.ps1`
4. Verify GPU is seated firmly in PCIe x16 slot

---

Created: January 2026
For: WRX80 + Ryzen Threadripper 3995X + AMD Radeon RX 6900 XT
Purpose: DaVinci Resolve Proxy Media Stability

# Windows Reboot Investigation Report

**Date:** 2026-05-12  
**Investigator:** OpenCode Agent  
**Subject:** Unexpected System Reboots on Workstation `W11V32023720`

---

## Executive Summary

This report documents the findings from a diagnostic investigation into unexpected system reboots occurring on the workstation. **Two unexpected shutdowns were identified on 2026-05-12**, accompanied by a **fatal hardware error** and critical system events. Immediate hardware diagnostics and service stabilization are recommended.

---

## 1. Reboot History

Analysis of System Event Log (Event IDs 1074, 1076, 6008) reveals the following recent power events:

| Time | Event ID | Type | Details |
|------|----------|------|---------|
| 2026-05-12 12:36:42 | 6008 | Unexpected Shutdown | Previous shutdown at 12:24:30 was unexpected |
| 2026-05-12 08:13:41 | 6008 | Unexpected Shutdown | Previous shutdown at 07:36:28 was unexpected |
| 2026-05-11 19:19:20 | 1074 | Planned Power Off | Initiated by StartMenuExperienceHost (User: AzureAD\Pexabo) |
| 2026-05-11 18:52:15 | 1074 | Planned Power Off | Initiated by StartMenuExperienceHost (User: AzureAD\Pexabo) |
| 2026-05-10 18:47:43 | 1074 | Planned Power Off | Initiated by StartMenuExperienceHost (User: AzureAD\Pexabo) |
| 2026-05-10 18:30:44 | 1074 | Planned Restart | Initiated by StartMenuExperienceHost (User: AzureAD\Pexabo) |
| 2026-05-10 17:19:34 | 1074 | Planned Restart | Initiated by winlogon.exe (User: AzureAD\Pexabo) |

**Key Finding:** Two **unexpected shutdowns** occurred on the same day (2026-05-12) without a clean shutdown sequence, indicating potential hardware instability, driver failure, or power loss.

---

## 2. Windows Update Status

Recent updates installed (last 5):

| HotFix ID | Installed On |
|-----------|--------------|
| KB5083631 | 2026-05-02 |
| KB5082417 | 2026-04-16 |
| KB5088467 | 2026-04-16 |
| KB5054156 | 2025-10-17 |

**Assessment:** Updates were installed recently (KB5083631 on 2026-05-02). While correlation does not imply causation, update-related instability should be considered if reboots began after this date.

---

## 3. System Errors & Crashes

Critical and Error-level events from the System log (last 10):

| Level | Time | Source / Description |
|-------|------|----------------------|
| Error | 12:37:22 | Smart card logon certificate DN issue |
| **Error** | **12:36:43** | **A fatal hardware error has occurred.** |
| Error | 12:36:43 | NativePushService failed to start |
| **Critical** | **12:36:30** | **System rebooted without cleanly shutting down first.** |
| Error | 12:36:42 | Unexpected shutdown at 12:24:30 |
| Error | 12:17:33 | DCOM error starting MicrosoftEdgeElevationService |
| Error | 12:17:33 | Microsoft Edge Elevation Service failed |
| Error | 11:47:27 | Windows Camera Frame Server terminated unexpectedly |
| Error | 10:09:23 | Device Association Service endpoint discovery failure |
| Error | 09:26:52 | windows_exporter service terminated unexpectedly |

**Key Findings:**
- **Fatal hardware error at 12:36:43** — This is the highest severity finding and the most probable root cause for the unexpected reboots.
- **Critical Event 41 at 12:36:30** — Kernel-Power event indicating an unclean reboot, consistent with a hardware-induced crash or hard power loss.
- Multiple service terminations (`windows_exporter`, `Camera Frame Server`, `NativePushService`) suggest system instability around the time of the crashes.

---

## 4. Power Settings

| Setting | Value |
|---------|-------|
| Sleep Timeout (AC) | 0x00000000 (Never) |
| Hibernate | **Disabled / Not Available** |
| Wake Timers | **None active** (Wake History Count = 0) |

**Assessment:** Power settings are not the cause of the reboots. Sleep and hibernate are disabled, and no wake timers are scheduled.

---

## 5. Disk Health

| Drive | Used | Total | Status |
|-------|------|-------|--------|
| System Reserved | 1 GB | 1 GB | Healthy |
| C: | 1,528 GB | 1,862 GB | Healthy |
| F: | 412 GB | 447 GB | Healthy |

**Assessment:** All fixed drives report healthy capacity with no low-space conditions. Disk corruption is unlikely to be the primary cause.

---

## 6. Device Driver Status

| Status | Count |
|--------|-------|
| OK | All enumerated devices |
| Error / Degraded | **0** |

**Assessment:** No devices are reporting Error or Degraded status in PnP. However, this does not rule out transient driver failures or hardware faults that do not persist in device status.

---

## 7. Scheduled Tasks

Active or running scheduled tasks identified:

- Adobe Acrobat Update Task (Running)
- ASC_PerformanceMonitor (Running)
- MSIAfterburner (Running)
- Chrome URL Launcher (Ready)
- Clawdbot Gateway (Ready)
- CreateExplorerShellUnelevatedTask (Ready)
- ObsidianAutoSync (Ready)
- OneDrive Per-Machine Standalone Update Task (Ready)

**Assessment:** No scheduled tasks are configured to trigger system reboots. `MSIAfterburner` and `ASC_PerformanceMonitor` are running but are not known to force reboots.

---

## 8. System File Integrity

No live scan was performed. Recommended commands:

```powershell
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
```

---

## Root Cause Analysis (Preliminary)

Based on the evidence, the most likely causes for the unexpected reboots are ranked as follows:

1. **Hardware Fault (Highest Probability)**
   - **Fatal hardware error** logged at the exact time of the unexpected reboot.
   - This typically points to **CPU, RAM, PSU, or motherboard** faults.
   - Action: Run Windows Memory Diagnostic (`mdsched.exe`) and inspect hardware health (temperatures, voltages).

2. **Power Supply Instability**
   - Unclean shutdowns without a preceding software-initiated power event can indicate power delivery issues.
   - Action: Verify PSU health and power connections.

3. **Driver / Kernel Crash (Lower Probability)**
   - No persistent driver errors found, but a transient GPU, storage, or chipset driver crash could trigger a bugcheck.
   - Action: Review `C:\Windows\Minidump` for `.dmp` files and analyze with WinDbg.

4. **Windows Update Side Effect**
   - KB5083631 was installed 10 days prior. If reboots began after this date, consider rollback.
   - Action: Correlate reboot timeline with update installation date.

---

## Recommendations & Next Steps

| Priority | Action | Command / Tool |
|----------|--------|----------------|
| **High** | Run Windows Memory Diagnostic | `mdsched.exe` |
| **High** | Check Event Viewer for WHEA-Logger events | `eventvwr.msc` -> System |
| **High** | Review minidump files for bugcheck codes | `C:\Windows\Minidump\` |
| Medium | Run System File Checker | `sfc /scannow` |
| Medium | Repair OS image with DISM | `DISM /Online /Cleanup-Image /RestoreHealth` |
| Medium | Monitor system temperatures | HWiNFO64, MSI Afterburner |
| Low | Review Windows Update history | Settings > Windows Update > Update history |

---

## Appendix: Evidence Sources

- **Event Log:** `System` (Event IDs 6008, 1074, 41, WHEA-Logger)
- **WMI:** `Win32_QuickFixEngineering`
- **Power:** `powercfg /query`, `powercfg /a`, `powercfg /lastwake`
- **Storage:** `Get-Volume` (PowerShell)
- **Devices:** `Get-PnpDevice` (PowerShell)
- **Tasks:** `Get-ScheduledTask` (PowerShell)

---

*Report generated by automated diagnostic script. Review by a system administrator is recommended before performing hardware replacements.*

# VMware & BlueStacks Post-Reboot Cleanup Report

**Report Date:** 2026-03-08 12:12:46
**Machine:** W11V32023720
**User:** Pexabo

---

## Executive Summary

This report identifies VMware and BlueStacks remnants on the system after attempted removal.

**Quick Status:**
- VMware Services: 0 found
- VMware Packages: 0 found
- VMware VM Files: 3 found
- BlueStacks Directories: 2 found
- Problem Audio Devices: 5 found

---

## 1. VMware Virtual Machine Files (.vmx)

**Total VMware VM Files Found:** 3

| File Path | Size (KB) | Last Modified |
|-----------|-----------|---------------|
| C:\Users\Pexabo\Documents\Virtual Machines\MS-DOS\MS-DOS.vmx | 2.09 | 2023-12-09 19:07 |
| C:\Users\Pexabo\Documents\Virtual Machines\msdev\msdev.vmx | 3.82 | 2024-09-24 15:28 |
| C:\Users\Pexabo\Documents\Virtual Machines\ServerlessFunctions\ServerlessFunctions.vmx | 3.89 | 2024-06-04 10:19 |

**Total VM Configuration Size:** 0.01 MB

---

## 2. VMware Services

**Total VMware Services:** 0

No VMware services found.

---

## 3. VMware Installed Packages

**Total VMware Packages:** 0

No VMware packages found via Package Manager.

---

## 4. BlueStacks Data Directories

**BlueStacks Directories Found:** 2

| Directory Path | Created | Last Modified |
|----------------|---------|---------------|
| C:\Users\Pexabo\AppData\Local\Bluestacks | 2023-12-09 | 2026-03-08 |
| C:\Users\Pexabo\AppData\Local\bluestacks-services-updater | 2023-12-09 | 2024-02-07 |

---

## 5. Audio Endpoint Devices

**Total Audio Endpoints:** 30

**Audio Device Health Summary:**
- OK: 25 (83.3%)
- Unknown: 5 (16.7%)
- Error: 0

### Problematic Audio Devices

| Status | Friendly Name |
|--------|---------------|
| Unknown | Microphone (2- Insta360 Link) |
| Unknown | Headphones (Razer BlackShark V2 Pro (BT)) |
| Unknown | 3 - SAMSUNG (AMD High Definition Audio Device) |
| Unknown | Record Mix (Elgato Virtual Audio) |
| Unknown | SFX (Elgato Virtual Audio) |

---

## 6. Cleanup Recommendations

### High Priority - VMware Removal


### Complete Cleanup Script

See: `post_reboot_check.ps1` for automated cleanup

---

## 7. System Health Metrics

| Component | Status | Details |
|-----------|--------|---------|
| VMware Services | Complete | 0 services found |
| VMware Packages | Complete | 0 packages found |
| VMware VM Files | Present | 3 VM configurations |
| BlueStacks Data | Remnants Found | 2 directories found |
| Audio Devices | Needs Attention | 5 unknown, 0 error |

---

## 8. Next Steps Checklist

- [ ] Review VMware services list and stop running services
- [ ] Disable or uninstall VMware services
- [ ] Uninstall VMware packages via Programs and Features
- [ ] Review VM directories and backup/delete as needed
- [ ] Clean up audio devices in Device Manager
- [ ] Run Windows Disk Cleanup to remove temp files
- [ ] Reboot system and re-run this report to verify cleanup

---

**Report Generated:** 2026-03-08 12:12:46
**Tool:** VMware & BlueStacks Cleanup Report Generator v2.0

# 🖥️ USB Device Simulation Report — Workstation
**Generated:** 2026-03-07 22:28  
**Script:** `Check-USBDevices.ps1`  
**Host:** Pexabo Workstation  

---

## 📊 Executive Summary

| Metric | Value |
|---|---|
| Total USB / HID Devices | **125** |
| Working Devices | **125** ✅ |
| Devices with Errors | **0** ✅ |
| USB Health Ratio | **100%** |
| Problem Devices (all classes) | **4** ⚠️ (disabled NICs) |
| StreamDeck Hardware | **Found — 15 interfaces** ✅ |
| StreamDeck Software | **Running** ✅ |
| **Health Score** | **60 / 100** |

> **Note:** The 40-point health deduction comes entirely from 4 **disabled** network adapters (ErrorCode 22 = device disabled by user/policy). No USB hardware is broken.

---

## 🧮 Health Formulas

```
HealthScore  = 100 − (ProblemDevices × 10) − (SDMissing × 30) − (USBErrors × 5)
             = 100 − (4 × 10)              − (0 × 30)          − (0 × 5)
             = 100 − 40 − 0 − 0
             = 60 / 100

HealthRatio  = WorkingUSB / TotalUSB × 100
             = 125 / 125 × 100
             = 100.0%

StabilityIndex = PerfectRuns / TotalRuns × 100
               = N/A  (first run — history accumulates from next boot)
```

---

## 🔌 USB Controllers (6)

| Controller | Manufacturer | Status |
|---|---|---|
| AMD USB 3.10 xHCI Host Controller (×4) | Generic USB xHCI | ✅ OK |
| ASMedia USB 3.20 xHCI Host Controller | Generic USB xHCI | ✅ OK |
| Synology Virtual USB Hub | Synology Inc | ✅ OK |

> AMD platform with 4 xHCI root controllers + 1 ASMedia add-in card + 1 Synology NAS virtual hub.

---

## 🌐 USB Topology Simulation

```
[AMD USB 3.10 xHCI ×4]  [ASMedia USB 3.20 xHCI]  [Synology Virtual Hub]
        │                         │                          │
   ┌────┴─────────────┐     ┌─────┴────┐             ┌──────┴──────┐
   │  USB Root Hubs   │     │ Root Hub │             │ Virtual NAS │
   │  (×5, USB 3.0)   │     │(USB 3.0) │             │   Storage   │
   └────┬─────────────┘     └─────┬────┘             └─────────────┘
        │                         │
   ┌────┴──────────────────────────────────────────────────────┐
   │               Generic USB / SuperSpeed Hubs (×12)         │
   └────┬──────────────────────────────────────────────────────┘
        │
   ┌────┴──────────────────────────────────────────────────────────────────┐
   │                      USB Composite Devices (×14+)                     │
   └────┬─────────────┬──────────────┬──────────────┬───────────┬──────────┘
        │             │              │              │           │
   [Elgato]     [Logitech]     [Razer]       [Apple]    [3Dconnexion]
   [Devices]    [Devices]      [Devices]     [Touchpad] [SpaceMouse]
```

---

## 🎛️ Elgato / StreamDeck Devices (15 interfaces, VID `0FD9`)

| # | Device Name | PID | Serial / Instance | Status |
|---|---|---|---|---|
| 1 | **Stream Deck +** — HID Consumer Control | `0084` | `A00WA5211K8U6W` | ✅ OK |
| 2 | **Stream Deck +** — USB Input | `0084` | `A00WA5211K8U6W` | ✅ OK |
| 3 | **Stream Deck XL** — USB Composite | `008A` | `A00XB34421SK1P` | ✅ OK |
| 4 | **Stream Deck XL** — HID Vendor-defined | `008A` | `MI_07` | ✅ OK |
| 5 | **Stream Deck XL** — USB Input | `008A` | `MI_07` | ✅ OK |
| 6 | **Stream Deck MK.2** — USB Composite | `0078` | `FW15K1A13280` | ✅ OK |
| 7 | **Stream Deck MK.2** — USB Input | `0078` | `MI_02` | ✅ OK |
| 8 | **Stream Deck MK.2** — HID Vendor-defined | `0078` | `MI_02` | ✅ OK |
| 9 | **Stream Deck Mini** — HID Consumer Control | `006C` | `CL13K1A05274` | ✅ OK |
| 10 | **Stream Deck Mini** — USB Input | `006C` | `CL13K1A05274` | ✅ OK |
| 11 | **Stream Deck Mini** — HID Consumer Control | `006C` | `CL13K1A05278` | ✅ OK |
| 12 | **Stream Deck Mini** — USB Input | `006C` | `CL13K1A05278` | ✅ OK |
| 13 | **Elgato Wave:3** — USB Composite | `0070` | `BS28J1A01412` | ✅ OK |
| 14 | **Elgato Wave:3** — Controls Interface | `0070` | `MI_03` | ✅ OK |
| 15 | **Elgato Wave:3** — DFU Interface | `0070` | `MI_04` | ✅ OK |

**Elgato device breakdown:**
- 🎛️ Stream Deck + (1 unit) — PID `0084`
- 🎛️ Stream Deck XL (1 unit) — PID `008A`
- 🎛️ Stream Deck MK.2 (1 unit) — PID `0078`
- 🎛️ Stream Deck Mini (2 units) — PID `006C`
- 🎙️ Elgato Wave:3 Microphone (1 unit) — PID `0070`

> **Correction (2026-03-07):** Devices with PID `006C` were initially misidentified as Stream Deck Pedals. The Stream Deck Pedal uses PID `0086`, which is **not present** on this system. PID `006C` with serial prefix `CL13K` is confirmed **Stream Deck Mini**.

---

## 🖱️ HID Devices by Vendor (84 total)

| Vendor ID | Brand | Devices Detected |
|---|---|---|
| `0FD9` | Elgato | HID Consumer, HID Vendor-defined (×5) |
| `046D` | Logitech | Download Assistant |
| `1532` | Razer | BlackShark V2 Pro (wireless headset) |
| `05AC` | Apple | USB Precision Touchpad (user-mode) |
| `256F` | 3Dconnexion | SpaceMouse — KMJ Emulator + Wireless Device |
| `256C` | HUION | HUION HID (drawing tablet) |
| `0B05` | ASUS | (onboard HID / AURA) |
| `2E1A` / `514C` | Unknown | Misc HID composite interfaces |
| —     | Microsoft | Input Configuration Device |
| —     | Bluetooth | BT HID, BT LE GATT HID, XINPUT-compatible |

**HID categories found:**
- 🎮 Game controllers (HID-compliant)
- ✍️ Digitizer / pen / stylus (HUION tablet)
- 👆 Touch screen + touch pad
- 🖱️ Multi-axis controller (3Dconnexion SpaceMouse)
- 🔊 Consumer control (volume/media keys)
- ⚙️ System controller / multi-axis

---

## ⚠️ Problem Devices (ErrorCode 22 = Disabled)

| Device | Class | Error Code | Meaning |
|---|---|---|---|
| Intel® Ethernet Controller X550 | Net | 22 | ❌ Disabled (not broken) |
| VMware Virtual Ethernet Adapter for VMnet1 | Net | 22 | ❌ Disabled (VMware not running) |
| VMware Virtual Ethernet Adapter for VMnet8 | Net | 22 | ❌ Disabled (VMware not running) |
| Bluetooth Device (Personal Area Network) #4 | Net | 22 | ❌ Disabled |

> **ErrorCode 22** = "This device is disabled." — these adapters were manually disabled or are inactive because VMware / Bluetooth PAN services are not in use. **No driver corruption or hardware fault.**

---

## 🔍 Full Vendor ID Map (13 unique vendors)

| VID | Brand | Category |
|---|---|---|
| `046D` | Logitech | Peripherals |
| `04D8` | Microchip Technology | Embedded / misc HID |
| `05AC` | Apple | Touchpad |
| `05E3` | Genesys Logic | USB Hubs |
| `0B05` | ASUS | Motherboard / RGB controllers |
| `0FD9` | Elgato | StreamDecks, Wave:3 |
| `1532` | Razer | Audio (BlackShark V2 Pro) |
| `17E9` | DisplayLink | Video adapters |
| `2109` | VIA Labs | USB Hubs |
| `256C` | HUION | Drawing tablet |
| `256F` | 3Dconnexion | SpaceMouse |
| `2E1A` | Unknown | — |
| `514C` | Unknown | — |

---

## 🗂️ Device Class Breakdown

```
USB/HID Device Class Distribution (125 total)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HIDClass   ████████████████████████████████████  84  (67.2%)
USB        ████████████████████               39  (31.2%)
USBDevice  █                                   2  ( 1.6%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🛠️ Auto-Fix Actions This Run

| Step | Action | Result |
|---|---|---|
| USB scan | Detected all 125 devices via CIM | ✅ |
| StreamDeck check | Hardware found (15 interfaces, all OK) | ✅ |
| Software check | StreamDeck software already running | ✅ No action needed |
| pnputil rescan | Not triggered (hardware found immediately) | — |
| Report write | Appended to `usb_health_log.txt` + `.json` | ✅ |

---

## 📁 Log Files

| File | Path |
|---|---|
| Text log (human readable) | `%APPDATA%\USBHealthChecker\usb_health_log.txt` |
| JSON log (machine readable, 30-day rolling) | `%APPDATA%\USBHealthChecker\usb_health_log.json` |
| Scheduled Task | `USBStreamDeckHealthCheck` → runs at every logon |

---

## 🔄 Startup Behaviour (every boot)

```
LOGON
  └─► Scheduled Task: USBStreamDeckHealthCheck
        └─► Check-USBDevices.ps1
              ├── Scan USB/HID via CIM (fast, no remoting)
              ├── Detect Elgato/StreamDeck by VID_0FD9
              ├── If missing → pnputil /scan-devices → re-check
              ├── If SW dead  → kill + relaunch StreamDeck.exe
              ├── Compute HealthScore / HealthRatio / StabilityIndex
              └── Append report → usb_health_log.txt + .json
```

---

*Report auto-generated by `Check-USBDevices.ps1` — GitHub Copilot CLI*

# USB Device Diagnostic Script
# Purpose: Scan and test all USB devices, show status with colors, provide fix suggestions
# Place: C:\projects\workstation\6_Symbols\startup\desktopscripts\
# Run at Windows startup via Task Scheduler or Startup folder

$ErrorActionPreference = "Continue"

# ─────────────────────────────────────────────
# Emoji helpers (Unicode safe on Windows)
# ─────────────────────────────────────────────
$ico = @{
    USB     = [System.Char]::ConvertFromUtf32(0x1F50C)  # Electric plug
    OK      = [System.Char]::ConvertFromUtf32(0x2705)   # Green check
    WARN    = [System.Char]::ConvertFromUtf32(0x26A0)   # Warning
    ERR     = [System.Char]::ConvertFromUtf32(0x1F534)  # Red circle
    FIX     = [System.Char]::ConvertFromUtf32(0x1F527)  # Wrench
    INFO    = [System.Char]::ConvertFromUtf32(0x2139)   # Info
    SCAN    = [System.Char]::ConvertFromUtf32(0x1F50D)  # Magnifier
    HUB     = [System.Char]::ConvertFromUtf32(0x1F4E1)  # Satellite / hub
    DRIVE   = [System.Char]::ConvertFromUtf32(0x1F4BE)  # Floppy / drive
    CAMERA  = [System.Char]::ConvertFromUtf32(0x1F4F7)  # Camera
    AUDIO   = [System.Char]::ConvertFromUtf32(0x1F3A7)  # Headphones
    HID     = [System.Char]::ConvertFromUtf32(0x2328)   # Keyboard
    ROCKET  = [System.Char]::ConvertFromUtf32(0x1F680)  # Rocket
    SPARKLE = [System.Char]::ConvertFromUtf32(0x2728)   # Sparkles
    STOP    = [System.Char]::ConvertFromUtf32(0x1F6D1)  # Stop sign
    CLOCK   = [System.Char]::ConvertFromUtf32(0x23F0)   # Alarm clock
    SKULL   = [System.Char]::ConvertFromUtf32(0x1F480)  # Missing / not found
    GHOST   = [System.Char]::ConvertFromUtf32(0x1F47B)  # Unknown
}

# ─────────────────────────────────────────────
# Counters
# ─────────────────────────────────────────────
$stats = @{ OK = 0; Warn = 0; Error = 0; Total = 0 }

# ─────────────────────────────────────────────
# Helper: Write-Status
# ─────────────────────────────────────────────
function Write-Status {
    param(
        [string]$Emoji,
        [string]$Label,
        [string]$Message,
        [string]$Color = "Gray"
    )
    $pad = $Label.PadRight(28)
    Write-Host "$Emoji  $pad" -NoNewline -ForegroundColor $Color
    Write-Host $Message -ForegroundColor White
}

# ─────────────────────────────────────────────
# Helper: Write-FixSuggestion
# ─────────────────────────────────────────────
function Write-FixSuggestion {
    param([string[]]$Steps)
    foreach ($step in $Steps) {
        Write-Host "     $($ico.FIX)  $step" -ForegroundColor DarkYellow
    }
}

# ─────────────────────────────────────────────
# Helper: Get device icon by class
# ─────────────────────────────────────────────
function Get-DeviceIcon {
    param([string]$Class, [string]$Name)
    $Name = $Name.ToLower()
    if ($Class -match "USB" -or $Name -match "hub")              { return $ico.HUB }
    if ($Class -match "DiskDrive" -or $Name -match "disk|drive|storage") { return $ico.DRIVE }
    if ($Class -match "Camera" -or $Name -match "camera|webcam") { return $ico.CAMERA }
    if ($Class -match "AudioEndpoint" -or $Name -match "audio|headset|mic|sound") { return $ico.AUDIO }
    if ($Class -match "HIDClass" -or $Name -match "keyboard|mouse|trackpad|hid") { return $ico.HID }
    return $ico.USB
}

# ─────────────────────────────────────────────
# Helper: Get fix steps based on error / status
# ─────────────────────────────────────────────
function Get-FixSteps {
    param([string]$Status, [string]$DeviceName, [string]$ErrorCode)
    $fixes = @()

    switch -Regex ($Status) {
        "Error" {
            $fixes += "Right-click the device in Device Manager > 'Update driver'"
            $fixes += "Right-click > 'Uninstall device', then replug the USB cable"
            $fixes += "Try a different USB port (prefer USB 3.0 blue ports)"
            $fixes += "Run: 'devmgmt.msc' and look for yellow exclamation marks"
        }
        "Unknown" {
            $fixes += "Unplug and replug the device"
            $fixes += "Check if the device needs a driver: visit manufacturer's website"
            $fixes += "Open Device Manager > Action > Scan for hardware changes"
        }
        "Degraded" {
            $fixes += "Run: 'usbview.exe' (USB Device Viewer) to check connection speed"
            $fixes += "Device may be running at USB 2.0 speed on a USB 3.0 port — try a different port"
            $fixes += "Replace the USB cable; damaged cables cause speed degradation"
        }
        "Not Present" {
            $fixes += "Device driver is installed but hardware is disconnected"
            $fixes += "Replug the device or check the cable"
            $fixes += "Run: 'pnputil /enum-devices /problem' to list all problem devices"
        }
    }

    # Extra fix if ErrorCode is known
    switch ($ErrorCode) {
        "43" {
            $fixes += "Code 43: Windows stopped the device — uninstall driver, reboot, replug"
            $fixes += "Run: 'devmgmt.msc' > right-click > Properties > Error Code 43"
        }
        "10" {
            $fixes += "Code 10: Device cannot start — reinstall driver from manufacturer site"
        }
        "28" {
            $fixes += "Code 28: No driver installed — download driver from manufacturer"
        }
        "45" {
            $fixes += "Code 45: Currently not connected — replug the device and rescan"
        }
    }

    return $fixes
}

# ─────────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  $($ico.ROCKET) ══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "       USB DEVICE DIAGNOSTIC  -  $(Get-Date -Format 'yyyy-MM-dd  HH:mm:ss')" -ForegroundColor Cyan
Write-Host "  $($ico.ROCKET) ══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Computer : $env:COMPUTERNAME   User: $env:USERNAME" -ForegroundColor DarkGray
Write-Host ""

# ─────────────────────────────────────────────
# SECTION 1 — USB Controllers
# ─────────────────────────────────────────────
Write-Host "  $($ico.SCAN) ─── USB CONTROLLERS ──────────────────────────────────" -ForegroundColor Magenta
Write-Host ""

$controllers = Get-PnpDevice -Class "USB" -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -match "controller|host|xhci|ehci|ohci|uhci" }

if (-not $controllers) {
    Write-Host "  $($ico.WARN)  No USB controllers found (requires admin rights)" -ForegroundColor Yellow
} else {
    foreach ($ctrl in ($controllers | Sort-Object FriendlyName)) {
        $stats.Total++
        $icon = Get-DeviceIcon -Class $ctrl.Class -Name $ctrl.FriendlyName

        if ($ctrl.Status -eq "OK") {
            $stats.OK++
            Write-Status -Emoji $ico.OK -Label $ctrl.FriendlyName -Message "OK" -Color Green
        } elseif ($ctrl.Status -match "Warn|Degraded") {
            $stats.Warn++
            Write-Status -Emoji $ico.WARN -Label $ctrl.FriendlyName -Message "WARNING — $($ctrl.Status)" -Color Yellow
            Write-FixSuggestion -Steps (Get-FixSteps -Status $ctrl.Status -DeviceName $ctrl.FriendlyName -ErrorCode "")
        } else {
            $stats.Error++
            Write-Status -Emoji $ico.ERR -Label $ctrl.FriendlyName -Message "ERROR — $($ctrl.Status)" -Color Red
            Write-FixSuggestion -Steps (Get-FixSteps -Status $ctrl.Status -DeviceName $ctrl.FriendlyName -ErrorCode "")
        }
    }
}

Write-Host ""

# ─────────────────────────────────────────────
# SECTION 2 — All USB-connected Devices
# ─────────────────────────────────────────────
Write-Host "  $($ico.SCAN) ─── CONNECTED USB DEVICES ─────────────────────────────" -ForegroundColor Magenta
Write-Host ""

# Pull all devices that have a USB instance path (physically on USB bus)
$allDevices = Get-PnpDevice -ErrorAction SilentlyContinue |
    Where-Object {
        $_.InstanceId -like "USB\*" -or
        $_.InstanceId -like "USBSTOR\*" -or
        $_.InstanceId -like "USBPRINT\*" -or
        $_.InstanceId -like "USBHUB\*" -or
        $_.InstanceId -like "USBXHCI\*"
    } |
    Sort-Object Status, FriendlyName

if (-not $allDevices) {
    Write-Host "  $($ico.WARN)  No USB devices detected (try running as Administrator)" -ForegroundColor Yellow
} else {
    foreach ($dev in $allDevices) {
        $stats.Total++
        $devIcon = Get-DeviceIcon -Class $dev.Class -Name $dev.FriendlyName
        $name = if ($dev.FriendlyName) { $dev.FriendlyName } else { $dev.InstanceId }

        # Try to get error code from device properties
        $errorCode = ""
        try {
            $props = Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName "DEVPKEY_Device_ProblemCode" -ErrorAction SilentlyContinue
            if ($props -and $props.Data -and $props.Data -ne 0) {
                $errorCode = "$($props.Data)"
            }
        } catch {}

        $suffix = if ($errorCode) { "  [Code $errorCode]" } else { "" }

        if ($dev.Status -eq "OK") {
            $stats.OK++
            Write-Status -Emoji "$devIcon" -Label $name -Message "OK" -Color Green
        } elseif ($dev.Status -match "Warn|Degraded") {
            $stats.Warn++
            Write-Status -Emoji $ico.WARN -Label $name -Message "WARNING — $($dev.Status)$suffix" -Color Yellow
            Write-FixSuggestion -Steps (Get-FixSteps -Status $dev.Status -DeviceName $name -ErrorCode $errorCode)
        } elseif ($dev.Status -eq "Unknown") {
            $stats.Warn++
            Write-Status -Emoji $ico.GHOST -Label $name -Message "UNKNOWN STATUS$suffix" -Color DarkYellow
            Write-FixSuggestion -Steps (Get-FixSteps -Status "Unknown" -DeviceName $name -ErrorCode $errorCode)
        } elseif ($dev.Status -eq "Not Present") {
            # Not connected now — skip silent, only show if verbose needed
            # Skip to avoid noise from historical devices
            $stats.Total--
        } else {
            $stats.Error++
            Write-Status -Emoji $ico.ERR -Label $name -Message "ERROR — $($dev.Status)$suffix" -Color Red
            Write-FixSuggestion -Steps (Get-FixSteps -Status $dev.Status -DeviceName $name -ErrorCode $errorCode)
        }
    }
}

Write-Host ""

# ─────────────────────────────────────────────
# SECTION 3 — USB Event Log (last boot)
# ─────────────────────────────────────────────
Write-Host "  $($ico.SCAN) ─── USB EVENTS (last 30 minutes) ──────────────────────" -ForegroundColor Magenta
Write-Host ""

$cutoff = (Get-Date).AddMinutes(-30)
$usbEvents = Get-WinEvent -LogName System -ErrorAction SilentlyContinue |
    Where-Object {
        $_.TimeCreated -gt $cutoff -and
        ($_.Message -like "*USB*" -or $_.Message -like "*UsbHub*" -or $_.Message -like "*USBSTOR*")
    } |
    Select-Object -First 10

if ($usbEvents) {
    foreach ($ev in $usbEvents) {
        $time = $ev.TimeCreated.ToString("HH:mm:ss")
        $short = if ($ev.Message.Length -gt 90) { $ev.Message.Substring(0, 90) + "..." } else { $ev.Message }
        if ($ev.LevelDisplayName -match "Error") {
            Write-Host "  $($ico.ERR)  [$time] $short" -ForegroundColor Red
        } elseif ($ev.LevelDisplayName -match "Warning") {
            Write-Host "  $($ico.WARN)  [$time] $short" -ForegroundColor Yellow
        } else {
            Write-Host "  $($ico.INFO)  [$time] $short" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  $($ico.OK)  No USB-related system events in the last 30 minutes" -ForegroundColor Green
}

Write-Host ""

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
Write-Host "  $($ico.SPARKLE) ─── SUMMARY ──────────────────────────────────────────" -ForegroundColor Cyan
Write-Host ""

$okLine   = "  OK      : $($stats.OK)"
$warnLine = "  Warnings: $($stats.Warn)"
$errLine  = "  Errors  : $($stats.Error)"
$totLine  = "  Total   : $($stats.Total)"

Write-Host $okLine   -ForegroundColor Green
Write-Host $warnLine -ForegroundColor Yellow
Write-Host $errLine  -ForegroundColor Red
Write-Host $totLine  -ForegroundColor Cyan

Write-Host ""

if ($stats.Error -gt 0) {
    Write-Host "  $($ico.ERR)  ACTION REQUIRED — $($stats.Error) device(s) have errors." -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($ico.FIX)  QUICK FIX GUIDE:" -ForegroundColor DarkYellow
    Write-Host "     1. Open Device Manager  :  Win + X > Device Manager" -ForegroundColor DarkYellow
    Write-Host "     2. Look for red/yellow   :  Right-click > Update driver" -ForegroundColor DarkYellow
    Write-Host "     3. Replug the device     :  Use a different USB port" -ForegroundColor DarkYellow
    Write-Host "     4. Run USB troubleshooter:  Settings > Troubleshoot > Hardware" -ForegroundColor DarkYellow
    Write-Host "     5. Check USB power       :  Device Manager > USB Root Hub >" -ForegroundColor DarkYellow
    Write-Host "                                 Properties > Power Management tab" -ForegroundColor DarkYellow
    Write-Host "     6. Run as Admin          :  Some errors only show with elevated rights" -ForegroundColor DarkYellow
} elseif ($stats.Warn -gt 0) {
    Write-Host "  $($ico.WARN)  ADVISORY — $($stats.Warn) device(s) may need attention." -ForegroundColor Yellow
} else {
    Write-Host "  $($ico.OK)  All USB devices are healthy!" -ForegroundColor Green
}

Write-Host ""
Write-Host "  $($ico.CLOCK)  Completed at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor DarkGray
Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Press Enter to close..." -ForegroundColor DarkGray
Read-Host | Out-Null

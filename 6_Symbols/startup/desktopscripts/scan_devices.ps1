<#
.SYNOPSIS
    Scans all hardware devices and their current states on the local machine.
    Designed for Stream Deck launch - window always stays open on error or completion.

.DESCRIPTION
    Uses Get-PnpDevice and CIM to enumerate all devices across categories,
    reporting status, driver problem codes, disk health, network adapters,
    battery, and device-related System event log errors (last 24h).
    Run as Administrator for full access.
#>

# ── Error trap - window NEVER auto-closes ──────────────────────────────────────
$ErrorActionPreference = "Continue"
trap {
    Write-Host ""
    Write-Host "  !! SCRIPT ERROR - LINE $($_.InvocationInfo.ScriptLineNumber) !!" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ("  Line: " + $_.InvocationInfo.Line.Trim()) -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "  Press any key to close..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

$originalTitle = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle = "Windows Device State Scanner"

# ── Helpers ────────────────────────────────────────────────────────────────────

Function Write-Header {
    param ([string]$Text)
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor White
    Write-Host "================================================================================" -ForegroundColor Cyan
}

Function Write-SubHeader {
    param ([string]$Text)
    Write-Host ""
    Write-Host "  ── $Text ──" -ForegroundColor DarkCyan
}

$PnpErrorCodes = @{
    1  = "Device not configured correctly"
    3  = "Driver corrupted or missing"
    10 = "Device cannot start"
    12 = "Cannot find enough free resources"
    14 = "Restart required to finish changes"
    16 = "Cannot identify all resources used"
    18 = "Reinstall the drivers"
    19 = "Registry corrupted"
    21 = "Windows is removing device"
    22 = "Device disabled (manually)"
    24 = "Device not present / working"
    28 = "Drivers not installed"
    29 = "Device disabled (firmware)"
    31 = "Not working properly - no driver loaded"
    32 = "Driver service disabled"
    33 = "Cannot determine resources"
    34 = "Cannot select settings"
    35 = "BIOS missing required resources"
    36 = "IRQ resource conflict"
    37 = "Driver returned failure"
    38 = "Driver loaded - prior instance still in memory"
    39 = "Driver missing or corrupted"
    40 = "Service key missing"
    41 = "Driver loaded but device not found"
    42 = "Duplicate device"
    43 = "Device reported failure"
    44 = "Application blocked the driver"
    45 = "Device not present (daemon)"
    46 = "Device not available at boot"
    47 = "Device cannot start (powering off)"
    48 = "Driver blocked - compatibility issue"
    49 = "Registry too large - device hidden"
    52 = "Driver is unsigned"
    54 = "Device failed and will be reset"
}

# ── Main Scan ──────────────────────────────────────────────────────────────────

Clear-Host
Write-Header "Windows Device State Scanner"
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  [1/4] Reading PnP devices..." -ForegroundColor DarkGray
$allDevices = Get-PnpDevice -PresentOnly:$false -ErrorAction SilentlyContinue | Sort-Object Class, FriendlyName

Write-Host "  [2/4] Reading WMI device data..." -ForegroundColor DarkGray
$wmiEntities = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue

Write-Host "  [3/4] Reading System event log (last 24h)..." -ForegroundColor DarkGray
$StartDate = (Get-Date).AddHours(-24)
$deviceSources = "disk|storage|driver|pci|usb|acpi|nvme|scsi|ata|net|ndis|i8042|hid|bluetooth|audio|volsnap|iaStorV|cdrom"
$deviceEvents = Get-EventLog -LogName System -After $StartDate -EntryType Error,Warning -ErrorAction SilentlyContinue |
    Where-Object { $_.Source -match $deviceSources }

Write-Host "  [4/4] Building report..." -ForegroundColor DarkGray

# ── Section 1: Status Summary ──────────────────────────────────────────────────

$ok       = @($allDevices | Where-Object { $_.Status -eq "OK" })
$errors   = @($allDevices | Where-Object { $_.Status -eq "Error" })
$unknown  = @($allDevices | Where-Object { $_.Status -eq "Unknown" })
$disabled = @($allDevices | Where-Object { $_.Status -eq "Disabled" })
$other    = @($allDevices | Where-Object { $_.Status -notin @("OK","Error","Unknown","Disabled") })

Write-Header "Device Status Summary"
Write-Host "  Total Devices   : $($allDevices.Count)" -ForegroundColor White
Write-Host "  OK              : $($ok.Count)"          -ForegroundColor Green
Write-Host "  Error           : $($errors.Count)"      -ForegroundColor $(if ($errors.Count  -gt 0) { "Red"    } else { "Green" })
Write-Host "  Disabled        : $($disabled.Count)"    -ForegroundColor $(if ($disabled.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Unknown         : $($unknown.Count)"     -ForegroundColor Gray
if ($other.Count -gt 0) {
    Write-Host "  Other           : $($other.Count)"   -ForegroundColor DarkYellow
}

# ── Section 2: Devices with Errors ────────────────────────────────────────────

Write-Header "Devices with Errors / Problems"

if ($errors.Count -eq 0) {
    Write-Host "  [OK] No devices in error state." -ForegroundColor Green
} else {
    foreach ($dev in $errors) {
        $wmiDev   = $wmiEntities | Where-Object { $_.DeviceID -eq $dev.DeviceID } | Select-Object -First 1
        $code     = [int]($wmiDev.ConfigManagerErrorCode)
        $codeDesc = if ($PnpErrorCodes.ContainsKey($code)) { $PnpErrorCodes[$code] } else { "Unknown problem (code $code)" }
        $name     = if ($dev.FriendlyName) { $dev.FriendlyName } else { "(Unnamed)" }

        Write-Host ""
        Write-Host "  [ERROR] $name" -ForegroundColor Red
        Write-Host "          Class    : $($dev.Class)" -ForegroundColor DarkGray
        Write-Host "          DeviceID : $($dev.DeviceID)" -ForegroundColor DarkGray
        Write-Host "          Problem  : [Code $code] $codeDesc" -ForegroundColor Yellow
    }
}

# ── Section 3: Disabled Devices ───────────────────────────────────────────────

Write-Header "Disabled Devices"

if ($disabled.Count -eq 0) {
    Write-Host "  [OK] No disabled devices." -ForegroundColor Green
} else {
    foreach ($dev in ($disabled | Sort-Object Class, FriendlyName)) {
        $name = if ($dev.FriendlyName) { $dev.FriendlyName } else { "(Unnamed)" }
        Write-Host "  [DISABLED] [$($dev.Class.PadRight(22))] $name" -ForegroundColor Yellow
    }
}

# ── Section 4: All Devices by Category ────────────────────────────────────────

Write-Header "All Devices by Category"

$grouped = $allDevices | Group-Object Class | Sort-Object Name

foreach ($group in $grouped) {
    $className = if ([string]::IsNullOrWhiteSpace($group.Name)) { "(Uncategorized)" } else { $group.Name }
    Write-SubHeader "$className  [$($group.Count)]"

    foreach ($dev in ($group.Group | Sort-Object FriendlyName)) {
        $status = $dev.Status
        $color  = switch ($status) {
            "OK"       { "Green"      }
            "Error"    { "Red"        }
            "Disabled" { "Yellow"     }
            "Unknown"  { "Gray"       }
            default    { "DarkYellow" }
        }
        $name = if ($dev.FriendlyName) { $dev.FriendlyName } else { "(Unnamed)" }
        Write-Host "    [$($status.PadRight(10))] $name" -ForegroundColor $color
    }
}

# ── Section 5: Disk & Volume Health ───────────────────────────────────────────

Write-Header "Disk & Volume Health"

$disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
if ($disks) {
    Write-SubHeader "Physical Disks"
    foreach ($disk in $disks) {
        $health = $disk.HealthStatus
        $op     = $disk.OperationalStatus
        $color  = if ($health -eq "Healthy") { "Green" } elseif ($health -eq "Warning") { "Yellow" } else { "Red" }
        $size   = [math]::Round($disk.Size / 1GB, 1)
        Write-Host "  [$($health.PadRight(10))] [$($op.PadRight(12))] $($disk.FriendlyName) - $size GB  [$($disk.MediaType)]" -ForegroundColor $color
    }
} else {
    Write-Host "  [--] Could not read physical disk data." -ForegroundColor Gray
}

$volumes = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -ne "CD-ROM" -and $null -ne $_.DriveLetter }
if ($volumes) {
    Write-SubHeader "Volumes"
    foreach ($vol in ($volumes | Sort-Object DriveLetter)) {
        $health = $vol.HealthStatus
        $color  = if ($health -eq "Healthy") { "Green" } elseif ($health -eq "Warning") { "Yellow" } else { "Red" }
        $free   = [math]::Round($vol.SizeRemaining / 1GB, 1)
        $total  = [math]::Round($vol.Size / 1GB, 1)
        $label  = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "No Label" }
        Write-Host "  [$($health.PadRight(10))] $($vol.DriveLetter):\ [$label] - $free GB free of $total GB  [$($vol.FileSystem)]" -ForegroundColor $color
    }
}

# ── Section 6: Network Adapters ───────────────────────────────────────────────

Write-Header "Network Adapter States"

$netAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Sort-Object Name
if ($netAdapters) {
    foreach ($nic in $netAdapters) {
        $status = $nic.Status
        $color  = switch ($status) {
            "Up"           { "Green"  }
            "Disconnected" { "Yellow" }
            "Disabled"     { "Gray"   }
            default        { "Red"    }
        }
        $speed = if ($nic.LinkSpeed) { "  @ $($nic.LinkSpeed)" } else { "" }
        Write-Host "  [$($status.PadRight(13))] $($nic.Name.PadRight(28)) $($nic.InterfaceDescription)$speed" -ForegroundColor $color
    }
} else {
    Write-Host "  [--] No network adapters found." -ForegroundColor Gray
}

# ── Section 7: Battery (laptops only) ─────────────────────────────────────────

$batteries = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
if ($batteries) {
    Write-Header "Battery Status"
    $batStatusMap = @{
        1="Other"; 2="Unknown"; 3="Fully Charged"; 4="Low"; 5="Critical"
        6="Charging"; 7="Charging+High"; 8="Charging+Low"; 9="Charging+Critical"
        10="Undefined"; 11="Partially Charged"
    }
    foreach ($bat in $batteries) {
        $charge    = $bat.EstimatedChargeRemaining
        $color     = if ($charge -ge 50) { "Green" } elseif ($charge -ge 20) { "Yellow" } else { "Red" }
        $batStatus = $batStatusMap[[int]$bat.BatteryStatus]
        Write-Host "  [$batStatus]  Charge: $charge%   Runtime: ~$($bat.EstimatedRunTime) min" -ForegroundColor $color
    }
}

# ── Section 8: Recent Device-Related System Events ────────────────────────────

Write-Header "Device-Related System Events (Last 24h)"

if (-not $deviceEvents -or $deviceEvents.Count -eq 0) {
    Write-Host "  [OK] No device-related errors or warnings found." -ForegroundColor Green
} else {
    $deviceEvents | Sort-Object TimeGenerated -Descending | Select-Object -First 30 | ForEach-Object {
        $color = if ($_.EntryType -eq "Error") { "Red" } else { "Yellow" }
        $time  = $_.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
        $msg   = ($_.Message -replace "[\r\n]+"," ").Trim()
        if ($msg.Length -gt 120) { $msg = $msg.Substring(0,120) + "..." }
        Write-Host "  [$time] [$($_.EntryType.ToString().PadRight(7))] [$($_.Source)]" -ForegroundColor $color
        Write-Host "           $msg" -ForegroundColor Gray
    }
}

# ── Footer ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  Scan complete - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Press 'E' to export CSV to Desktop, any other key to close." -ForegroundColor Cyan
Write-Host ""

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if ($key.Character -eq 'e' -or $key.Character -eq 'E') {
    try {
        $timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
        $exportPath = "$env:USERPROFILE\Desktop\DeviceScan_$timestamp.csv"
        $allDevices | Select-Object FriendlyName, Class, Status, DeviceID |
            Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
        Write-Host "  [EXPORTED] $exportPath" -ForegroundColor Green
    } catch {
        Write-Host "  [EXPORT ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  Press any key to close..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

$Host.UI.RawUI.WindowTitle = $originalTitle
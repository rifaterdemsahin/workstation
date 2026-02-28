# Reset-StreamDeck.ps1
# Kills Stream Deck, sets LG as primary monitor, restarts Stream Deck

# ── 1. Kill Stream Deck ────────────────────────────────────────────────────────
Write-Host "Stopping Stream Deck..." -ForegroundColor Yellow

$sdProcesses = Get-Process | Where-Object { $_.Name -like "*StreamDeck*" }

if ($sdProcesses) {
    $sdProcesses | ForEach-Object {
        Write-Host "   Killing: $($_.Name) (PID $($_.Id))"
        Stop-Process -Id $_.Id -Force
    }
    Start-Sleep -Seconds 2
    Write-Host "   Stream Deck stopped." -ForegroundColor Green
} else {
    Write-Host "   Stream Deck was not running." -ForegroundColor Cyan
}

# ── 2. Load C# display helper via Add-Type ────────────────────────────────────
Write-Host ""
Write-Host "Loading display helper..." -ForegroundColor Yellow

$src = @'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class DisplayHelper {

    [DllImport("user32.dll")]
    public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

    [DllImport("user32.dll")]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE lpDevMode, IntPtr hwnd, uint dwflags, IntPtr lParam);

    public const int  ENUM_CURRENT_SETTINGS         = -1;
    public const uint CDS_SET_PRIMARY               = 0x00000010;
    public const uint CDS_UPDATEREGISTRY            = 0x00000001;
    public const uint CDS_NORESET                   = 0x10000000;
    public const uint EDD_GET_DEVICE_INTERFACE_NAME = 0x00000001;
    public const uint DISPLAY_DEVICE_ATTACHED       = 0x00000001;
    public const uint DISPLAY_DEVICE_ACTIVE         = 0x00000001;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DISPLAY_DEVICE {
        public uint cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]  public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public uint StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public uint  dmFields;
        public int   dmPositionX, dmPositionY;
        public uint  dmDisplayOrientation, dmDisplayFixedOutput;
        public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels;
        public uint  dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
        public uint  dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2;
        public uint  dmPanningWidth, dmPanningHeight;
    }

    // Returns: "DISPLAY_NAME|ADAPTER_STRING|MONITOR_STRING|MONITOR_ID|MONITOR_INTERFACE"
    public static List<string> GetAllMonitors() {
        var list = new List<string>();
        var adapter = new DISPLAY_DEVICE();
        adapter.cb  = (uint)Marshal.SizeOf(adapter);

        for (uint i = 0; EnumDisplayDevices(null, i, ref adapter, 0); i++) {
            if ((adapter.StateFlags & DISPLAY_DEVICE_ACTIVE) != 0) {
                // Enumerate monitors attached to this adapter
                var monitor = new DISPLAY_DEVICE();
                monitor.cb  = (uint)Marshal.SizeOf(monitor);

                for (uint j = 0; EnumDisplayDevices(adapter.DeviceName, j, ref monitor, EDD_GET_DEVICE_INTERFACE_NAME); j++) {
                    list.Add(
                        adapter.DeviceName  + "|" +
                        adapter.DeviceString + "|" +
                        monitor.DeviceString + "|" +
                        monitor.DeviceID     + "|" +
                        monitor.DeviceName
                    );
                    monitor    = new DISPLAY_DEVICE();
                    monitor.cb = (uint)Marshal.SizeOf(monitor);
                }
            }
            adapter    = new DISPLAY_DEVICE();
            adapter.cb = (uint)Marshal.SizeOf(adapter);
        }
        return list;
    }

    public static int SetAsPrimary(string deviceName) {
        var dm    = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(dm);
        if (!EnumDisplaySettings(deviceName, ENUM_CURRENT_SETTINGS, ref dm)) return -99;

        int offsetX = dm.dmPositionX;
        int offsetY = dm.dmPositionY;

        dm.dmPositionX = 0;
        dm.dmPositionY = 0;
        dm.dmFields    = 0x00000020; // DM_POSITION
        ChangeDisplaySettingsEx(deviceName, ref dm, IntPtr.Zero,
            CDS_SET_PRIMARY | CDS_UPDATEREGISTRY | CDS_NORESET, IntPtr.Zero);

        var dd2   = new DISPLAY_DEVICE();
        dd2.cb    = (uint)Marshal.SizeOf(dd2);
        for (uint i = 0; EnumDisplayDevices(null, i, ref dd2, 0); i++) {
            if ((dd2.StateFlags & DISPLAY_DEVICE_ACTIVE) != 0 && dd2.DeviceName != deviceName) {
                var dm2    = new DEVMODE();
                dm2.dmSize = (short)Marshal.SizeOf(dm2);
                if (EnumDisplaySettings(dd2.DeviceName, ENUM_CURRENT_SETTINGS, ref dm2)) {
                    dm2.dmPositionX -= offsetX;
                    dm2.dmPositionY -= offsetY;
                    dm2.dmFields     = 0x00000020;
                    ChangeDisplaySettingsEx(dd2.DeviceName, ref dm2, IntPtr.Zero,
                        CDS_UPDATEREGISTRY | CDS_NORESET, IntPtr.Zero);
                }
            }
            dd2    = new DISPLAY_DEVICE();
            dd2.cb = (uint)Marshal.SizeOf(dd2);
        }

        var empty    = new DEVMODE();
        empty.dmSize = (short)Marshal.SizeOf(empty);
        return ChangeDisplaySettingsEx(null, ref empty, IntPtr.Zero, 0, IntPtr.Zero);
    }
}
'@

Add-Type -TypeDefinition $src -Language CSharp

# ── 3. Detect LG and set as primary ──────────────────────────────────────────
Write-Host "Detecting monitors..." -ForegroundColor Yellow

$monitors  = [DisplayHelper]::GetAllMonitors()
$lgDevice  = $null
$lgLabel   = $null

Write-Host ""
Write-Host "   {DISPLAY}        {ADAPTER}                  {MONITOR NAME}              {MONITOR ID}" -ForegroundColor DarkGray
Write-Host "   " + ("-" * 100) -ForegroundColor DarkGray

foreach ($m in $monitors) {
    $parts       = $m -split "\|"
    $dispName    = $parts[0].Trim()   # \\.\DISPLAY1
    $adapterStr  = $parts[1].Trim()   # AMD Radeon RX 6900 XT
    $monitorStr  = $parts[2].Trim()   # e.g. LG ULTRAGEAR
    $monitorId   = $parts[3].Trim()   # MONITOR\LGE...
    $monitorIface= $parts[4].Trim()   # \\.\DISPLAY1\Monitor0

    Write-Host "   $dispName   $adapterStr   $monitorStr   $monitorId"

    if (($monitorStr -match "LG") -or ($monitorId -match "LG") -or ($monitorId -match "GSM")) {
        $lgDevice = $dispName
        $lgLabel  = if ($monitorStr -ne "") { $monitorStr } else { $monitorId }
    }
}

Write-Host ""

if ($lgDevice) {
    Write-Host "LG monitor found: $lgLabel ($lgDevice)" -ForegroundColor Green
    Write-Host "Setting as primary display..." -ForegroundColor Yellow

    $result = [DisplayHelper]::SetAsPrimary($lgDevice)

    switch ($result) {
        0       { Write-Host "LG is now the primary display." -ForegroundColor Green }
        1       { Write-Host "Primary display set - restart Windows to fully apply." -ForegroundColor Yellow }
        default { Write-Host "ChangeDisplaySettingsEx returned: $result" -ForegroundColor Red }
    }
} else {
    Write-Host "No LG monitor detected automatically." -ForegroundColor Red
    Write-Host ""
    Write-Host ">>> ACTION NEEDED: Look at the monitor list above and set LG_DISPLAY_OVERRIDE below." -ForegroundColor Yellow
    Write-Host "    Example: Set LG_DISPLAY_OVERRIDE = '\\.\DISPLAY2' if that is your LG." -ForegroundColor Yellow

    # Manual override - set this if auto-detect fails
    $LG_DISPLAY_OVERRIDE = ""   # <-- e.g. "\\.\DISPLAY2"

    if ($LG_DISPLAY_OVERRIDE -ne "") {
        Write-Host ""
        Write-Host "Using manual override: $LG_DISPLAY_OVERRIDE" -ForegroundColor Cyan
        $result = [DisplayHelper]::SetAsPrimary($LG_DISPLAY_OVERRIDE)
        switch ($result) {
            0       { Write-Host "Display set as primary." -ForegroundColor Green }
            1       { Write-Host "Display set - restart Windows to fully apply." -ForegroundColor Yellow }
            default { Write-Host "ChangeDisplaySettingsEx returned: $result" -ForegroundColor Red }
        }
    }
}

# ── 4. Start Stream Deck ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "Starting Stream Deck..." -ForegroundColor Yellow

$sdPaths = @(
    "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe",
    "${env:ProgramFiles(x86)}\Elgato\StreamDeck\StreamDeck.exe"
)

$sdExe = $sdPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($sdExe) {
    Start-Process -FilePath $sdExe
    Write-Host "Stream Deck launched: $sdExe" -ForegroundColor Green
} else {
    Write-Host "Stream Deck not found at default paths:" -ForegroundColor Red
    $sdPaths | ForEach-Object { Write-Host "   $_" }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green

# DaVinci Resolve Audio Crackling Diagnostic
# Run this while the crackling project is open in Resolve

Write-Host "`n╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   DaVinci Resolve Audio Crackling Diagnostic     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ── 1. Focusrite Device Status ──────────────────────────────
Write-Host "=== 1. Focusrite / Audio Interface ===" -ForegroundColor Yellow
$focusrite = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Focusrite*" -or $_.FriendlyName -like "*Scarlett*" }
if ($focusrite) {
    $focusrite | Format-Table Status, FriendlyName, InstanceId -AutoSize
} else {
    Write-Host "  WARNING: Focusrite device not found!" -ForegroundColor Red
}

# ── 2. All Audio Endpoints & Sample Rate Info ────────────────
Write-Host "`n=== 2. Audio Endpoint Devices ===" -ForegroundColor Yellow
$audioDevices = Get-PnpDevice -Class AudioEndpoint | Select-Object Status, FriendlyName
$audioDevices | Format-Table -AutoSize

$okCount = ($audioDevices | Where-Object { $_.Status -eq "OK" }).Count
$totalCount = $audioDevices.Count
Write-Host "  $okCount of $totalCount endpoints OK" -ForegroundColor $(if ($okCount -eq $totalCount) { "Green" } else { "Yellow" })

# ── 3. Windows Audio Sample Rate (Default Device) ───────────
Write-Host "`n=== 3. Windows Default Audio Format ===" -ForegroundColor Yellow
try {
    $audioReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
    $devices = Get-ChildItem $audioReg -ErrorAction Stop
    $defaultDevice = $devices | Where-Object {
        (Get-ItemProperty "$($_.PSPath)\Properties" -ErrorAction SilentlyContinue) -ne $null
    } | Select-Object -First 3

    Write-Host "  Check Focusrite Control app for current sample rate" -ForegroundColor Gray
    Write-Host "  Common mismatch: Focusrite=44100Hz vs Resolve Timeline=48000Hz" -ForegroundColor Gray
} catch {
    Write-Host "  Could not read audio registry directly" -ForegroundColor Gray
}

# ── 4. DaVinci Resolve Process Check ────────────────────────
Write-Host "`n=== 4. DaVinci Resolve Process ===" -ForegroundColor Yellow
$resolve = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue
if ($resolve) {
    Write-Host "  ✅ Resolve is running" -ForegroundColor Green
    Write-Host "  PID: $($resolve.Id)" -ForegroundColor Gray
    Write-Host "  Memory: $([math]::Round($resolve.WorkingSet64/1MB))MB" -ForegroundColor Gray
    Write-Host "  CPU Time: $($resolve.TotalProcessorTime)" -ForegroundColor Gray

    # Check if Resolve is using excessive CPU (sign of audio resampling stress)
    $cpuLoad = $resolve.CPU
    Write-Host "  CPU: $cpuLoad seconds total processor time" -ForegroundColor Gray
} else {
    Write-Host "  ⚠️  Resolve is NOT running - open your crackling project first, then re-run this script" -ForegroundColor Yellow
}

# ── 5. Resolve Project Database Location ────────────────────
Write-Host "`n=== 5. Resolve Project Files ===" -ForegroundColor Yellow
$resolveProjects = @(
    "$env:APPDATA\Blackmagic Design\DaVinci Resolve\Support\Resolve Disk Database",
    "$env:PUBLIC\Documents\DaVinci Resolve\Projects",
    "C:\ProgramData\Blackmagic Design\DaVinci Resolve"
)
foreach ($path in $resolveProjects) {
    if (Test-Path $path) {
        Write-Host "  Found: $path" -ForegroundColor Green
        $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Host "  Size: $([math]::Round($size/1MB, 1))MB" -ForegroundColor Gray
    }
}

# ── 6. Resolve Cache & Temp Files ───────────────────────────
Write-Host "`n=== 6. Resolve Cache Location ===" -ForegroundColor Yellow
$cachePaths = @(
    "$env:LOCALAPPDATA\Temp\DaVinci Resolve",
    "C:\Users\$env:USERNAME\AppData\Local\Temp"
)
foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        $cacheSize = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Host "  $path" -ForegroundColor Gray
        Write-Host "  Cache size: $([math]::Round($cacheSize/1MB, 1))MB" -ForegroundColor Gray
    }
}

# ── 7. USB Controller Check (Focusrite relies on USB) ───────
Write-Host "`n=== 7. USB Controllers ===" -ForegroundColor Yellow
$usbControllers = Get-PnpDevice -Class USB | Where-Object { $_.Status -eq "OK" -and $_.FriendlyName -like "*Host Controller*" }
$usbControllers | Format-Table Status, FriendlyName -AutoSize
Write-Host "  TIP: Focusrite should be on its own USB controller, not shared with DisplayLink" -ForegroundColor Gray

# ── 8. Current DPC Hot Drivers ───────────────────────────────
Write-Host "`n=== 8. High-Risk DPC Drivers (still loaded) ===" -ForegroundColor Yellow
$dpcDrivers = @("dxgkrnl.sys", "HDAudBus.sys", "USBXHCI.SYS", "tcpip.sys", "storport.sys")
foreach ($driver in $dpcDrivers) {
    $found = Get-Process | Where-Object { $_.Modules.ModuleName -contains $driver } -ErrorAction SilentlyContinue
    $driverPath = "C:\Windows\System32\drivers\$driver"
    if (Test-Path $driverPath) {
        $driverInfo = Get-Item $driverPath
        Write-Host "  ⚠️  $driver - Last modified: $($driverInfo.LastWriteTime)" -ForegroundColor Yellow
    }
}

# ── 9. Recommendations ───────────────────────────────────────
Write-Host "`n╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                 NEXT STEPS                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host @"

In DaVinci Resolve (crackling project):
  1. Preferences > System > Audio I/O
     → Set device: Focusrite USB Audio (not Default)
     → Sample rate: 48000 Hz
     → Buffer size: 512 or 1024

  2. Fairlight page → check for RED waveforms
     → Red = sample rate mismatch on that clip

  3. Playback menu → Render Cache → Smart
     → Then: Fairlight → Create Audio Render Cache

  4. Preferences > Memory and GPU
     → Uncheck 'Use display GPU for compute'

  5. Match Focusrite Control app sample rate to Resolve
     → Both must be 48000Hz or both 44100Hz

"@ -ForegroundColor White

Write-Host "Diagnostic complete.`n" -ForegroundColor Cyan
<#
.SYNOPSIS
    Scans Windows event logs for DaVinci Resolve, audio, and GPU issues.
    Output is formatted for copy-paste into an AI assistant for diagnosis.

.DESCRIPTION
    Targets:
      - DaVinci Resolve / Blackmagic Design application crashes and errors
      - Windows Audio subsystem failures (AudioSrv, WASAPI, audio drivers)
      - GPU / display driver errors (NVIDIA, AMD, Intel)
      - General application crashes and hangs involving Resolve processes
#>

$ErrorActionPreference = "SilentlyContinue"
$originalTitle = $Host.UI.RawUI.WindowTitle
$Host.UI.RawUI.WindowTitle = "DaVinci Resolve Event Scanner"

$HoursBack = 48
$StartDate = (Get-Date).AddHours(-$HoursBack)

# ── Keywords used to filter relevant events ──────────────────────────────────
$ResolveKeywords  = @("resolve", "blackmagic", "davinci", "bmd", "braw")
$AudioKeywords    = @("audio", "wasapi", "audiodg", "audiosrv", "audioendpoint", "mmdevapi", "soundmax", "realtek", "audioservice")
$GpuKeywords      = @("nvlddmkm", "amdkmdag", "amdkmdap", "igdkmd", "display", "dxgi", "d3d", "directx", "gpu", "nvwmi", "atikmdag", "nvapi", "cuda", "opencl")

# Event sources known to be relevant
$AudioSources     = @("AudioSrv", "AudioEndpointBuilder", "AudioClientRpc", "Windows Audio", "PlugPlay")
$GpuSources       = @("nvlddmkm", "amdkmdag", "Display", "igdkmd64", "Microsoft-Windows-Kernel-PnP")
$AppCrashSources  = @("Application Error", "Application Hang", "Windows Error Reporting")

Function Write-Header {
    param ([string]$Text)
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor White
    Write-Host "================================================================================" -ForegroundColor Cyan
}

Function Write-Divider {
    Write-Host "  ────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
}

# Returns true if any keyword matches the text (case-insensitive)
Function Test-Keywords {
    param ([string]$Text, [string[]]$Keywords)
    foreach ($kw in $Keywords) {
        if ($Text -match [regex]::Escape($kw)) { return $true }
    }
    return $false
}

Function Get-RelevantEvents {
    param ([string]$LogName)
    $results = @()
    try {
        $raw = Get-EventLog -LogName $LogName -After $StartDate -EntryType Error, Warning -ErrorAction SilentlyContinue
        foreach ($ev in $raw) {
            $src = $ev.Source ?? ""
            $msg = $ev.Message ?? ""
            $combined = "$src $msg".ToLower()

            $isResolve = Test-Keywords -Text $combined -Keywords $ResolveKeywords
            $isAudio   = (Test-Keywords -Text $combined -Keywords $AudioKeywords) -or ($AudioSources -contains $src)
            $isGpu     = (Test-Keywords -Text $combined -Keywords $GpuKeywords)   -or ($GpuSources   -contains $src)
            $isCrash   = ($AppCrashSources -contains $src) -and (Test-Keywords -Text $combined -Keywords ($ResolveKeywords + $AudioKeywords + $GpuKeywords))

            if ($isResolve -or $isAudio -or $isGpu -or $isCrash) {
                $ev | Add-Member -NotePropertyName "_Category" -NotePropertyValue (
                    if ($isResolve) { "DAVINCI" }
                    elseif ($isAudio) { "AUDIO" }
                    elseif ($isGpu)   { "GPU" }
                    else              { "CRASH" }
                ) -Force
                $results += $ev
            }
        }
    }
    catch {
        Write-Host "  [WARN] Could not read '$LogName' log. Try running as Administrator." -ForegroundColor Yellow
    }
    return $results
}

# ── Collect events ────────────────────────────────────────────────────────────
Clear-Host
Write-Header "DaVinci Resolve — Audio & Visual Diagnostic Scanner"
Write-Host "  Scanning last $HoursBack hours of System + Application logs..." -ForegroundColor Cyan

$allEvents = @()
$allEvents += Get-RelevantEvents -LogName "System"
$allEvents += Get-RelevantEvents -LogName "Application"

# Sort by time, newest last (easier to read in terminal, AI reads top-down)
$allEvents = $allEvents | Sort-Object TimeGenerated

# ── System info header for AI context ────────────────────────────────────────
$os      = Get-CimInstance Win32_OperatingSystem
$cs      = Get-CimInstance Win32_ComputerSystem
$gpu     = Get-CimInstance Win32_VideoController | Select-Object -First 2
$lastBoot = $os.LastBootUpTime

Write-Header "System Context  (copy everything below this line to your AI)"
Write-Host ""
Write-Host "=== SYSTEM INFO ===" -ForegroundColor White
Write-Host "  OS        : $($os.Caption) Build $($os.BuildNumber)"
Write-Host "  RAM       : $([math]::Round($cs.TotalPhysicalMemory / 1GB, 1)) GB"
Write-Host "  Last Boot : $($lastBoot.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "  Scan From : $($StartDate.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "  Scan To   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
foreach ($g in $gpu) {
    Write-Host "  GPU       : $($g.Name)  [Driver: $($g.DriverVersion)]"
}
Write-Host "  Events    : $($allEvents.Count) matching events found"
Write-Host ""

if ($allEvents.Count -eq 0) {
    Write-Host "  [OK] No DaVinci Resolve / audio / GPU events found in the last $HoursBack hours." -ForegroundColor Green
    Write-Host ""
}
else {
    # ── Summary by category ───────────────────────────────────────────────────
    Write-Host "=== SUMMARY ===" -ForegroundColor White
    $categories = $allEvents | Group-Object _Category
    foreach ($cat in $categories) {
        $errors = ($cat.Group | Where-Object { $_.EntryType -eq 'Error' }).Count
        $warns  = ($cat.Group | Where-Object { $_.EntryType -eq 'Warning' }).Count
        $color  = if ($errors -gt 0) { 'Red' } else { 'Yellow' }
        Write-Host ("  [{0,-8}] {1,3} events  ({2} errors, {3} warnings)" -f $cat.Name, $cat.Count, $errors, $warns) -ForegroundColor $color
    }
    Write-Host ""

    # ── Top recurring issues ──────────────────────────────────────────────────
    Write-Host "=== TOP RECURRING ISSUES ===" -ForegroundColor White
    $grouped = $allEvents | Group-Object Source, InstanceId | Sort-Object Count -Descending | Select-Object -First 10
    foreach ($g in $grouped) {
        $first = $g.Group[0]
        $msg   = ($first.Message -replace "[\r\n]+", " ").Trim()
        if ($msg.Length -gt 120) { $msg = $msg.Substring(0, 120) + "..." }
        $color = if ($first.EntryType -eq 'Error') { 'Red' } else { 'Yellow' }
        Write-Host ("  [{0}x] [{1}] [{2}] {3}" -f $g.Count, $first._Category, $first.Source, $msg) -ForegroundColor $color
    }
    Write-Host ""

    # ── Full event log ────────────────────────────────────────────────────────
    Write-Host "=== FULL EVENT LOG ===" -ForegroundColor White
    Write-Host ""

    $lastCat = ""
    foreach ($ev in $allEvents) {
        $cat    = $ev._Category
        $type   = $ev.EntryType.ToString()
        $time   = $ev.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
        $src    = $ev.Source
        $id     = $ev.EventID
        $msg    = ($ev.Message -replace "[\r\n]+", " ").Trim()
        # Keep more text for AI — truncate only at 300 chars
        if ($msg.Length -gt 300) { $msg = $msg.Substring(0, 300) + "..." }

        if ($cat -ne $lastCat) {
            Write-Host "  -- $cat EVENTS --" -ForegroundColor Cyan
            $lastCat = $cat
        }

        $color = if ($type -eq "Error") { "Red" } else { "Yellow" }
        Write-Host "  [$time] [$type] [EventID:$id] [$src]" -ForegroundColor $color
        Write-Host "    $msg" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "=== END OF LOG ===" -ForegroundColor Cyan
    Write-Host ""
}

# ── Auto-copy full report to clipboard ───────────────────────────────────────
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("=== DAVINCI RESOLVE DIAGNOSTIC REPORT ===")
[void]$sb.AppendLine("Scan range: $($StartDate.ToString('yyyy-MM-dd HH:mm')) to $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$sb.AppendLine("OS: $($os.Caption) Build $($os.BuildNumber)")
[void]$sb.AppendLine("RAM: $([math]::Round($cs.TotalPhysicalMemory / 1GB, 1)) GB | Last Boot: $($lastBoot.ToString('yyyy-MM-dd HH:mm:ss'))")
foreach ($g in $gpu) {
    [void]$sb.AppendLine("GPU: $($g.Name)  Driver: $($g.DriverVersion)")
}
[void]$sb.AppendLine("")

if ($allEvents.Count -eq 0) {
    [void]$sb.AppendLine("No relevant events found.")
}
else {
    foreach ($ev in $allEvents) {
        $msg = ($ev.Message -replace "[\r\n]+", " ").Trim()
        if ($msg.Length -gt 400) { $msg = $msg.Substring(0, 400) + "..." }
        [void]$sb.AppendLine("[$($ev.TimeGenerated.ToString('yyyy-MM-dd HH:mm:ss'))] [$($ev._Category)] [$($ev.EntryType)] [ID:$($ev.EventID)] [$($ev.Source)]")
        [void]$sb.AppendLine("  $msg")
        [void]$sb.AppendLine("")
    }
}

$sb.ToString() | Set-Clipboard
Write-Host "`n  [OK] Report copied to clipboard — paste into your AI assistant." -ForegroundColor Green

# ── Block until user explicitly closes (works from Stream Deck) ───────────────
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "Scan complete. Report copied to clipboard.`n`nPaste it into your AI assistant to diagnose DaVinci Resolve issues.",
    "DaVinci Resolve Scanner",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null

$Host.UI.RawUI.WindowTitle = $originalTitle

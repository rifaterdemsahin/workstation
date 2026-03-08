# ============================================================
#  RESOLVE OPTIMIZER - Stream Deck Launcher
#  Limits Resolve to first NUMA node (32 cores)
#  Performance fix for Threadripper 3995X + RX 6900 XT
#
#  Stream Deck: Open action > powershell.exe
#  Args: -ExecutionPolicy Bypass -File "C:\path\to\resolve_launch.ps1"
# ============================================================

$Host.UI.RawUI.WindowTitle = "RESOLVE OPTIMIZER"
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

function Write-Color {
    param([string]$Text, [string]$Color = "White", [switch]$NoNewline)
    if ($NoNewline) { Write-Host $Text -ForegroundColor $Color -NoNewline }
    else            { Write-Host $Text -ForegroundColor $Color }
}

Write-Color ""
Write-Color "  ██████╗ ███████╗███████╗ ██████╗ ██╗    ██╗   ██╗███████╗" "Cyan"
Write-Color "  ██╔══██╗██╔════╝██╔════╝██╔═══██╗██║    ██║   ██║██╔════╝" "Cyan"
Write-Color "  ██████╔╝█████╗  ███████╗██║   ██║██║    ██║   ██║█████╗  " "Cyan"
Write-Color "  ██╔══██╗██╔══╝  ╚════██║██║   ██║██║    ╚██╗ ██╔╝██╔══╝  " "Cyan"
Write-Color "  ██║  ██║███████╗███████║╚██████╔╝███████╗╚████╔╝ ███████╗" "Cyan"
Write-Color "  ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝ ╚═══╝  ╚══════╝" "Cyan"
Write-Color ""
Write-Color "  +---------------------------------------------------------+" "DarkGray"
Write-Color "  |   Threadripper 3995X  x  RX 6900 XT  x  NUMA Optimizer |" "DarkGray"
Write-Color "  +---------------------------------------------------------+" "DarkGray"
Write-Color ""

$sep = "  " + ("-" * 57)

Write-Color $sep "DarkGray"
Write-Color "  SYSTEM CHECK" "Yellow"
Write-Color $sep "DarkGray"

$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$cpu = (Get-CimInstance Win32_Processor).Name
$gpuObj = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -like "*AMD*" }
$gpu = if ($gpuObj) { $gpuObj.Name } else { "GPU not found" }

Write-Color "  CPU   : " "DarkGray" -NoNewline; Write-Color $cpu "White"
Write-Color "  GPU   : " "DarkGray" -NoNewline; Write-Color $gpu "White"
Write-Color "  RAM   : " "DarkGray" -NoNewline; Write-Color "${ram} GB" "White"
Write-Color ""

Write-Color $sep "DarkGray"
Write-Color "  NUMA CONFIGURATION" "Yellow"
Write-Color $sep "DarkGray"
Write-Color "  Total cores     : " "DarkGray" -NoNewline; Write-Color "64 cores / 128 threads" "White"
Write-Color "  NUMA nodes      : " "DarkGray" -NoNewline; Write-Color "2 nodes (32 cores each)" "White"
Write-Color "  Resolve target  : " "DarkGray" -NoNewline; Write-Color "Node 0 - cores 0-31 (0xFFFFFFFF)" "Green"
Write-Color "  Reason          : " "DarkGray" -NoNewline; Write-Color "Resolve does not scale past 32 cores" "Gray"
Write-Color ""

Write-Color $sep "DarkGray"
Write-Color "  RESOLVE STATUS" "Yellow"
Write-Color $sep "DarkGray"

$existing = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue

if ($existing) {
    Write-Color "  Resolve already running (PID: $($existing.Id))" "Yellow"
    Write-Color "  Applying NUMA affinity to existing process..." "Gray"
    Write-Color ""
    try {
        $existing.ProcessorAffinity = [IntPtr]0xFFFFFFFF
        Write-Color "  OK - Affinity applied to running instance!" "Green"
        Write-Color "     Cores 0-31 active, cores 32-63 released" "DarkGray"
    } catch {
        Write-Color "  WARNING - Could not set affinity: $_" "Red"
        Write-Color "  Try running this script as Administrator" "Gray"
    }
} else {
    $resolvePaths = @(
        "C:\Program Files\Blackmagic Design\DaVinci Resolve\Resolve.exe",
        "C:\Program Files\Blackmagic Design\DaVinci Resolve 19\Resolve.exe"
    )

    $resolvePath = $null
    foreach ($path in $resolvePaths) {
        if (Test-Path $path) { $resolvePath = $path; break }
    }

    if (-not $resolvePath) {
        Write-Color "  ERROR - DaVinci Resolve not found!" "Red"
        Write-Color "  Update the path in this script" "Yellow"
    } else {
        Write-Color "  Launching DaVinci Resolve..." "Gray"
        Write-Color "  Path: $resolvePath" "DarkGray"
        Write-Color ""

        try {
            $process = Start-Process -FilePath $resolvePath -PassThru
            Write-Color "  Waiting for Resolve to initialise..." "Gray"

            $waited = 0
            while ($waited -lt 30) {
                Start-Sleep -Seconds 2
                $waited += 2
                $resolveProc = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue
                if ($resolveProc) {
                    Write-Color "  OK - Resolve started! (PID: $($resolveProc.Id))" "Green"
                    break
                }
                Write-Color "  Still waiting... ($waited s)" "DarkGray"
            }

            Start-Sleep -Seconds 3
            $resolveProc = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue
            if ($resolveProc) {
                try {
                    $resolveProc.ProcessorAffinity = [IntPtr]0xFFFFFFFF
                    Write-Color ""
                    Write-Color $sep "DarkGray"
                    Write-Color "  AFFINITY APPLIED" "Yellow"
                    Write-Color $sep "DarkGray"
                    Write-Color "  OK - Limited to cores 0-31 (NUMA node 0)" "Green"
                    Write-Color "  OK - Freed cores 32-63 for OS tasks" "Green"
                    Write-Color "  OK - Expected: smoother playback, fewer dropped frames" "Green"
                } catch {
                    Write-Color "  WARNING - Affinity set failed: $_" "Yellow"
                    Write-Color "  Try right-clicking this script and Run as Administrator" "Gray"
                }
            } else {
                Write-Color "  WARNING - Could not find Resolve process after launch" "Yellow"
            }
        } catch {
            Write-Color "  ERROR - Failed to launch Resolve: $_" "Red"
        }
    }
}

Write-Color ""
Write-Color $sep "DarkGray"
Write-Color "  RESOLVE PERFORMANCE SETTINGS REMINDER" "Yellow"
Write-Color $sep "DarkGray"
Write-Color "  Memory          : 55 GB allocated" "Green"
Write-Color "  GPU decode      : H.264/H.265 hardware ON" "Green"
Write-Color "  Audio engine    : ASIO > Focusrite USB" "Green"
Write-Color "  Proxy           : Enable before editing heavy timelines" "Cyan"
Write-Color "  Playback menu   : Proxy Media > Enable Proxies" "DarkGray"
Write-Color ""
Write-Color $sep "DarkGray"
Write-Color ""
Write-Color "  Go make something great, Erdem." "Cyan"
Write-Color ""
Write-Color $sep "DarkGray"
Write-Color ""
Write-Color "  Window stays open - close manually when done." "DarkGray"
Write-Color ""

while ($true) {
    Start-Sleep -Seconds 60
}
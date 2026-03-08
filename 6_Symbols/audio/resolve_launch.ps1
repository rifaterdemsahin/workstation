# ============================================================
#  RESOLVE OPTIMIZER - Stream Deck Launcher
#  Pins Resolve to Processor Group 0 (NUMA node 0, 32 cores)
#  Performance fix for Threadripper 3995WX + RX 6900 XT
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
Write-Color "  |   Threadripper 3995WX  x  RX 6900 XT  x  NUMA Optimizer|" "DarkGray"
Write-Color "  +---------------------------------------------------------+" "DarkGray"
Write-Color ""

$sep = "  " + ("-" * 57)

# ── Windows API: processor group affinity ────────────────────
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct GROUP_AFFINITY {
    public UIntPtr Mask;
    public ushort  Group;
    public ushort  Reserved1;
    public ushort  Reserved2;
    public ushort  Reserved3;
}

public static class Kernel32 {
    const uint THREAD_SET_INFORMATION   = 0x0020;
    const uint THREAD_QUERY_INFORMATION = 0x0040;

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenThread(uint access, bool inherit, uint threadId);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetThreadGroupAffinity(IntPtr hThread,
        ref GROUP_AFFINITY newAffinity, IntPtr prevAffinity);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool GetThreadGroupAffinity(IntPtr hThread,
        out GROUP_AFFINITY affinity);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr h);

    public static ushort GetProcessGroup(System.Diagnostics.Process proc) {
        var thread = proc.Threads[0];
        IntPtr h = OpenThread(THREAD_QUERY_INFORMATION, false, (uint)thread.Id);
        if (h == IntPtr.Zero) return ushort.MaxValue;
        GROUP_AFFINITY aff;
        GetThreadGroupAffinity(h, out aff);
        CloseHandle(h);
        return aff.Group;
    }

    public static int SetProcessGroup(System.Diagnostics.Process proc, ushort group) {
        int ok = 0; int fail = 0;
        var allCpus = new UIntPtr(ulong.MaxValue);
        foreach (System.Diagnostics.ProcessThread t in proc.Threads) {
            IntPtr h = OpenThread(THREAD_SET_INFORMATION | THREAD_QUERY_INFORMATION,
                                  false, (uint)t.Id);
            if (h == IntPtr.Zero) { fail++; continue; }
            var aff = new GROUP_AFFINITY { Mask = allCpus, Group = group };
            if (SetThreadGroupAffinity(h, ref aff, IntPtr.Zero)) ok++; else fail++;
            CloseHandle(h);
        }
        return fail == 0 ? ok : -fail;
    }
}
"@ -ErrorAction Stop

function Set-ResolveGroup {
    param($Proc, [uint16]$Group = 0)
    $result = [Kernel32]::SetProcessGroup($Proc, $Group)
    return $result
}

function Get-ResolveGroup {
    param($Proc)
    return [Kernel32]::GetProcessGroup($Proc)
}

# ── System check ─────────────────────────────────────────────
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

# ── Group config ─────────────────────────────────────────────
Write-Color $sep "DarkGray"
Write-Color "  PROCESSOR GROUP CONFIGURATION" "Yellow"
Write-Color $sep "DarkGray"
Write-Color "  System total    : " "DarkGray" -NoNewline; Write-Color "64 cores / 128 threads (2 groups)" "White"
Write-Color "  Group 0 (target): " "DarkGray" -NoNewline; Write-Color "32 cores / 64 threads  [NUMA node 0]" "Green"
Write-Color "  Group 1 (freed) : " "DarkGray" -NoNewline; Write-Color "32 cores / 64 threads  [NUMA node 1]" "DarkGray"
Write-Color "  Reason          : " "DarkGray" -NoNewline; Write-Color "Resolve does not scale past 32 cores" "Gray"
Write-Color ""

# ── Resolve status ────────────────────────────────────────────
Write-Color $sep "DarkGray"
Write-Color "  RESOLVE STATUS" "Yellow"
Write-Color $sep "DarkGray"

$existing = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue

if ($existing) {
    $currentGroup = Get-ResolveGroup -Proc $existing
    Write-Color "  Resolve already running (PID: $($existing.Id))" "Yellow"
    Write-Color "  Current group   : " "DarkGray" -NoNewline

    if ($currentGroup -eq 0) {
        Write-Color "Group 0  (correct)" "Green"
        Write-Color "  Reapplying to ensure all threads are pinned..." "Gray"
    } else {
        Write-Color "Group $currentGroup  (WRONG - needs Group 0)" "Red"
        Write-Color "  Reassigning to Group 0..." "Gray"
    }

    $result = Set-ResolveGroup -Proc $existing -Group 0
    if ($result -gt 0) {
        Write-Color "  OK - $result thread(s) pinned to Group 0 (NUMA node 0)" "Green"
    } else {
        Write-Color "  WARNING - Failed on $([Math]::Abs($result)) thread(s). Try Run as Administrator." "Red"
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
            $resolveProc = $null
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

            if ($resolveProc) {
                Start-Sleep -Seconds 3   # let more threads spin up
                $resolveProc = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue
                Write-Color ""
                Write-Color $sep "DarkGray"
                Write-Color "  PINNING TO GROUP 0" "Yellow"
                Write-Color $sep "DarkGray"

                $result = Set-ResolveGroup -Proc $resolveProc -Group 0
                if ($result -gt 0) {
                    Write-Color "  OK - $result thread(s) pinned to Group 0 (NUMA node 0)" "Green"
                    Write-Color "  OK - Group 1 (cores 32-63) freed for OS tasks" "Green"
                    Write-Color "  OK - Expected: smoother playback, fewer dropped frames" "Green"

                    $verifyGroup = Get-ResolveGroup -Proc $resolveProc
                    Write-Color "  Verified group  : " "DarkGray" -NoNewline
                    if ($verifyGroup -eq 0) {
                        Write-Color "Group 0  (confirmed)" "Green"
                    } else {
                        Write-Color "Group $verifyGroup  (unexpected)" "Yellow"
                    }
                } else {
                    Write-Color "  WARNING - Pinning failed on $([Math]::Abs($result)) thread(s)." "Yellow"
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

# ── Reminders ────────────────────────────────────────────────
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

while ($true) { Start-Sleep -Seconds 60 }

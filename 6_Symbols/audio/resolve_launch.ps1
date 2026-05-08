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

# ── Windows API: CPU Sets (Win10+) + group query ─────────────
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

// Read-only group query (sample first thread)
[StructLayout(LayoutKind.Sequential)]
public struct GROUP_AFFINITY {
    public UIntPtr Mask;
    public ushort  Group;
    public ushort  Reserved1;
    public ushort  Reserved2;
    public ushort  Reserved3;
}

// SYSTEM_CPU_SET_INFORMATION - CpuSet union variant (32 bytes)
[StructLayout(LayoutKind.Explicit, Size=32)]
public struct SYSTEM_CPU_SET_INFORMATION {
    [FieldOffset( 0)] public uint   Size;
    [FieldOffset( 4)] public uint   Type;           // 0 = CpuSetInformation
    [FieldOffset( 8)] public uint   Id;
    [FieldOffset(12)] public ushort Group;
    [FieldOffset(14)] public byte   LogicalProcessorIndex;
    [FieldOffset(15)] public byte   CoreIndex;
    [FieldOffset(16)] public byte   LastLevelCacheIndex;
    [FieldOffset(17)] public byte   NumaNodeIndex;
    [FieldOffset(18)] public byte   EfficiencyClass;
    [FieldOffset(19)] public byte   AllFlags;
    [FieldOffset(20)] public uint   SchedulingClass;
    [FieldOffset(24)] public ulong  AllocationTag;
}

public static class Kernel32 {
    const uint THREAD_QUERY_INFORMATION          = 0x0040;
    const uint PROCESS_QUERY_LIMITED_INFORMATION = 0x1000;
    const uint PROCESS_SET_LIMITED_INFORMATION   = 0x2000;

    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr OpenThread(uint access, bool inherit, uint threadId);

    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool GetThreadGroupAffinity(IntPtr hThread, out GROUP_AFFINITY affinity);

    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr OpenProcess(uint access, bool inherit, uint pid);

    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool CloseHandle(IntPtr h);

    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool GetSystemCpuSetInformation(
        IntPtr info, uint infoLength, out uint returnLength,
        IntPtr process, uint flags);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetProcessDefaultCpuSets(
        IntPtr process, uint[] cpuSetIds, uint count);

    // Returns NUMA node index of the process's first thread (for status display)
    public static int GetProcessNumaNode(System.Diagnostics.Process proc) {
        IntPtr h = OpenThread(THREAD_QUERY_INFORMATION, false, (uint)proc.Threads[0].Id);
        if (h == IntPtr.Zero) return -1;
        GROUP_AFFINITY aff;
        GetThreadGroupAffinity(h, out aff);
        CloseHandle(h);
        return aff.Group;   // on Threadripper 3995WX: group == NUMA node
    }

    // Collect CPU set IDs belonging to a NUMA node, then pin the process
    public static string PinToNumaNode(uint pid, byte numaNode) {
        // Query required buffer size
        uint needed = 0;
        GetSystemCpuSetInformation(IntPtr.Zero, 0, out needed, IntPtr.Zero, 0);
        if (needed == 0) return "ERROR: GetSystemCpuSetInformation returned 0 bytes";

        IntPtr buf = Marshal.AllocHGlobal((int)needed);
        try {
            if (!GetSystemCpuSetInformation(buf, needed, out needed, IntPtr.Zero, 0))
                return "ERROR: GetSystemCpuSetInformation failed (" + Marshal.GetLastWin32Error() + ")";

            var ids = new List<uint>();
            IntPtr ptr = buf;
            uint remaining = needed;
            int structSize = Marshal.SizeOf(typeof(SYSTEM_CPU_SET_INFORMATION));

            while (remaining >= structSize) {
                var info = (SYSTEM_CPU_SET_INFORMATION)Marshal.PtrToStructure(
                    ptr, typeof(SYSTEM_CPU_SET_INFORMATION));
                if (info.Type == 0 && info.NumaNodeIndex == numaNode)
                    ids.Add(info.Id);
                if (info.Size == 0) break;
                ptr      = new IntPtr(ptr.ToInt64() + info.Size);
                remaining -= info.Size;
            }

            if (ids.Count == 0)
                return "ERROR: No CPU sets found for NUMA node " + numaNode;

            IntPtr hProc = OpenProcess(PROCESS_SET_LIMITED_INFORMATION, false, pid);
            if (hProc == IntPtr.Zero)
                return "ERROR: OpenProcess failed (" + Marshal.GetLastWin32Error() + ") - run as Administrator";

            try {
                bool ok = SetProcessDefaultCpuSets(hProc, ids.ToArray(), (uint)ids.Count);
                if (ok) return "OK:" + ids.Count;
                return "ERROR: SetProcessDefaultCpuSets failed (" + Marshal.GetLastWin32Error() + ")";
            } finally {
                CloseHandle(hProc);
            }
        } finally {
            Marshal.FreeHGlobal(buf);
        }
    }
}
"@ -ErrorAction Stop

function Set-ResolveNumaNode {
    param($Proc, [byte]$NumaNode = 0)
    return [Kernel32]::PinToNumaNode([uint32]$Proc.Id, $NumaNode)
}

function Get-ResolveNumaNode {
    param($Proc)
    return [Kernel32]::GetProcessNumaNode($Proc)
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
    $currentNode = Get-ResolveNumaNode -Proc $existing
    Write-Color "  Resolve already running (PID: $($existing.Id))" "Yellow"
    Write-Color "  Current NUMA node: " "DarkGray" -NoNewline

    if ($currentNode -eq 0) {
        Write-Color "Node 0  (correct)" "Green"
        Write-Color "  Reapplying CPU Sets to ensure pin is active..." "Gray"
    } elseif ($currentNode -lt 0) {
        Write-Color "Unknown (thread query failed)" "Yellow"
        Write-Color "  Applying CPU Sets anyway..." "Gray"
    } else {
        Write-Color "Node $currentNode  (WRONG - needs Node 0)" "Red"
        Write-Color "  Reassigning via CPU Sets..." "Gray"
    }

    $result = Set-ResolveNumaNode -Proc $existing -NumaNode 0
    if ($result -like "OK:*") {
        $count = $result.Split(':')[1]
        Write-Color "  OK - Pinned via $count CPU Sets to NUMA node 0" "Green"
    } else {
        Write-Color "  $result" "Red"
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
                Write-Color "  PINNING TO NUMA NODE 0 (CPU SETS)" "Yellow"
                Write-Color $sep "DarkGray"

                $result = Set-ResolveNumaNode -Proc $resolveProc -NumaNode 0
                if ($result -like "OK:*") {
                    $count = $result.Split(':')[1]
                    Write-Color "  OK - Pinned via $count CPU Sets to NUMA node 0" "Green"
                    Write-Color "  OK - NUMA node 1 (cores 32-63) freed for OS tasks" "Green"
                    Write-Color "  OK - Pin persists for all future threads Resolve spawns" "Green"
                    Write-Color "  OK - Expected: smoother playback, fewer dropped frames" "Green"
                } else {
                    Write-Color "  $result" "Red"
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

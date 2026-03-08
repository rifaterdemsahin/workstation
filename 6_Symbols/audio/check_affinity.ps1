# ============================================================
#  CHECK_AFFINITY - Verify Resolve processor group assignment
#  Run after resolve_launch.ps1 to confirm Group 0 pinning
# ============================================================

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

public static class Kernel32Check {
    public const uint THREAD_QUERY_LIMITED_INFORMATION = 0x0800;

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenThread(uint access, bool inherit, uint threadId);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool GetThreadGroupAffinity(IntPtr hThread, out GROUP_AFFINITY affinity);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr h);
}
"@ -ErrorAction Stop

$p = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue

if (-not $p) {
    Write-Host "Resolve is NOT running." -ForegroundColor Red
    exit 1
}

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host ""
Write-Host "  RESOLVE GROUP CHECK" -ForegroundColor Yellow
Write-Host "  ---------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  PID            : " -ForegroundColor DarkGray -NoNewline; Write-Host $p.Id
Write-Host "  Total threads  : " -ForegroundColor DarkGray -NoNewline; Write-Host $p.Threads.Count
Write-Host "  Running as Admin: " -ForegroundColor DarkGray -NoNewline
if ($isAdmin) { Write-Host "Yes" -ForegroundColor Green } else { Write-Host "No  (thread open may fail)" -ForegroundColor Yellow }
Write-Host "  ---------------------------------------------------" -ForegroundColor DarkGray

# Sample all threads and count by group
$groupCounts = @{}
$openFail = 0; $queryFail = 0; $sampled = 0

foreach ($t in $p.Threads) {
    $h = [Kernel32Check]::OpenThread([Kernel32Check]::THREAD_QUERY_LIMITED_INFORMATION, $false, [uint32]$t.Id)
    if ($h -eq [IntPtr]::Zero) { $openFail++; continue }

    $aff = New-Object GROUP_AFFINITY
    if ([Kernel32Check]::GetThreadGroupAffinity($h, [ref]$aff)) {
        $g = [int]$aff.Group
        $groupCounts[$g] = ($groupCounts[$g] -as [int]) + 1
        $sampled++
    } else {
        $queryFail++
    }
    [Kernel32Check]::CloseHandle($h) | Out-Null
}

Write-Host "  Threads sampled: " -ForegroundColor DarkGray -NoNewline; Write-Host $sampled
if ($openFail -gt 0)  { Write-Host "  Open failed    : $openFail  (access denied - run as Admin for full scan)" -ForegroundColor Yellow }
if ($queryFail -gt 0) { Write-Host "  Query failed   : $queryFail" -ForegroundColor Yellow }

Write-Host "  ---------------------------------------------------" -ForegroundColor DarkGray

foreach ($key in ($groupCounts.Keys | Sort-Object)) {
    $label = if ($key -eq 0) { "Group 0 (NUMA node 0 - target)" } else { "Group $key (NUMA node $key)" }
    $color = if ($key -eq 0) { "Green" } else { "Yellow" }
    Write-Host "  $label : $($groupCounts[$key]) threads" -ForegroundColor $color
}

Write-Host "  ---------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Status         : " -ForegroundColor DarkGray -NoNewline

$g0 = $groupCounts[0] -as [int]
$g1 = $groupCounts[1] -as [int]

if ($sampled -eq 0 -and $openFail -gt 0) {
    Write-Host "Cannot verify - re-run as Administrator" -ForegroundColor Yellow
} elseif ($g1 -eq 0 -and $g0 -gt 0) {
    Write-Host "CORRECT - all sampled threads in Group 0 (NUMA node 0)" -ForegroundColor Green
} elseif ($g1 -gt 0 -and $g0 -gt 0) {
    Write-Host "PARTIAL - threads split across groups. Re-run launcher as Admin." -ForegroundColor Yellow
} else {
    Write-Host "UNEXPECTED - check manually" -ForegroundColor Red
}

# Fallback info: show ProcessorAffinity (within-group mask)
$aff = [long]$p.ProcessorAffinity
Write-Host ""
Write-Host "  ProcessorAffinity (within-group mask):" -ForegroundColor DarkGray
Write-Host "    Value : 0x$('{0:X}' -f $aff)" -ForegroundColor White
Write-Host "    Note  : -1 / 0xFFFF... = all CPUs in current group (expected)" -ForegroundColor DarkGray
Write-Host ""

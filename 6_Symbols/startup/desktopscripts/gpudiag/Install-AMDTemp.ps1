# Install-AMDTemp.ps1
# Installs AMD GPU temperature monitoring tools for use with GPU_Diagnostic_Startup.ps1
# Run once as Administrator

#Requires -RunAsAdministrator

function Test-Command { param([string]$Name); return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host ""
Write-Host "  AMD GPU Temperature Tool Installer" -ForegroundColor Cyan
Write-Host "  ===================================" -ForegroundColor Cyan
Write-Host ""

# ── Check: already installed ─────────────────────────────────────────────────
if (Test-Command "rocm-smi") {
    Write-Host "  [OK] rocm-smi already installed: $(Get-Command rocm-smi | Select-Object -ExpandProperty Source)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Test output:" -ForegroundColor DarkGray
    & rocm-smi --showtemp
    exit 0
}

if (Test-Command "amd-smi") {
    Write-Host "  [OK] amd-smi already installed: $(Get-Command amd-smi | Select-Object -ExpandProperty Source)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Test output:" -ForegroundColor DarkGray
    & amd-smi metric --gpu 0 --temperature
    exit 0
}

# ── Option 1: winget (AMD ROCm) ───────────────────────────────────────────────
Write-Host "  Trying winget install for AMD ROCm..." -ForegroundColor Yellow
if (Test-Command "winget") {
    try {
        $result = winget install --id AMD.ROCm --accept-package-agreements --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] ROCm installed via winget." -ForegroundColor Green
            Write-Host "  Restart your terminal, then re-run the GPU diagnostic." -ForegroundColor DarkGray
            exit 0
        }
        Write-Host "  winget ROCm install failed (exit $LASTEXITCODE). Trying amd-smi..." -ForegroundColor DarkYellow
    } catch {
        Write-Host "  winget error: $_" -ForegroundColor DarkYellow
    }

    # Option 2: winget amd-smi standalone
    try {
        $result2 = winget install --id AMD.amdsmi --accept-package-agreements --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] amd-smi installed via winget." -ForegroundColor Green
            Write-Host "  Restart your terminal, then re-run the GPU diagnostic." -ForegroundColor DarkGray
            exit 0
        }
    } catch {}
} else {
    Write-Host "  winget not found - skipping." -ForegroundColor DarkGray
}

# ── Option 3: Use AMD driver's built-in amd-smi (Radeon Software installs it) ─
$amdSmiPaths = @(
    "C:\Program Files\AMD\ROCm\bin\amd-smi.exe",
    "C:\Program Files\AMD\ROCm\bin\rocm-smi.exe",
    "C:\Windows\System32\amd-smi.exe"
)
foreach ($path in $amdSmiPaths) {
    if (Test-Path $path) {
        Write-Host "  [OK] Found AMD tool at: $path" -ForegroundColor Green
        Write-Host "  Adding to PATH for this session..." -ForegroundColor DarkGray
        $dir = Split-Path $path
        $env:PATH = "$dir;$env:PATH"

        # Add permanently to system PATH
        $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$dir*") {
            [System.Environment]::SetEnvironmentVariable("PATH", "$dir;$currentPath", "Machine")
            Write-Host "  [OK] Added $dir to system PATH permanently." -ForegroundColor Green
        }
        Write-Host "  Restart your terminal, then re-run the GPU diagnostic." -ForegroundColor DarkGray
        exit 0
    }
}

# ── Option 4: HWiNFO64 shared memory reader ──────────────────────────────────
Write-Host ""
Write-Host "  Automatic install not available. Options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  OPTION A - AMD ROCm (full GPU compute platform):" -ForegroundColor White
Write-Host "    winget install AMD.ROCm" -ForegroundColor DarkCyan
Write-Host "    Then run this script again." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  OPTION B - HWiNFO64 (lightweight, runs in background):" -ForegroundColor White
Write-Host "    winget install REALiX.HWiNFO" -ForegroundColor DarkCyan
Write-Host "    Enable: Settings > Shared Memory Support" -ForegroundColor DarkGray
Write-Host "    The GPU diagnostic will auto-detect HWiNFO64 shared memory." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  OPTION C - LibreHardwareMonitor (open source):" -ForegroundColor White
Write-Host "    winget install LibreHardwareMonitor.LibreHardwareMonitor" -ForegroundColor DarkCyan
Write-Host ""

Read-Host "  Press Enter to close"
exit 1

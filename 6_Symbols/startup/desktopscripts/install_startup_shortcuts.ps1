# PowerShell Script to Install Startup Shortcuts
# Purpose: Creates shortcuts in the Windows Startup folder for the agent scripts

$StartupFolder = [Environment]::GetFolderPath('Startup')
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Get-Location }

$ScriptsToInstall = @(
    "launch_chrome_urls.ps1",
    "start_gemini_secondbrain.ps1",
    "run_updates_admin.ps1"
)

$WScriptShell = New-Object -ComObject WScript.Shell

Write-Host "Installing shortcuts to Startup folder: $StartupFolder" -ForegroundColor Cyan

foreach ($ScriptName in $ScriptsToInstall) {
    if (Test-Path "$ScriptDir\$ScriptName") {
        $ShortcutPath = Join-Path $StartupFolder "$([System.IO.Path]::GetFileNameWithoutExtension($ScriptName)).lnk"
        $TargetScript = Join-Path $ScriptDir $ScriptName
        
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$TargetScript`""
        $Shortcut.WorkingDirectory = $ScriptDir
        $Shortcut.Description = "Startup Script for $ScriptName"
        $Shortcut.Save()
        
        Write-Host "Created shortcut: $ShortcutPath" -ForegroundColor Green
    }
    else {
        Write-Host "Warning: Script not found - $ScriptName" -ForegroundColor Yellow
    }
}

Write-Host "Installation complete." -ForegroundColor Cyan

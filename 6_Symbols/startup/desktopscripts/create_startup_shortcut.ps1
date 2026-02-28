# Create a shortcut for run_updates_admin.ps1 in Windows Startup folder

$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutPath = Join-Path $StartupFolder "run_updates_admin.lnk"
$TargetScript = Join-Path $PSScriptRoot "run_updates_admin.ps1"

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$TargetScript`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Description = "Daily Winget and Windows Updates"
$Shortcut.Save()

Write-Host "Startup shortcut created successfully at: $ShortcutPath" -ForegroundColor Green
Write-Host "The update script will run automatically on next login" -ForegroundColor Cyan

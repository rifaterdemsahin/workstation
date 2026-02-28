# PowerShell Profile Backup

## Overview

This folder contains backups of the PowerShell profile for version control and easy restoration.

**Profile Location**: `C:\Users\Pexabo\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

---

## Files

- **`backup_powershell_profile.ps1`** - Automated backup script
- **`Microsoft.PowerShell_profile.ps1`** - Latest profile backup (always current)
- **`backup_YYYYMMDD_HHMMSS.ps1`** - Timestamped backups (last 10 kept automatically)

---

## Usage

### Backup Your Profile

```powershell
# Run the backup script
.\backup_powershell_profile.ps1
```

This will:
- Copy current profile to `Microsoft.PowerShell_profile.ps1`
- Create timestamped backup `backup_YYYYMMDD_HHMMSS.ps1`
- Keep only last 10 timestamped backups
- Display profile statistics

### Restore Your Profile

```powershell
# Restore from latest backup
Copy-Item "C:\projects\workstation\6_Symbols\powershell_profile\Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force

# Or restore from specific timestamped backup
Copy-Item "C:\projects\workstation\6_Symbols\powershell_profile\backup_20260228_123456.ps1" -Destination $PROFILE -Force

# Reload profile
. $PROFILE
```

---

## Automation

### Add to Profile for Automatic Backup

Add this to your PowerShell profile to backup on every session start:

```powershell
# Auto-backup profile on startup (once per day)
$backupScript = "C:\projects\workstation\6_Symbols\powershell_profile\backup_powershell_profile.ps1"
$lastBackupFile = "C:\projects\workstation\6_Symbols\powershell_profile\.last_backup"

if (Test-Path $backupScript) {
    $shouldBackup = $false

    if (Test-Path $lastBackupFile) {
        $lastBackup = Get-Content $lastBackupFile -ErrorAction SilentlyContinue
        $lastBackupDate = [DateTime]::ParseExact($lastBackup, "yyyy-MM-dd", $null)

        if ($lastBackupDate -lt (Get-Date).Date) {
            $shouldBackup = $true
        }
    }
    else {
        $shouldBackup = $true
    }

    if ($shouldBackup) {
        & $backupScript
        (Get-Date -Format "yyyy-MM-dd") | Out-File -FilePath $lastBackupFile -Force
    }
}
```

### Schedule Automatic Backups

Create a scheduled task to run daily:

```powershell
# Create scheduled task for daily backup at 9 AM
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\projects\workstation\6_Symbols\powershell_profile\backup_powershell_profile.ps1`""

$trigger = New-ScheduledTaskTrigger -Daily -At 9am

$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive

Register-ScheduledTask -TaskName "Backup PowerShell Profile" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Description "Daily backup of PowerShell profile to workstation repo"
```

---

## Version Control

Since this folder is part of the workstation git repository:

```powershell
# After running backup, commit changes
cd C:\projects\workstation
git add 6_Symbols/powershell_profile/
git commit -m "chore: backup PowerShell profile"
git push
```

---

## Profile Information

### Check Your Current Profile

```powershell
# View profile location
$PROFILE

# Check if profile exists
Test-Path $PROFILE

# View profile content
Get-Content $PROFILE

# Edit profile
notepad $PROFILE
# or
code $PROFILE
```

### Common Profile Locations

- **Current User, Current Host**: `$PROFILE` or `$PROFILE.CurrentUserCurrentHost`
- **Current User, All Hosts**: `$PROFILE.CurrentUserAllHosts`
- **All Users, Current Host**: `$PROFILE.AllUsersCurrentHost`
- **All Users, All Hosts**: `$PROFILE.AllUsersAllHosts`

---

## Restore from Git Repository

If you need to restore on a new machine:

```powershell
# Clone the repository
git clone https://github.com/rifaterdemsahin/workstation.git C:\projects\workstation

# Restore the profile
$profileBackup = "C:\projects\workstation\6_Symbols\powershell_profile\Microsoft.PowerShell_profile.ps1"
$profileDir = Split-Path $PROFILE -Parent

# Create profile directory if it doesn't exist
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force
}

# Copy backup to profile location
Copy-Item $profileBackup -Destination $PROFILE -Force

# Reload profile
. $PROFILE
```

---

## Troubleshooting

### Profile Not Loading

```powershell
# Check execution policy
Get-ExecutionPolicy

# Set execution policy to allow scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Backup Script Errors

```powershell
# Run with verbose output
.\backup_powershell_profile.ps1 -Verbose

# Check if profile exists
Test-Path $PROFILE

# Check if backup directory is writable
Test-Path "C:\projects\workstation\6_Symbols\powershell_profile" -IsValid
```

---

**Created**: 2026-02-28
**Purpose**: PowerShell profile version control and disaster recovery

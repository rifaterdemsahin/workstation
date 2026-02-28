# PowerShell Profile Backup Script
# Purpose: Backs up PowerShell profile to workstation repository
# Location: 6_Symbols/powershell_profile/

# Configuration
$RepoPath = "C:\projects\workstation\6_Symbols\powershell_profile"
$BackupFileName = "Microsoft.PowerShell_profile.ps1"
$BackupPath = Join-Path $RepoPath $BackupFileName
$TimestampedBackup = Join-Path $RepoPath "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"

# Function to log messages
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Type) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

try {
    Write-Log "Starting PowerShell profile backup..."

    # Check if PowerShell profile exists
    if (-not (Test-Path $PROFILE)) {
        Write-Log "PowerShell profile not found at: $PROFILE" "ERROR"
        Write-Log "Create a profile first: New-Item -Path `$PROFILE -ItemType File -Force" "WARNING"
        exit 1
    }

    # Ensure backup directory exists
    if (-not (Test-Path $RepoPath)) {
        New-Item -ItemType Directory -Path $RepoPath -Force | Out-Null
        Write-Log "Created backup directory: $RepoPath" "SUCCESS"
    }

    # Create current backup (overwrites previous)
    Copy-Item -Path $PROFILE -Destination $BackupPath -Force
    Write-Log "Backed up profile to: $BackupPath" "SUCCESS"

    # Create timestamped backup (keeps history)
    Copy-Item -Path $PROFILE -Destination $TimestampedBackup -Force
    Write-Log "Created timestamped backup: $TimestampedBackup" "SUCCESS"

    # Display profile info
    $profileContent = Get-Content $PROFILE
    $lineCount = $profileContent.Count
    $fileSize = (Get-Item $PROFILE).Length

    Write-Log "Profile statistics:" "INFO"
    Write-Log "  - Location: $PROFILE" "INFO"
    Write-Log "  - Lines: $lineCount" "INFO"
    Write-Log "  - Size: $fileSize bytes" "INFO"

    # Cleanup old timestamped backups (keep only last 10)
    $oldBackups = Get-ChildItem -Path $RepoPath -Filter "backup_*.ps1" |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -Skip 10

    if ($oldBackups) {
        foreach ($backup in $oldBackups) {
            Remove-Item $backup.FullName -Force
            Write-Log "Removed old backup: $($backup.Name)" "INFO"
        }
    }

    Write-Log "Backup completed successfully!" "SUCCESS"
    Write-Log "To restore, copy from: $BackupPath" "INFO"

}
catch {
    Write-Log "Backup failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

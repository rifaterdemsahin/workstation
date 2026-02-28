# ==============================================================================
# Install PowerShell Profile Symlink
# ==============================================================================
# This script creates a symbolic link from the PowerShell profile location
# to the version-controlled profile in the workstation repository.
# ==============================================================================

#Requires -RunAsAdministrator

$rocket = [System.Char]::ConvertFromUtf32(0x1F680)
$check = [System.Char]::ConvertFromUtf32(0x2705)
$cross = [System.Char]::ConvertFromUtf32(0x274C)
$warning = [System.Char]::ConvertFromUtf32(0x26A0)
$info = [System.Char]::ConvertFromUtf32(0x2139)

Write-Host "`n$rocket PowerShell Profile Symlink Installer`n" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor DarkCyan

# Define paths
$repoProfile = "C:\projects\workstation\6_Symbols\powershell_profile\Microsoft.PowerShell_profile.ps1"
$targetProfile = $PROFILE
$targetDir = Split-Path $targetProfile -Parent

Write-Host "$info Repository Profile: $repoProfile" -ForegroundColor White
Write-Host "$info Target Profile: $targetProfile`n" -ForegroundColor White

# Check if repository profile exists
if (-not (Test-Path $repoProfile)) {
    Write-Host "$cross ERROR: Repository profile not found!" -ForegroundColor Red
    Write-Host "Expected location: $repoProfile" -ForegroundColor Yellow
    exit 1
}

# Create target directory if it doesn't exist
if (-not (Test-Path $targetDir)) {
    Write-Host "$info Creating PowerShell profile directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "$check Directory created: $targetDir" -ForegroundColor Green
}

# Check if target profile exists
if (Test-Path $targetProfile) {
    # Check if it's already a symlink
    $item = Get-Item $targetProfile
    if ($item.LinkType -eq "SymbolicLink") {
        $linkTarget = $item.Target
        if ($linkTarget -eq $repoProfile) {
            Write-Host "$check Symlink already exists and points to the correct location!" -ForegroundColor Green
            Write-Host "$info No action needed.`n" -ForegroundColor DarkGray
            exit 0
        }
        else {
            Write-Host "$warning Symlink exists but points to: $linkTarget" -ForegroundColor Yellow
            $response = Read-Host "Replace with new symlink? (Y/N)"
            if ($response -ne 'Y' -and $response -ne 'y') {
                Write-Host "$cross Operation cancelled by user." -ForegroundColor Red
                exit 1
            }
            Remove-Item $targetProfile -Force
            Write-Host "$check Old symlink removed." -ForegroundColor Green
        }
    }
    else {
        # It's a real file, backup first
        $backupPath = "$targetProfile.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "$warning Existing profile found (not a symlink)" -ForegroundColor Yellow
        Write-Host "$info Backing up to: $backupPath" -ForegroundColor Yellow

        Copy-Item $targetProfile $backupPath -Force
        Write-Host "$check Backup created successfully!" -ForegroundColor Green

        Remove-Item $targetProfile -Force
        Write-Host "$check Old profile removed." -ForegroundColor Green
    }
}

# Create the symbolic link
try {
    Write-Host "`n$rocket Creating symbolic link..." -ForegroundColor Cyan
    New-Item -ItemType SymbolicLink -Path $targetProfile -Target $repoProfile -Force | Out-Null
    Write-Host "$check Symlink created successfully!`n" -ForegroundColor Green

    # Verify the symlink
    $item = Get-Item $targetProfile
    if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $repoProfile) {
        Write-Host "$check Verification passed!" -ForegroundColor Green
        Write-Host "$info Your PowerShell profile is now linked to the repository.`n" -ForegroundColor DarkGray
    }
    else {
        Write-Host "$warning Verification failed! Please check manually." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "$cross ERROR: Failed to create symlink!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host "===========================================" -ForegroundColor DarkCyan
Write-Host "$check Installation complete!" -ForegroundColor Cyan
Write-Host "`n$info Next steps:" -ForegroundColor Yellow
Write-Host "  1. Close and reopen PowerShell to load the new profile" -ForegroundColor White
Write-Host "  2. Type 'help-profile' to see available commands`n" -ForegroundColor White

# PowerShell Script to Create Windows Startup Shortcut
# Purpose: Create a startup shortcut for the Chrome URL launcher
# Date: $(Get-Date -Format "yyyy-MM-dd")
# Version: 1.0

# Set error handling
$ErrorActionPreference = "Continue"

# Configuration
$ScriptPath = "C:\projects\workstation\6_Symbols\startup\startup_chrome_launcher.ps1"
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutName = "Chrome URL Launcher.lnk"
$ShortcutPath = Join-Path -Path $StartupFolder -ChildPath $ShortcutName

# Function to create startup shortcut
function New-StartupShortcut {
    try {
        Write-Host "Creating startup shortcut..." -ForegroundColor Cyan
        
        # Create WScript.Shell object
        $WshShell = New-Object -ComObject WScript.Shell
        
        # Create shortcut
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
        $Shortcut.WorkingDirectory = Split-Path -Parent $ScriptPath
        $Shortcut.Description = "Chrome URL Launcher - Opens Telegram and Gemini on startup"
        $Shortcut.Save()
        
        Write-Host "Startup shortcut created successfully: $ShortcutPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error creating startup shortcut: $_" -ForegroundColor Red
        return $false
    }
}

# Function to create scheduled task (alternative method)
function New-ScheduledTask {
    try {
        Write-Host "Creating scheduled task..." -ForegroundColor Cyan
        
        # Task name
        $TaskName = "Chrome URL Launcher"
        
        # Check if task already exists
        $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($ExistingTask) {
            Write-Host "Scheduled task already exists. Removing old task..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
        
        # Create task action
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
        
        # Create task trigger (at startup)
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        
        # Create task settings
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Register the task
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Launches Chrome with Telegram and Gemini URLs at Windows startup"
        
        Write-Host "Scheduled task created successfully: $TaskName" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error creating scheduled task: $_" -ForegroundColor Red
        return $false
    }
}

# Function to test the startup script
function Test-StartupScript {
    try {
        Write-Host "Testing startup script..." -ForegroundColor Cyan
        
        if (-not (Test-Path $ScriptPath)) {
            Write-Host "Startup script not found at: $ScriptPath" -ForegroundColor Red
            return $false
        }
        
        # Test PowerShell syntax
        $SyntaxCheck = Get-Command -Name $ScriptPath -ErrorAction SilentlyContinue
        if (-not $SyntaxCheck) {
            Write-Host "Testing PowerShell syntax..." -ForegroundColor Yellow
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScriptPath -Raw), [ref]$null)
        }
        
        Write-Host "Startup script syntax is valid" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error testing startup script: $_" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "🚀 Chrome URL Launcher Startup Setup" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Cyan
    
    # Test the startup script first
    if (-not (Test-StartupScript)) {
        Write-Host "Startup script test failed. Cannot create startup entries." -ForegroundColor Red
        exit 1
    }
    
    # Create startup folder if it doesn't exist
    if (-not (Test-Path $StartupFolder)) {
        New-Item -ItemType Directory -Path $StartupFolder -Force | Out-Null
        Write-Host "Created startup folder: $StartupFolder" -ForegroundColor Green
    }
    
    # Create startup shortcut
    $shortcutSuccess = New-StartupShortcut
    
    # Create scheduled task as backup
    $taskSuccess = New-ScheduledTask
    
    Write-Host "`n=======================================" -ForegroundColor Green
    Write-Host "✅ Startup Setup Completed!" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
    
    if ($shortcutSuccess) {
        Write-Host "• Startup shortcut created: $ShortcutPath" -ForegroundColor White
    }
    
    if ($taskSuccess) {
        Write-Host "• Scheduled task created: Chrome URL Launcher" -ForegroundColor White
    }
    
    Write-Host "`nThe Chrome URL launcher will now run automatically at Windows startup." -ForegroundColor Cyan
    Write-Host "URLs that will be opened:" -ForegroundColor Cyan
    Write-Host "  • https://web.telegram.org/a/#-1002793496878" -ForegroundColor White
    Write-Host "  • https://gemini.google.com/app/a4012a0daa4ad70d" -ForegroundColor White
    
    Write-Host "`nTo test immediately, run:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$ScriptPath`"" -ForegroundColor White
    
} catch {
    Write-Host "`n=======================================" -ForegroundColor Red
    Write-Host "❌ Setup failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=======================================" -ForegroundColor Red
}

Write-Host "`nPress Enter to close..." -ForegroundColor Yellow
Read-Host | Out-Null

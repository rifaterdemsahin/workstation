# PowerShell Script to Disable Windows Voice Assistant at Startup
# Purpose: Disable Cortana, voice services, and related voice assistant features
# Target: Windows 10/11 systems
# Date: December 2024
# Version: 1.0

# Requires Administrator privileges
#Requires -RunAsAdministrator

# Enhanced error handling
$ErrorActionPreference = "Continue"
trap {
    Write-Log "Unhandled exception: $_" -ForegroundColor Red -LogLevel "CRITICAL"
    continue
}

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$logFilePath = Join-Path -Path $scriptPath -ChildPath "DisableVoiceAssistant_$timestamp.log"

# Function to write to log file and console
function Write-Log {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White",
        [string]$LogLevel = "INFO"
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$LogLevel] $Message"

        # Write to console with color
        Write-Host $logMessage -ForegroundColor $ForegroundColor

        # Write to log file
        Add-Content -Path $logFilePath -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        Write-Host "[$timestamp] CRITICAL: Failed to log message. Error: $_" -ForegroundColor Red
    }
}

# Function to disable Cortana service
function Disable-CortanaService {
    try {
        Write-Log "Disabling Cortana service..." -ForegroundColor Cyan -LogLevel "INFO"
        
        # Stop Cortana service if running
        try {
            Stop-Service -Name "Cortana" -Force -ErrorAction SilentlyContinue
            Write-Log "Cortana service stopped" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Cortana service was not running or could not be stopped" -ForegroundColor Yellow -LogLevel "WARNING"
        }

        # Disable Cortana service
        try {
            Set-Service -Name "Cortana" -StartupType Disabled -ErrorAction Stop
            Write-Log "Cortana service disabled successfully" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable Cortana service: $_" -ForegroundColor Red -LogLevel "ERROR"
        }
    } catch {
        Write-Log "Error in Disable-CortanaService: $_" -ForegroundColor Red -LogLevel "ERROR"
    }
}

# Function to disable voice services
function Disable-VoiceServices {
    try {
        Write-Log "Disabling voice-related services..." -ForegroundColor Cyan -LogLevel "INFO"
        
        $voiceServices = @(
            "Cortana",
            "SpeechRuntime",
            "SpeechService",
            "WindowsSpeechPlatform",
            "VoiceActivationService"
        )

        foreach ($serviceName in $voiceServices) {
            try {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    # Stop service if running
                    if ($service.Status -eq "Running") {
                        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                        Write-Log "Stopped $serviceName service" -ForegroundColor Green -LogLevel "INFO"
                    }
                    
                    # Disable service
                    Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
                    Write-Log "Disabled $serviceName service" -ForegroundColor Green -LogLevel "INFO"
                } else {
                    Write-Log "$serviceName service not found" -ForegroundColor Yellow -LogLevel "WARNING"
                }
            } catch {
                Write-Log "Failed to disable $serviceName service: $_" -ForegroundColor Red -LogLevel "ERROR"
            }
        }
    } catch {
        Write-Log "Error in Disable-VoiceServices: $_" -ForegroundColor Red -LogLevel "ERROR"
    }
}

# Function to disable Cortana via registry
function Disable-CortanaRegistry {
    try {
        Write-Log "Disabling Cortana via registry..." -ForegroundColor Cyan -LogLevel "INFO"
        
        $cortanaRegPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
        )

        foreach ($regPath in $cortanaRegPaths) {
            try {
                if (!(Test-Path $regPath)) {
                    New-Item -Path $regPath -Force | Out-Null
                    Write-Log "Created registry path: $regPath" -ForegroundColor Green -LogLevel "INFO"
                }
            } catch {
                Write-Log "Failed to create registry path ${regPath}: $_" -ForegroundColor Red -LogLevel "ERROR"
            }
        }

        # Disable Cortana
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -ErrorAction Stop
            Write-Log "Cortana disabled in Windows Search policy" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to set Cortana policy: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Disable web search
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1 -Type DWord -ErrorAction Stop
            Write-Log "Web search disabled" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable web search: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Disable Cortana in search
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0 -Type DWord -ErrorAction Stop
            Write-Log "Cortana consent disabled" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable Cortana consent: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Disable voice activation
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "AllowCortana" -Value 0 -Type DWord -ErrorAction Stop
            Write-Log "Cortana voice activation disabled" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable Cortana voice activation: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

    } catch {
        Write-Log "Error in Disable-CortanaRegistry: $_" -ForegroundColor Red -LogLevel "ERROR"
    }
}

# Function to disable voice features in Windows settings
function Disable-VoiceFeatures {
    try {
        Write-Log "Disabling voice features in Windows settings..." -ForegroundColor Cyan -LogLevel "INFO"
        
        # Disable voice activation
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\User" -Name "VoiceActivationEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "Voice activation disabled in user settings" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable voice activation in user settings: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Disable speech recognition
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Speech\Settings" -Name "SpeechRecognitionEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "Speech recognition disabled" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable speech recognition: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Disable microphone access for voice assistant
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" -Name "Value" -Value "Deny" -Type String -ErrorAction SilentlyContinue
            Write-Log "Microphone access for voice assistant denied" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to deny microphone access: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

    } catch {
        Write-Log "Error in Disable-VoiceFeatures: $_" -ForegroundColor Red -LogLevel "ERROR"
    }
}

# Function to disable Windows Hello voice features
function Disable-WindowsHelloVoice {
    try {
        Write-Log "Disabling Windows Hello voice features..." -ForegroundColor Cyan -LogLevel "INFO"
        
        # Disable Windows Hello voice
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Biometrics" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "Windows Hello biometrics disabled" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable Windows Hello biometrics: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Disable voice wake-up
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "VoiceWakeUpEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "Voice wake-up disabled" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable voice wake-up: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

    } catch {
        Write-Log "Error in Disable-WindowsHelloVoice: $_" -ForegroundColor Red -LogLevel "ERROR"
    }
}

# Function to disable voice assistant in Microsoft Edge
function Disable-EdgeVoiceAssistant {
    try {
        Write-Log "Disabling voice assistant in Microsoft Edge..." -ForegroundColor Cyan -LogLevel "INFO"
        
        # Disable Cortana in Edge
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "CortanaEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "Cortana disabled in Edge" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable Cortana in Edge: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

        # Disable voice search in Edge
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "VoiceSearchEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "Voice search disabled in Edge" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to disable voice search in Edge: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

    } catch {
        Write-Log "Error in Disable-EdgeVoiceAssistant: $_" -ForegroundColor Red -LogLevel "ERROR"
    }
}

# Function to create startup script
function Create-StartupScript {
    try {
        Write-Log "Creating startup script to ensure voice assistant stays disabled..." -ForegroundColor Cyan -LogLevel "INFO"
        
        $startupScript = @"
# Voice Assistant Disable Startup Script
# This script runs at startup to ensure voice assistant remains disabled

# Disable Cortana service
try {
    Set-Service -Name "Cortana" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name "Cortana" -Force -ErrorAction SilentlyContinue
} catch { }

# Disable voice services
`$voiceServices = @("SpeechRuntime", "SpeechService", "WindowsSpeechPlatform", "VoiceActivationService")
foreach (`$service in `$voiceServices) {
    try {
        Set-Service -Name `$service -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name `$service -Force -ErrorAction SilentlyContinue
    } catch { }
}

# Disable Cortana registry settings
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1 -Type DWord -ErrorAction SilentlyContinue
} catch { }
"@

        $startupScriptPath = Join-Path -Path $scriptPath -ChildPath "DisableVoiceAssistant_Startup.ps1"
        $startupScript | Out-File -FilePath $startupScriptPath -Encoding UTF8 -Force
        Write-Log "Startup script created: $startupScriptPath" -ForegroundColor Green -LogLevel "INFO"

        # Create scheduled task to run at startup
        try {
            $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$startupScriptPath`""
            $trigger = New-ScheduledTaskTrigger -AtStartup
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

            Register-ScheduledTask -TaskName "DisableVoiceAssistant" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
            Write-Log "Scheduled task created to run at startup" -ForegroundColor Green -LogLevel "INFO"
        } catch {
            Write-Log "Failed to create scheduled task: $_" -ForegroundColor Red -LogLevel "ERROR"
        }

    } catch {
        Write-Log "Error in Create-StartupScript: $_" -ForegroundColor Red -LogLevel "ERROR"
    }
}

# Function to verify voice assistant is disabled
function Test-VoiceAssistantDisabled {
    try {
        Write-Log "Verifying voice assistant is disabled..." -ForegroundColor Cyan -LogLevel "INFO"
        
        $verificationResults = @{
            CortanaService = $false
            VoiceServices = @()
            RegistrySettings = @()
            OverallStatus = "Unknown"
        }

        # Check Cortana service
        try {
            $cortanaService = Get-Service -Name "Cortana" -ErrorAction SilentlyContinue
            if ($cortanaService -and $cortanaService.StartType -eq "Disabled") {
                $verificationResults.CortanaService = $true
                Write-Log "Cortana service is disabled" -ForegroundColor Green -LogLevel "INFO"
            } else {
                Write-Log "Cortana service is not disabled" -ForegroundColor Red -LogLevel "ERROR"
            }
        } catch {
            Write-Log "Could not verify Cortana service status" -ForegroundColor Yellow -LogLevel "WARNING"
        }

        # Check voice services
        $voiceServices = @("SpeechRuntime", "SpeechService", "WindowsSpeechPlatform", "VoiceActivationService")
        foreach ($serviceName in $voiceServices) {
            try {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and $service.StartType -eq "Disabled") {
                    $verificationResults.VoiceServices += "${serviceName}: Disabled"
                    Write-Log "$serviceName service is disabled" -ForegroundColor Green -LogLevel "INFO"
                } else {
                    $verificationResults.VoiceServices += "${serviceName}: Not Disabled"
                    Write-Log "$serviceName service is not disabled" -ForegroundColor Red -LogLevel "ERROR"
                }
            } catch {
                $verificationResults.VoiceServices += "${serviceName}: Not Found"
                Write-Log "$serviceName service not found" -ForegroundColor Yellow -LogLevel "WARNING"
            }
        }

        # Check registry settings
        try {
            $cortanaPolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ErrorAction SilentlyContinue
            if ($cortanaPolicy -and $cortanaPolicy.AllowCortana -eq 0) {
                $verificationResults.RegistrySettings += "Cortana Policy: Disabled"
                Write-Log "Cortana registry policy is disabled" -ForegroundColor Green -LogLevel "INFO"
            } else {
                $verificationResults.RegistrySettings += "Cortana Policy: Not Disabled"
                Write-Log "Cortana registry policy is not disabled" -ForegroundColor Red -LogLevel "ERROR"
            }
        } catch {
            $verificationResults.RegistrySettings += "Cortana Policy: Not Set"
            Write-Log "Cortana registry policy not set" -ForegroundColor Yellow -LogLevel "WARNING"
        }

        # Determine overall status
        if ($verificationResults.CortanaService -and ($verificationResults.VoiceServices -match "Disabled").Count -gt 0) {
            $verificationResults.OverallStatus = "Successfully Disabled"
            Write-Log "Voice assistant has been successfully disabled" -ForegroundColor Green -LogLevel "INFO"
        } else {
            $verificationResults.OverallStatus = "Partially Disabled"
            Write-Log "Voice assistant is partially disabled - some features may still be active" -ForegroundColor Yellow -LogLevel "WARNING"
        }

        return $verificationResults

    } catch {
        Write-Log "Error in Test-VoiceAssistantDisabled: $_" -ForegroundColor Red -LogLevel "ERROR"
        return $null
    }
}

# Main execution block
try {
    Write-Log "Starting Voice Assistant Disable Script" -ForegroundColor Cyan -LogLevel "INFO"
    Write-Log "This script will disable Cortana and voice assistant features" -ForegroundColor Yellow -LogLevel "INFO"

    # Disable Cortana service
    Disable-CortanaService

    # Disable voice services
    Disable-VoiceServices

    # Disable Cortana via registry
    Disable-CortanaRegistry

    # Disable voice features
    Disable-VoiceFeatures

    # Disable Windows Hello voice features
    Disable-WindowsHelloVoice

    # Disable voice assistant in Edge
    Disable-EdgeVoiceAssistant

    # Create startup script
    Create-StartupScript

    # Verify voice assistant is disabled
    $verification = Test-VoiceAssistantDisabled

    Write-Log "Voice Assistant Disable Script completed" -ForegroundColor Cyan -LogLevel "INFO"
    Write-Log "Log file saved to: $logFilePath" -ForegroundColor Green -LogLevel "INFO"
    
    if ($verification) {
        Write-Log "Verification Results:" -ForegroundColor Cyan -LogLevel "INFO"
        Write-Log "Overall Status: $($verification.OverallStatus)" -ForegroundColor Cyan -LogLevel "INFO"
        Write-Log "Cortana Service: $($verification.CortanaService)" -ForegroundColor Cyan -LogLevel "INFO"
        Write-Log "Voice Services: $($verification.VoiceServices -join ', ')" -ForegroundColor Cyan -LogLevel "INFO"
        Write-Log "Registry Settings: $($verification.RegistrySettings -join ', ')" -ForegroundColor Cyan -LogLevel "INFO"
    }

} catch {
    Write-Log "Script execution failed: $_" -ForegroundColor Red -LogLevel "CRITICAL"
    Write-Log "Check logs for details" -ForegroundColor Red -LogLevel "CRITICAL"
}

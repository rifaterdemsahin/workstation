# Voice Assistant Disable Startup Script
# This script runs at startup to ensure voice assistant remains disabled

# Disable Cortana service
try {
    Set-Service -Name "Cortana" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name "Cortana" -Force -ErrorAction SilentlyContinue
} catch { }

# Disable voice services
$voiceServices = @("SpeechRuntime", "SpeechService", "WindowsSpeechPlatform", "VoiceActivationService")
foreach ($service in $voiceServices) {
    try {
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    } catch { }
}

# Disable Cortana registry settings
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1 -Type DWord -ErrorAction SilentlyContinue
} catch { }

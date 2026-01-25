# PowerShell Script to Launch Gemini Agent in Second Brain
# Purpose: Open a new terminal window, navigate to Second Brain repo, and start Gemini
# Date: $(Get-Date -Format "yyyy-MM-dd")

$SecondBrainPath = "F:\secondbrain_v4\secondbrain"
if (-not (Test-Path $SecondBrainPath)) {
    $SecondBrainPath = "F:\secondbrain_v4\secondbrain"
}

if (Test-Path $SecondBrainPath) {
    Write-Host "Launching Gemini in $SecondBrainPath..." -ForegroundColor Cyan
    
    # Start a new PowerShell process that stays open (-NoExit)
    # navigate to the directory and run gemini
    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "Set-Location '$SecondBrainPath'; Write-Host 'Starting Gemini...'; gemini"
}
else {
    Write-Host "Error: Second Brain repository not found at '$SecondBrainPath' " -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}

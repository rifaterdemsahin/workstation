# School Run Status Sender
# ========================

Write-Host "`n== School Run Status Script ==" -ForegroundColor Cyan

# 1. Wait for focus
Write-Host "`nWaiting 2 seconds for you to click into Teams/Slack..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
Write-Host "Done waiting." -ForegroundColor Green

# 2. Define phrases
$phrases = @(
    "I'm heading out for the school run, but I'll be back online and ready to go shortly!",
    "I'll be away for a brief window to handle the school run - looking forward to reconnecting as soon as I'm back.",
    "Off to go grab the kids! I'll be back in the swing of things in just a bit.",
    "Time for the afternoon school run! I'll be back at my desk before you know it.",
    "Just stepping out for the school run - talk soon!",
    "Brief pause for the school run! I'll be back and available shortly."
)

Write-Host "`nLoaded $($phrases.Count) phrases." -ForegroundColor Cyan

# 3. Pick random phrase
$randomPhrase = $phrases | Get-Random
Write-Host "`nSelected phrase:" -ForegroundColor Magenta
Write-Host "   $randomPhrase" -ForegroundColor White

# 4. Copy to clipboard
Set-Clipboard -Value $randomPhrase
Write-Host "`nCopied to clipboard." -ForegroundColor Green
Write-Host "`nStream Deck will now paste and send!" -ForegroundColor Cyan
Write-Host "==============================`n" -ForegroundColor Cyan
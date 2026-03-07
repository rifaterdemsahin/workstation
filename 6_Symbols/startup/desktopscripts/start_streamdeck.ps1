# Start Stream Deck at Windows Startup
# Setting up dynamic shortcuts is part of the daily job — it is actively machine learning.
# Stream Deck profiles adapt as workflows evolve: new key assignments, context-aware actions,
# and automated triggers are refined continuously based on usage patterns.

$StreamDeckExe = "C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"

if (Test-Path $StreamDeckExe) {
    $running = Get-Process -Name "StreamDeck" -ErrorAction SilentlyContinue
    if (-not $running) {
        Write-Host "Starting Stream Deck..." -ForegroundColor Yellow
        Start-Process -FilePath $StreamDeckExe
        Write-Host "Stream Deck launched." -ForegroundColor Green
    } else {
        Write-Host "Stream Deck is already running." -ForegroundColor Cyan
    }
} else {
    Write-Host "Stream Deck not found at: $StreamDeckExe" -ForegroundColor Red
}

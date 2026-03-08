# --- CONFIGURATION ---
$ProfileName = "February2026"
$DesktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop", "$ProfileName.sdProfile")
if (!(Test-Path $DesktopPath)) { New-Item -ItemType Directory -Path $DesktopPath -Force }

# Your Dashboard Data
$Links = @(
    @{Title="📊 Prometheus"; Url="http://localhost:9090/graph"},
    @{Title="🗺️ Consciousness"; Url="http://localhost:3000/MapOfConsciousness"},
    @{Title="🛠️ Local 3001"; Url="http://localhost:3001/"},
    @{Title="🤖 Stable Diff"; Url="http://localhost:7860/"},
    @{Title="📦 Qdrant"; Url="http://192.168.2.227:6333/dashboard"},
    @{Title="🌐 Router"; Url="http://192.168.3.1/#Dashboard"},
    @{Title="✨ Gemini"; Url="https://gemini.google.com/"},
    @{Title="☁️ Claude"; Url="https://claude.ai/"},
    @{Title="💬 ChatGPT"; Url="https://chatgpt.com/"},
    @{Title="🎞️ DaVinci"; Url="https://www.blackmagicdesign.com/products/davinciresolve/training"},
    @{Title="📺 YT Studio"; Url="https://studio.youtube.com/"},
    @{Title="📩 Gmail"; Url="https://mail.google.com/mail/u/0/#drafts"},
    @{Title="💳 GCP Billing"; Url="https://console.cloud.google.com/billing"},
    @{Title="🚚 Delivery Pilot"; Url="https://github.com/rifaterdemsahin/delivery-pilot-web"},
    @{Title="👾 Discord"; Url="https://discord.com/channels/@me"}
)

# --- GENERATE MANIFEST ---
$Actions = @{}
$Row = 0
$Col = 0

foreach ($Link in $Links) {
    $UUID = [guid]::NewGuid().ToString().ToUpper()
    $Coordinates = "$Row,$Col"

    $Actions[$Coordinates] = @{
        "Action" = "com.elgato.streamdeck.system.website"
        "Name" = $Link.Title
        "Settings" = @{
            "uri" = $Link.Url
        }
        "State" = 0
        "States" = @(
            @{
                "Image" = "" # You can add custom Base64 icons here later
                "Title" = $Link.Title
                "TitleAlignment" = "Middle"
                "FontSize" = "10"
            }
        )
    }

    # Grid logic (Stream Deck XL style 8x4)
    $Col++
    if ($Col -ge 8) { $Col = 0; $Row++ }
}

$Manifest = @{
    "DeviceModel" = "Stream Deck XL"
    "Name" = $ProfileName
    "Actions" = $Actions
}

# --- SAVE FILE ---
$ManifestJson = $Manifest | ConvertTo-Json -Depth 10
Set-Content -Path (Join-Path $DesktopPath "manifest.json") -Value $ManifestJson

Write-Host "--- DONE! ---" -ForegroundColor Green
Write-Host "1. Go to your Desktop."
Write-Host "2. Double-click the 'February2026.sdProfile' folder."
Write-Host "3. Stream Deck will ask to import the profile."

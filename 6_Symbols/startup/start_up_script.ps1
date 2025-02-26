# 🔙 Backup link: https://github.com/rifaterdemsahin/workstation/blob/master/6_Symbols/startup/start_up_script.ps1
Write-Debug "Script started on $(Get-Date)"

# 📱 Launch WhatsApp
Write-Debug "Launching WhatsApp"
Start-Process "whatsapp:" -ErrorAction SilentlyContinue

# 🖼️ Minimize all windows
Write-Debug "Minimizing all windows"
(New-Object -ComObject Shell.Application).MinimizeAll()

# 🌐 Define Chrome path
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
Write-Debug "Chrome path set to: $chromePath"

# 🔗 URLs array
$urls = @(
    "https://chatgpt.com/?hints=search&ref=ext&model=auto",  # ChatGPT 🤖
    "https://claude.ai/new",                                 # Claude AI 🧠
    "https://to-do.office.com/tasks/",                       # Microsoft To-Do ✅
    "https://www.perplexity.ai/",                            # Perplexity AI ❓
    "https://www.linkedin.com/",                             # LinkedIn 💼
    "https://www.gmail.com/",                                # Gmail 📧
    "https://vdo.ninja/?director=rifaterdemsahin",           # VDO Ninja 🎥
    "https://calendly.com/app/scheduled_events/user/me",     # Calendly 📅
    "https://x.com/i/grok"                                   # Grok on X 🐦
)

# 🚀 Launch Chrome windows
Write-Debug "Launching $($urls.Count) Chrome windows"
foreach ($url in $urls) {
    if (Test-Path $chromePath) {
        Write-Debug "Opening: $url"
        Start-Process $chromePath -ArgumentList "--new-window", $url -ErrorAction Continue
    } else {
        Write-Warning "Chrome not found at: $chromePath"
        break
    }
}

# 🎬 Launch OBS Studio
$obsPath = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
$obsWorkingDirectory = "C:\Program Files\obs-studio\bin\64bit"
Write-Debug "Checking OBS at: $obsPath"
if (Test-Path $obsPath) {
    Write-Debug "Launching OBS Studio with admin privileges"
    Start-Process -FilePath $obsPath -WorkingDirectory $obsWorkingDirectory -Verb RunAs -ErrorAction Continue
} else {
    Write-Warning "🎥 OBS Studio not found at: $obsPath"
}

# 🤖 Launch LM Studio
$lmStudioPath = "C:\Users\Pexabo\AppData\Local\Programs\LM Studio\LM Studio.exe"
Write-Debug "Checking LM Studio at: $lmStudioPath"
if (Test-Path $lmStudioPath) {
    Write-Debug "Launching LM Studio with admin privileges"
    Start-Process -FilePath $lmStudioPath -Verb RunAs -ErrorAction Continue
} else {
    Write-Warning "🤖 LM Studio not found at: $lmStudioPath"
}

# 📚 Launch AnythingLLM
$anythingLLMPath = "C:\Users\Pexabo\AppData\Local\Programs\AnythingLLM\AnythingLLM.exe"
Write-Debug "Checking AnythingLLM at: $anythingLLMPath"
if (Test-Path $anythingLLMPath) {
    Write-Debug "Launching AnythingLLM"
    Start-Process -FilePath $anythingLLMPath -ErrorAction Continue
} else {
    Write-Warning "📚 AnythingLLM not found at: $anythingLLMPath"
}

# ✍️ Launch Obsidian
$obsidianPath = "C:\Users\Pexabo\AppData\Local\Programs\Obsidian\Obsidian.exe"
Write-Debug "Checking Obsidian at: $obsidianPath"
if (Test-Path $obsidianPath) {
    Write-Debug "Launching Obsidian"
    Start-Process -FilePath $obsidianPath -ErrorAction Continue
} else {
    Write-Warning "✍️ Obsidian not found at: $obsidianPath"
}

# 🎮 Launch Stream Deck
$streamDeckPath = "C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"
Write-Debug "Checking Stream Deck at: $streamDeckPath"
if (Test-Path $streamDeckPath) {
    Write-Debug "Launching Stream Deck"
    Start-Process -FilePath $streamDeckPath -ErrorAction Continue
} else {
    Write-Warning "🎮 Stream Deck not found at: $streamDeckPath"
}

# 🛠️ Launch Visual Studio Code
$vscodePath = "C:\Users\Pexabo\AppData\Local\Programs\Microsoft VS Code\Code.exe"
Write-Debug "Checking VS Code at: $vscodePath"
if (Test-Path $vscodePath) {
    Write-Debug "Launching Visual Studio Code"
    Start-Process -FilePath $vscodePath -ErrorAction Continue
} else {
    Write-Warning "🛠️ Visual Studio Code not found at: $vscodePath"
}

# 🖥️ Open PowerShell to Update Chocolatey Packages
$powershellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
Write-Debug "Checking PowerShell at: $powershellPath"
if (Test-Path $powershellPath) {
    Write-Debug "Launching PowerShell to update Chocolatey packages"
    $chocoUpdateCommand = "Start-Process choco -ArgumentList 'upgrade all -y' -Verb RunAs"
    Start-Process -FilePath $powershellPath -ArgumentList "-NoExit", "-Command", $chocoUpdateCommand -ErrorAction Continue
} else {
    Write-Warning "🖥️ PowerShell not found at: $powershellPath"
}

# ⚙️ Open Windows Update Settings
Write-Debug "Opening Windows Update settings"
Start-Process "ms-settings:windowsupdate" -ErrorAction Continue

# Start Docker Desktop
$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerDesktopPath) {
    Start-Process -FilePath $dockerDesktopPath
} else {
    Write-Warning "Docker Desktop not found at: $dockerDesktopPath"
}


Write-Debug "Script completed on $(Get-Date)"

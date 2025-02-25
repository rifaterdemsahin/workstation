# Backup here > https://github.com/rifaterdemsahin/workstation/blob/master/6_Symbols/startup/start_up_script.ps1
# Launch WhatsApp
Start-Process "whatsapp:"

# Minimize all windows
(New-Object -ComObject Shell.Application).MinimizeAll()

# Define the path to Chrome executable
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# URLs to open in Chrome instances
$urls = @(
    "https://chatgpt.com/?hints=search&ref=ext&model=auto",
    "https://claude.ai/new",
    "https://to-do.office.com/tasks/",
    "https://www.perplexity.ai/",
    "https://www.linkedin.com/",  # Fixed missing comma
    "https://www.gmail.com/",     # Fixed missing comma
    "https://vdo.ninja/?director=rifaterdemsahin",
    "https://calendly.com/app/scheduled_events/user/me"
    
)

# Launch each URL in a new Chrome window
foreach ($url in $urls) {
    Start-Process $chromePath -ArgumentList "--new-window", $url
}

# Launch OBS Studio with administrative privileges
$obsPath = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
$obsWorkingDirectory = "C:\Program Files\obs-studio\bin\64bit"
if (Test-Path $obsPath) {
    Start-Process -FilePath $obsPath -WorkingDirectory $obsWorkingDirectory -Verb RunAs
} else {
    Write-Warning "OBS Studio not found at specified path: $obsPath"
}

# Launch LM Studio with administrative privileges
$lmStudioPath = "C:\Users\Pexabo\AppData\Local\Programs\LM Studio\LM Studio.exe"
if (Test-Path $lmStudioPath) {
    Start-Process -FilePath $lmStudioPath -Verb RunAs
} else {
    Write-Warning "LM Studio not found at specified path: $lmStudioPath"
}

# Launch AnythingLLM
$anythingLLMPath = "C:\Users\Pexabo\AppData\Local\Programs\AnythingLLM\AnythingLLM.exe"
if (Test-Path $anythingLLMPath) {
    Start-Process -FilePath $anythingLLMPath
} else {
    Write-Warning "AnythingLLM not found at specified path: $anythingLLMPath"
}


# Launch onsidian
$obsidianPath = "C:\Users\Pexabo\AppData\Local\Programs\Obsidian\Obsidian.exe"
if (Test-Path $obsidianPath) {
    Start-Process -FilePath $anythingLLMPath
} else {
    Write-Warning "AnythingLLM not found at specified path: $obsidianPath"
}

open streamdeck
"C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"

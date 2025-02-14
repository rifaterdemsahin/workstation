# Launch WhatsApp
Start-Process "whatsapp:"

# Define the path to Chrome executable
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# URLs to open in Chrome instances
$urls = @(
    "https://chatgpt.com/?hints=search&ref=ext&model=auto",
    "https://claude.ai/new",
    "https://to-do.office.com/tasks/",
    "https://www.perplexity.ai/",
    "https://www.linkedin.com/"
    "https://www.gmail.com/"
    "https://vdo.ninja/?director=xxx"
)

# Launch each URL in a new Chrome window
foreach ($url in $urls) {
    Start-Process $chromePath -ArgumentList "--new-window", $url
}

# Launch OBS Studio
$obsPath = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
Start-Process $obsPath

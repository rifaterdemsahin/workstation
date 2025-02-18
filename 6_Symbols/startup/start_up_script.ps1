# Launch WhatsApp
Start-Process "whatsapp:"
# Estimated RAM: 150-200 MB, VRAM: Minimal (5-10 MB)

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
    "https://vdo.ninja/?director=rifaterdemsahin"
)

# Launch each URL in a new Chrome window
foreach ($url in $urls) {
    Start-Process $chromePath -ArgumentList "--new-window", $url
}
# Estimated RAM: 200-300 MB per tab, total ~1.4-2.1 GB
# Estimated VRAM: 50-100 MB per tab, total ~350-700 MB

# Launch OBS Studio with administrative privileges
$obsPath = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
$obsWorkingDirectory = "C:\Program Files\obs-studio\bin\64bit"
Start-Process -FilePath $obsPath -WorkingDirectory $obsWorkingDirectory -Verb RunAs
# Estimated RAM: 500-800 MB
# Estimated VRAM: 500-1000 MB (depends on scenes and sources)

# Launch LM Studio with administrative privileges
$lmStudioPath = "C:\Users\Pexabo\AppData\Local\Programs\LM Studio\LM Studio.exe"
Start-Process -FilePath $lmStudioPath -Verb RunAs
# Estimated RAM: 500-1000 MB (depends on model size)
# Estimated VRAM: Varies greatly, from 2-8 GB or more depending on model size

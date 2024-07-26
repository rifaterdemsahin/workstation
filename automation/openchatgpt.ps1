# Define the URL >>> trigger >>> streamdeck open powershell.exe -Command "& {Start-Process powershell.exe -ArgumentList '-File ""C:\Users\Pexabo\Downloads\openchatgpt.ps1""'}"
$url = "https://chatgpt.com/"

# Define the path to Chrome
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Open three separate Chrome windows with the specified URL
Start-Process -FilePath $chromePath -ArgumentList $url
Start-Process -FilePath $chromePath -ArgumentList $url
Start-Process -FilePath $chromePath -ArgumentList $url

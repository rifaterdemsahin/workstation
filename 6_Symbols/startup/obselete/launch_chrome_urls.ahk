#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force  ; Ensures that only a single instance of the script runs.

; AutoHotkey Script to Launch Chrome with Specific Profile and Open URLs
; Purpose: Open Chrome with a specific profile and navigate to Telegram and Gemini URLs
; Date: %A_Now%
; Version: 1.0

; Configuration
ChromePath := "C:\Program Files\Google\Chrome\Application\chrome.exe"
ChromeProfile := "--profile-directory=`"Profile 21`""  ; Adjust profile number as needed
TelegramURL := "https://web.telegram.org/a/#-1002793496878"
GeminiURL := "https://gemini.google.com/app/a4012a0daa4ad70d"

; Log file path
LogFile := A_Desktop . "\StartupLog\TelegramGemini_Log_" . A_Now . ".txt"

; Create log directory if it doesn't exist
LogDir := A_Desktop . "\StartupLog"
if (!FileExist(LogDir)) {
    FileCreateDir, %LogDir%
}

; Logging function
LogMessage(message) {
    timestamp := A_Now
    logEntry := timestamp . " - " . message . "`n"
    FileAppend, %logEntry%, %LogFile%
    ToolTip, %message%
    Sleep, 1000
    ToolTip
}

; Function to check if Chrome exists
CheckChrome() {
    if (FileExist(ChromePath)) {
        LogMessage("Chrome found at: " . ChromePath)
        return true
    }
    
    ; Try alternative Chrome paths
    alternativePaths := ["C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
                        , A_ProgramFiles . "\Google\Chrome\Application\chrome.exe"
                        , A_ProgramFiles . " (x86)\Google\Chrome\Application\chrome.exe"]
    
    for index, path in alternativePaths {
        if (FileExist(path)) {
            ChromePath := path
            LogMessage("Chrome found at alternative path: " . path)
            return true
        }
    }
    
    LogMessage("Chrome not found in any standard location")
    return false
}

; Function to check Chrome profile
CheckChromeProfile() {
    profileName := StrReplace(ChromeProfile, "--profile-directory=`"", "")
    profileName := StrReplace(profileName, "`"", "")
    profilePath := A_LocalAppData . "\Google\Chrome\User Data\" . profileName
    
    if (FileExist(profilePath)) {
        LogMessage("Chrome profile found: " . profilePath)
        return true
    } else {
        LogMessage("Chrome profile not found, using default profile")
        ChromeProfile := ""
        return false
    }
}

; Function to launch Chrome with URL
LaunchChromeWithURL(url, delay := 2000) {
    try {
        LogMessage("Launching Chrome with URL: " . url)
        
        if (ChromeProfile != "") {
            Run, "%ChromePath%" %ChromeProfile% "%url%"
        } else {
            Run, "%ChromePath%" "%url%"
        }
        
        ; Wait for Chrome to start
        WinWait, ahk_exe chrome.exe, , 10
        if (ErrorLevel) {
            LogMessage("Timeout waiting for Chrome to start")
            return false
        }
        
        LogMessage("Chrome launched successfully for: " . url)
        Sleep, %delay%
        return true
    } catch {
        LogMessage("Error launching Chrome: " . Error)
        return false
    }
}

; Function to wait for Chrome processes
WaitForChrome(timeoutSeconds := 30) {
    LogMessage("Waiting for Chrome processes...")
    timeout := A_TickCount + (timeoutSeconds * 1000)
    
    while (A_TickCount < timeout) {
        Process, Exist, chrome.exe
        if (ErrorLevel) {
            LogMessage("Chrome processes detected")
            return true
        }
        Sleep, 500
    }
    
    LogMessage("Timeout waiting for Chrome processes")
    return false
}

; Main execution
try {
    LogMessage("=== Telegram & Gemini Chrome Launcher Started ===")
    
    ; Check if Chrome exists
    if (!CheckChrome()) {
        MsgBox, 16, Error, Chrome not found! Please install Google Chrome or update the path in the script.
        ExitApp
    }
    
    ; Check Chrome profile
    CheckChromeProfile()
    
    ; Launch Chrome with Telegram URL
    if (LaunchChromeWithURL(TelegramURL, 3000)) {
        LogMessage("Telegram URL launched successfully")
    } else {
        LogMessage("Failed to launch Telegram URL")
    }
    
    ; Launch Chrome with Gemini URL
    if (LaunchChromeWithURL(GeminiURL, 3000)) {
        LogMessage("Gemini URL launched successfully")
    } else {
        LogMessage("Failed to launch Gemini URL")
    }
    
    ; Wait for Chrome to be ready
    WaitForChrome()
    
    LogMessage("=== Script completed successfully ===")
    
    ; Show completion message
    MsgBox, 64, Success, Chrome launched successfully!`n`nURLs opened:`n• %TelegramURL%`n• %GeminiURL%`n`nCheck the log file for details: %LogFile%
    
} catch {
    LogMessage("Script error: " . Error)
    MsgBox, 16, Error, Script encountered an error!`n`nError: %Error%`n`nCheck the log file for details: %LogFile%
}

; Exit the script
ExitApp

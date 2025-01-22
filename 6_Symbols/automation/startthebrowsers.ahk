#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force  ; Ensures that only a single instance of the script runs.

; Define URLs for each monitor
url1 := "https://wordpress.com/post/rifaterdemsahin.com"
url2 := "https://www.canva.com/design/DAGCZFYwanc/KyVkBJbOmZ_NT_4dqyFb3g/edit"
url3 := "https://chat.openai.com/"
url4 := "https://mail.google.com/mail/u/0/#advanced-search/is_unread=true&query=label%3A1_borrow_followup&isrefinement=true"

; Define monitor indices (0 = primary, 1 = secondary, etc.)
monitor1 := 0
monitor2 := 1
monitor3 := 2
monitor4 := 3

; Define resolutions for each monitor
width1 := 1920
height1 := 1080
width2 := 1080
height2 := 1920
width3 := 1280
height3 := 1024
width4 := 2560
height4 := 1080

; Close LoomDeck if it's running
Process, Exist, LoomDeck.exe
If (ErrorLevel)  ; ErrorLevel will be set to the process ID if found
{
    Process, Close, %ErrorLevel%
}

; Start OBS Studio with a specific working directory
Run, "%ProgramFiles%\obs-studio\bin\64bit\obs64.exe", "%ProgramFiles%\obs-studio\bin\64bit"


; Launch Sticky Notes in Windows 10/11
Run, "shell:AppsFolder\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe!App"


; Launch URLs on specified monitors
RunURL(url1, monitor1, width1, height1)
RunURL(url2, monitor2, width2, height2)
RunURL(url3, monitor3, width3, height3)
RunURL(url4, monitor4, width4, height4)

RunURL(url, monitor, width, height) {
    ; Launch Chrome with the specified URL
    Run, % "chrome.exe --new-window " url
    WinWait, ahk_exe chrome.exe, , 10 ; Wait up to 10 seconds for the window to appear

    ; Calculate X position based on monitor index
    XPos := monitor * width

    ; Move the Chrome window to the specified monitor
    IfWinExist, ahk_exe chrome.exe
    {
        WinActivate ; Make sure the window is active
        WinMove, A,, XPos, 0, width, height ; Move and resize the window
    }
    Sleep 1000 ; Wait a moment before opening the next window to prevent overlaps
}

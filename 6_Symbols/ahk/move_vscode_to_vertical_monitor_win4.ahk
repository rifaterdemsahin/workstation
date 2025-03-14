#4::
    ; Set title match mode to allow partial matches
    SetTitleMatchMode, 2
    ; Define the partial title of the VS Code window
    WinTitle := "Visual Studio Code"
    
    ; Check if the VS Code window exists
    if !WinExist(WinTitle) {
        ; Attempt to run VS Code
        Run, code
        ; Wait for the VS Code window to appear
        WinWait, %WinTitle%,, 10 ; Wait up to 10 seconds
        if !WinExist(WinTitle) {
            MsgBox, Failed to launch VS Code.
            return
        }
    }
    
    ; Get the window ID of VS Code
    WinGet, VSCodeID, ID, %WinTitle%
    
    ; Get the number of monitors
    SysGet, MonitorCount, MonitorCount
    
    ; Assume the vertical ASUS monitor is monitor 3
    ; If you need to target a different monitor, change the monitor number below
    if (MonitorCount >= 3) {
        ; Get the bounding coordinates of the target monitor
        SysGet, TargetMonitor, Monitor, 1 
        
        ; Move the VS Code window to the target monitor and maximize it
        WinMove, ahk_id %VSCodeID%, , TargetMonitorLeft, TargetMonitorTop, TargetMonitorRight - TargetMonitorLeft, TargetMonitorBottom - TargetMonitorTop
        WinMaximize, ahk_id %VSCodeID%
    } else {
        MsgBox, Target monitor does not exist.
    }
return

; #monitor 1 is laptop screen (default monitor
; #monitor 2 is samsung Tv 
; #monitor 3 is asus vertical monitor
; #monitor 4 is laptop screen (default monitor

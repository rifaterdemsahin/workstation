#6::
    ; Set title match mode to allow partial matches
    SetTitleMatchMode, 2
    ; Define the partial title of the paint.net window
    WinTitle := "paint.net"
    
    ; Check if the paint.net window exists
    if !WinExist(WinTitle) {
        ; Attempt to run paint.net
        Run, "C:\Program Files\paint.net\PaintDotNet.exe"
        ; Wait for the paint.net window to appear
        WinWait, %WinTitle%,, 10 ; Wait up to 10 seconds
        if !WinExist(WinTitle) {
            MsgBox, Failed to launch paint.net.
            return
        }
    }
    
    ; Get the window ID of paint.net
    WinGet, PaintNetID, ID, %WinTitle%
    
    ; Get the number of monitors
    SysGet, MonitorCount, MonitorCount
    
    ; Check if monitor 0 exists (note: monitors typically start at 1 in AHK, so this might need adjustment)
    ; Using monitor 1 as a fallback since AHK typically uses 1-based indexing for monitors
    MonitorIndex := 1  ; Default to 1 if 0 doesn't work
    
    ; Get the bounding coordinates of the target monitor
    SysGet, TargetMonitor, Monitor, %MonitorIndex%
    
    ; Move the paint.net window to the target monitor and maximize it
    WinMove, ahk_id %PaintNetID%, , TargetMonitorLeft, TargetMonitorTop, TargetMonitorRight - TargetMonitorLeft, TargetMonitorBottom - TargetMonitorTop
    WinMaximize, ahk_id %PaintNetID%
return
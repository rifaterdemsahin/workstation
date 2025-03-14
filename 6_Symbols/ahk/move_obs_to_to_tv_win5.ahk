#5::
    ; Set title match mode to allow partial matches
    SetTitleMatchMode, 2
    ; Define the partial title of the OBS window
    WinTitle := "OBS "
    
    ; Check if the OBS window exists
    if !WinExist(WinTitle) {
        ; Attempt to run OBS
        Run, obs64
        ; Wait for the OBS window to appear
        WinWait, %WinTitle%,, 10 ; Wait up to 10 seconds
        if !WinExist(WinTitle) {
            MsgBox, Failed to launch OBS.
            return
        }
    }
    
    ; Get the window ID of OBS
    WinGet, OBSID, ID, %WinTitle%
    
    ; Get the number of monitors
    SysGet, MonitorCount, MonitorCount
    
    ; Target monitor 1 (laptop screen according to your comment)
    if (MonitorCount >= 1) {
        ; Get the bounding coordinates of monitor 1
        SysGet, TargetMonitor, Monitor, 1
        
        ; Move the OBS window to monitor 1 and maximize it
        WinMove, ahk_id %OBSID%, , TargetMonitorLeft, TargetMonitorTop, TargetMonitorRight - TargetMonitorLeft, TargetMonitorBottom - TargetMonitorTop
        WinMaximize, ahk_id %OBSID%
    } else {
        MsgBox, Target monitor does not exist.
    }
return
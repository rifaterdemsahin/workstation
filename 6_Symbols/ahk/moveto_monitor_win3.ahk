; Move and maximize WhatsApp window to monitor 3
#3::
    ; Set title match mode to allow partial matches
    SetTitleMatchMode, 2
    ; Define the partial title of the WhatsApp window
    WinTitle := "WhatsApp"
    
    ; Check if the WhatsApp window exists
    if WinExist(WinTitle) {
        ; Get the window ID of WhatsApp
        WinGet, WhatsAppID, ID, %WinTitle%
        
        ; Get the number of monitors
        SysGet, MonitorCount, MonitorCount
        
        ; Check if monitor 3 exists
        if (MonitorCount >= 3) {
            ; Get the bounding coordinates of monitor 3
            SysGet, Monitor3, Monitor, 3
            
            ; Move the WhatsApp window to monitor 3 and maximize it
            WinMove, ahk_id %WhatsAppID%, , Monitor3Left, Monitor3Top, Monitor3Right - Monitor3Left, Monitor3Bottom - Monitor3Top
            WinMaximize, ahk_id %WhatsAppID%
        } else {
            MsgBox, Monitor 3 does not exist.
        }
    } else {
        MsgBox, WhatsApp window not found.
    }
return

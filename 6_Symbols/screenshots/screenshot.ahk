; Define the hotkey (Win + Shift + S)
#+s::
{
    ; Define the path to save the screenshot
    screenshotPath := A_Desktop "\screenshot.png"
    
    ; Check for the GDI+ library
    if !FileExist(A_ScriptDir "\Lib\Gdip_All.ahk")
    {
        MsgBox, Gdip_All.ahk library not found. Please download it from `nhttps://github.com/mmikeww/AHKv2-Gdip
        return
    }
    else
    {
        ; Include the GDI+ library
        #Include "C:\projects\workstation\6_Symbols\screenshots\Gdip_All.ahk"
    }
    
    ; Initialize GDI+
    if !pToken := Gdip_Startup()
    {
        MsgBox, GDI+ failed to start. Please ensure GDI+ is installed on your system.
        return
    }
    
    ; Get screen dimensions
    SysGet, ScreenWidth, 78
    SysGet, ScreenHeight, 79
    
    ; Create a bitmap
    pBitmap := Gdip_BitmapFromScreen(0, 0, ScreenWidth, ScreenHeight)
    
    ; Save the bitmap as a PNG file
    Gdip_SaveBitmapToFile(pBitmap, screenshotPath, 100)
    
    ; Clean up
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)
    
    ; Open the screenshot in Paint.NET
    Run, "C:\Program Files\paint.net\PaintDotNet.exe" " % screenshotPath%"
}
return

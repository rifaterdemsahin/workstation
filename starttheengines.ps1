cls
write-host "Most methods are here https://github.com/MScholtes/PSVirtualDesktop#remove-desktop--desktop-desktop"

Import-Module VirtualDesktop

function startminiprocess { 

    param (
       [string]$processpath,
       [int]$desktopIndex
       )
    
    write-host "Switch started desktop" $desktopIndex
    Switch-Desktop -Desktop $desktopIndex
    $proc = Start-Process $processpath -PassThru
    while ( ($myhandlepointer = $proc.MainWindowHandle) -eq 0 ) {
        write-host "the process handle is not ready for : " $processpath
    }
    write-host "Handler after waiting for the handler id: $myhandlepointer"
   
    $mycurrentDesktop = Get-CurrentDesktop
    write-host "move started to " $desktopIndex
    Move-Window -Desktop $mycurrentDesktop -Hwnd $myhandlepointer
}


Write-Host "Imported modules"


Write-Host "Start the machine"

Write-Host "Cleanup previous action"
Write-Host "DesktopList"
Get-DesktopList
Start-Sleep -s 6

$i=0
$desktopCount=Get-DesktopCount
Write-Host "Desktop Count" $desktopCount

Write-Host "Delete Virtual Desktops"
--$desktopCount

if ($desktopCount -gt 1) {
    $desktopCount=$desktopCount
    for ($i = $desktopCount; $i -ge 0; $i--) 
    {
        Write-Host "Deleting Desktop Index " $i
        
        if($i -ne 0)
            {Remove-Desktop $i}
        Start-Sleep -s 1
        Write-Host "Deleted Desktop" $i
    }
}


Write-Host "Create all the Desktops and switch to them than start to create the apps"
New-Desktop | Set-DesktopName -Name "Desktop"
New-Desktop | Set-DesktopName -Name "Editting"
New-Desktop | Set-DesktopName -Name "Tweet"
New-Desktop | Set-DesktopName -Name "Notion"
New-Desktop | Set-DesktopName -Name "Code"
New-Desktop | Set-DesktopName -Name "Instant Message"
New-Desktop | Set-DesktopName -Name "Watch"
New-Desktop | Set-DesktopName -Name "Operating System"
New-Desktop | Set-DesktopName -Name "Contracting"

Start-Sleep 5
write-host "Left over desktop messes it up"

$desktopindex =( Get-DesktopIndex -Desktop "Instant Message")
# startminiprocess -processpath "C:\Program Files (x86)\Microsoft\Skype for Desktop\Skype.exe" -desktop $desktopindex 
startminiprocess -processpath "C:\Users\erdem\AppData\Roaming\Telegram Desktop\Telegram.exe" -desktop $desktopindex
# startminiprocess -processpath "C:\Users\erdem\AppData\Local\Programs\signal-desktop\Signal.exe" -desktop $desktopindex
# startminiprocess -processpath "C:\Program Files\WindowsApps\5319275A.WhatsAppDesktop_2.2126.11.0_x64__cv1g1gvanyjgm\app\Whatsapp.exe" -desktop $desktopindex
# startminiprocess -processpath "C:\Users\erdem\AppData\Local\Discord\Update.exe --processStart Discord.exe" -desktop $desktopindex



Start-Sleep 5
return
$processpath = "C:\Program Files\Microsoft VS Code\Code.exe"
$proc = Start-Process $processpath  -PassThru
while ( ($myhandlepointernew = $proc.MainWindowHandle) -eq 0 ) {
	write-host "the process handle is not ready:" $processpath 
}
Move-Window -Desktop $mydesktop -Hwnd $myhandlepointernew
write-host "Handler after waiting for the handler id: $myhandlepointernew"



Write-Host "Open Stream Labs"
Start-Process "C:\Program Files\Streamlabs OBS\Streamlabs OBS.exe"
Write-Host "XSplit"
Write-Host "VCam"
 

Write-Host "Start programs ended"
 

Switch-Desktop -Desktop desktop


Write-Host "DesktopCount"
 Get-DesktopCount
 
Write-Host "DesktopList"
Get-DesktopList
 
Write-Host "Ended Start Machine"
Write-Host "References wait issue https://www.reddit.com/r/PowerShell/comments/or9ee9/why_cant_i_get_the_windows_handle_id_from_the/"
Write-Host "References Erdem github https://github.com/rifaterdemsahin/workstation/blob/master/starttheengines.ps1"
Write-Host "References Virtual Desktop Library Reference https://github.com/MScholtes/PSVirtualDesktop"

cls

Import-Module VirtualDesktop

Write-Host "Imported modules"


Write-Host "Start the machine"
 
Write-Host "Create the Virtual Desktops"
Write-Host "Cleanup previous action"
Write-Host "Delete Virtual Desktops"
Write-Host "Existing DesktopCount" 
Write-Host "DesktopList"
Get-DesktopList
Start-Sleep -s 6

$i=0
$desktopCount=Get-DesktopCount
Write-Host "Desktop Count" $desktopCount

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


 
Write-Host "Library Reference https://github.com/MScholtes/PSVirtualDesktop"


$proc = Start-Process "C:\Windows\system32\notepad.exe" -PassThru
while ( ($myhandlepointer = $proc.MainWindowHandle) -eq 0 ) {
	write-host "the process handle is not ready for notepad"
}
write-host "Handler after waiting for the handler id: $myhandlepointer"

New-Desktop | Switch-Desktop 

Move-Window -Desktop $mydesktop -Hwnd $myhandlepointer

Get-CurrentDesktop | Set-DesktopName -Name "Recording ZZZZZZ"

return

Write-Host "Open Stream Labs"
Start-Process "C:\Program Files\Streamlabs OBS\Streamlabs OBS.exe"
Write-Host "XSplit"
Write-Host "VCam"
 
 
New-Desktop | Set-DesktopName -Name "Editting"
New-Desktop | Set-DesktopName -Name "Tweet"
New-Desktop | Set-DesktopName -Name "Notion"
New-Desktop | Set-DesktopName -Name "Code"
New-Desktop | Set-DesktopName -Name "Instant Message"
New-Desktop | Set-DesktopName -Name "Watch"
New-Desktop | Set-DesktopName -Name "Operating System"
New-Desktop | Set-DesktopName -Name "Contracting"
Write-Host "Start programs ended"
 
Write-Host "DesktopCount"
 Get-DesktopCount
 
Write-Host "DesktopList"
Get-DesktopList
 
Write-Host "Ended Start Machine"
Write-Host "References https://www.reddit.com/r/PowerShell/comments/or9ee9/why_cant_i_get_the_windows_handle_id_from_the/"
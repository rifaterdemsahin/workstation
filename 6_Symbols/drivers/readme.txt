Ignored drivers
https://twitter.com/rifaterdemsahin/status/1522606406326788098

Practical Download
https://drive.google.com/drive/folders/1Qiys3IhfrpntcCodrfjfnlFbvHnarYBq

usb card
https://www.startech.com/en-gb/cards-adapters/pexusb3s44v


Shuttlepro
https://contour-design.co.uk/support/drivers/


Easy Command to List all on the machine
Get-WmiObject Win32_PnPSignedDriver| select devicename, FriendlyName, DriverVersion, DriverDate | Export-CSV -Path “.\My Drivers.csv” -NoTypeInformation
Get-WmiObject Win32_PnPSignedDriver | Export-CSV -Path “.\My Drivers.csv” -NoTypeInformation

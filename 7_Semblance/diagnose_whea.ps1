# This script retrieves detailed information about WHEA-Logger events
# from the System event log and saves it to a log file on the Desktop.

$logFile = "$env:USERPROFILE\Desktop\WHEA_Error_Log.txt"

function Get-WHEAErrorDetails {
    Write-Host "Querying for WHEA-Logger events..."
    $wheaEvents = Get-WinEvent -ProviderName "Microsoft-Windows-WHEA-Logger" -MaxEvents 20 | ForEach-Object {
        $eventXml = [xml]$_.ToXml()
        $eventData = $eventXml.Event.EventData
        $errorSource = $eventData.Data | Where-Object { $_.Name -eq 'ErrorSource' } | Select-Object -ExpandProperty '#text'
        $bus = $eventData.Data | Where-Object { $_.Name -eq 'Bus' } | Select-Object -ExpandProperty '#text'
        $device = $eventData.Data | Where-Object { $_.Name -eq 'Device' } | Select-Object -ExpandProperty '#text'
        $function = $eventData.Data | Where-Object { $_.Name -eq 'Function' } | Select-Object -ExpandProperty '#text'
        $vendor = $eventData.Data | Where-Object { $_.Name -eq 'Vendor' } | Select-Object -ExpandProperty '#text'
        $device_id = $eventData.Data | Where-Object { $_.Name -eq 'Device' } | Select-Object -ExpandProperty '#text'

        [PSCustomObject]@{
            TimeCreated = $_.TimeCreated
            ErrorSource = $errorSource
            BusDeviceFunction = "$bus:$device:$function"
            VendorID = $vendor
            DeviceID = $device_id
            Message = $_.Message
        }
    }

    if ($wheaEvents) {
        Write-Host "Found WHEA events. Logging details to $logFile"
        "WHEA Error Log - $(Get-Date)" | Out-File -FilePath $logFile -Encoding utf8
        "==================================================" | Out-File -FilePath $logFile -Encoding utf8 -Append
        $wheaEvents | Format-List | Out-File -FilePath $logFile -Encoding utf8 -Append
        Write-Host "Log file created at $logFile"
        Invoke-Item $logFile
    } else {
        Write-Host "No WHEA-Logger events found in the last 20 events."
    }
}

Get-WHEAErrorDetails

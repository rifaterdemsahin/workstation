function update-all {
    Write-Host "Starting Winget package upgrades..." -ForegroundColor Green
    winget upgrade --all

    Write-Host "Starting Windows Update..." -ForegroundColor Green
    Install-WindowsUpdate -AcceptAll -AutoReboot

    Write-Host "Starting Chocolatey package upgrades..." -ForegroundColor Green
    choco upgrade all -y

    Write-Host "All updates complete!" -ForegroundColor Cyan
}
$env:GOOGLE_CLOUD_PROJECT = "leafy-winter-477609-k0"

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

function dvl { Set-Location "C:\Users\Pexabo\AppData\Roaming\Blackmagic Design\DaVinci Resolve\Support\logs" }

# Reset Stream Deck - Kills Stream Deck, sets LG as primary, restarts Stream Deck
function reset-streamdeck {
    & powershell -ExecutionPolicy Bypass -File "C:\projects\workstation\6_Symbols\streamdeck\Reset-StreamDeck.ps1"
}

# Raspberry Pi Pico 2 W - Send text via WiFi
function Send-ToPico {
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [string]$Text,

        [Parameter(Mandatory=$false)]
        [switch]$Clipboard
    )

    $ProjectDir = "C:\projects\raspberry-pico-2-hid"
    Push-Location $ProjectDir

    try {
        if ($Clipboard) {
            python send_wifi.py --clip
        }
        elseif ($Text) {
            python send_wifi.py $Text
        }
        else {
            Write-Host "Usage: Send-ToPico 'text to send'"
            Write-Host "       Send-ToPico -Clipboard"
        }
    }
    finally {
        Pop-Location
    }
}

# Alias for convenience
Set-Alias -Name pico -Value Send-ToPico -Scope Global -Option AllScope


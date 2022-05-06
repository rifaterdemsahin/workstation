cls
$OutputVariable = (choco) | Out-String
$OutputVariable  | Select-String -Pattern 'Chocolatey' -CaseSensitive -SimpleMatch
if ($OutputVariable.length -gt 5) {
    Write-Output "Chocolatey already installed"
}
else
{
    Read-Host -Prompt ' Run this before start : Set-ExecutionPolicy Bypass -Scope Process -Force; press any key to continue, ctrl+c to exit '
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}


$User = Read-Host -Prompt ' Press any key to start the installation of the programs'
echo ' ------------- Started to Install the programs ------------- '

$list = New-Object Collections.Generic.List[String]
$list.Add("git.install")
$list.Add("gpu-z")
$list.Add("msiafterburner")
$list.Add("git")
$list.Add("Firefox")
$list.Add("Everything")
$list.Add("dotnetfx")
$list.Add("discord")
$list.Add("curl")
$list.Add("chocolatey-windowsupdate.extension")
$list.Add("chocolatey-visualstudio.extension")
$list.Add("chocolatey-dotnetfx.extension")
$list.Add("chocolatey-dotnetfx.extension")
$list.Add("chocolatey-core.extension")
$list.Add("chocolatey")
$list.Add("beyondcompare")
$list.Add("autohotkey.install")
$list.Add("autohotkey")
$list.Add("adobereader")
$list.Add("7zip.install")
$list.Add("microsoft-teams")
$list.Add("obs-studio")
$list.Add("notepadplusplus.install")
$list.Add("nomachine")
$list.Add("nodejs.install")
$list.Add("nodejs")
$list.Add("logitech-options")
$list.Add("lightshot.install")
$list.Add("jre8")
$list.Add("jdk8")
$list.Add("javaruntime")
$list.Add("GoogleChrome")
$list.Add("obs-studio.install")
$list.Add("greenshot")
$list.Add("slack")
$list.Add("skype")
$list.Add("python3")
$list.Add("python")
$list.Add("procexp")
$list.Add("PowerShell")
$list.Add("putty.install")
$list.Add("postman")
$list.Add("paint.net")
$list.Add("vscode")
$list.Add("vscode.install")
$list.Add("vlc")
$list.Add("virtualbox")
$list.Add("vim")
$list.Add("vcredist2017")
$list.Add("vcredist2015")
$list.Add("vcredist140")
$list.Add("streamlabs-obs")
$list.Add("streamdeck")
$list.Add("steam-client")
$list.Add("sourcetree")
$list.Add("audacity")

Foreach ($mypackage in $list)
{
choco install $mypackage -y
}

echo ' ----------------- Installation Complete -------------- '
echo ' Now login to the tools to be able to use them'

choco upgrade all -y


choco list --localonly
#todo verify install count

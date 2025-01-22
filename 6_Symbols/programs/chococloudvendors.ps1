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

$list.Add("awscli")
$list.Add("azure-cli")
$list.Add("gcloudsdk")

Foreach ($mypackage in $list)
{
choco install $mypackage -y
}

echo ' ----------------- Installation Complete -------------- '
echo ' Now login to the tools to be able to use them'

choco upgrade all -y


choco list --localonly
#todo verify install count

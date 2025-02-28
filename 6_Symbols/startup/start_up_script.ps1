# Enable debugging output
$DebugPreference = "Continue"

# Function to write colored debug messages
function Write-DebugWithColor {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Color = "Cyan"
    )
    Write-Host "[DEBUG] $Message" -ForegroundColor $Color
}

Write-DebugWithColor "Script started on $(Get-Date)" "Green"

# Function to start a process with error handling
function Start-ProcessWithCheck {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProcessPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $false)]
        [string]$Verb = "",

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = ""
    )

    if

# PowerShell Script to Launch AI Agents in Windows Terminal Tabs
# Purpose: Open Windows Terminal with Claude, Copilot, and Gemini in separate colored tabs
# Location: C:\projects\workstation\6_Symbols\startup
# Date: 2026-03-03

<#
.SYNOPSIS
    Launches three AI CLI agents (Claude, Copilot, Gemini) in separate Windows Terminal tabs
    with distinct tab colors for easy identification.

.DESCRIPTION
    - Tab 1 (Orange #E87D2F):  Claude   - Anthropic CLI agent
    - Tab 2 (Purple #8B5CF6):  Copilot  - GitHub Copilot CLI agent  
    - Tab 3 (Blue #4285F4):    Gemini   - Google Gemini CLI agent

    Each tab opens in the workstation project directory.

.NOTES
    Requires: Windows Terminal (wt.exe), claude, copilot, gemini CLI tools installed.
#>

$WorkDir = "C:\projects\workstation"

# Verify Windows Terminal is available
if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Windows Terminal (wt.exe) not found." -ForegroundColor Red
    exit 1
}

# Define agents with their colors and commands
$Agents = @(
    @{
        Name    = "Claude"
        Color   = "#E87D2F"   # Orange
        Command = "Write-Host '🤖 Claude Agent - Ready' -ForegroundColor Yellow; claude"
    },
    @{
        Name    = "Copilot"
        Color   = "#8B5CF6"   # Purple
        Command = "Write-Host '🤖 Copilot Agent - Ready' -ForegroundColor Magenta; copilot"
    },
    @{
        Name    = "Gemini"
        Color   = "#4285F4"   # Blue
        Command = "Write-Host '🤖 Gemini Agent - Ready' -ForegroundColor Cyan; gemini"
    }
)

Write-Host "Launching AI Agents in Windows Terminal..." -ForegroundColor Cyan

# Build the wt.exe command with multiple tabs
# First tab (Claude) uses default new-tab, subsequent tabs use `;` separator
$wtArgs = @()

# Tab 1: Claude
$wtArgs += "new-tab"
$wtArgs += "--title"
$wtArgs += $Agents[0].Name
$wtArgs += "--tabColor"
$wtArgs += $Agents[0].Color
$wtArgs += "-d"
$wtArgs += $WorkDir
$wtArgs += "pwsh"
$wtArgs += "-NoExit"
$wtArgs += "-Command"
$wtArgs += $Agents[0].Command

# Tab 2: Copilot
$wtArgs += ";"
$wtArgs += "new-tab"
$wtArgs += "--title"
$wtArgs += $Agents[1].Name
$wtArgs += "--tabColor"
$wtArgs += $Agents[1].Color
$wtArgs += "-d"
$wtArgs += $WorkDir
$wtArgs += "pwsh"
$wtArgs += "-NoExit"
$wtArgs += "-Command"
$wtArgs += $Agents[1].Command

# Tab 3: Gemini
$wtArgs += ";"
$wtArgs += "new-tab"
$wtArgs += "--title"
$wtArgs += $Agents[2].Name
$wtArgs += "--tabColor"
$wtArgs += $Agents[2].Color
$wtArgs += "-d"
$wtArgs += $WorkDir
$wtArgs += "pwsh"
$wtArgs += "-NoExit"
$wtArgs += "-Command"
$wtArgs += $Agents[2].Command

# Launch Windows Terminal with all tabs
Start-Process wt.exe -ArgumentList $wtArgs

Write-Host "AI Agents launched in 3 tabs:" -ForegroundColor Green
Write-Host "  Tab 1 - Claude  (Orange)" -ForegroundColor Yellow
Write-Host "  Tab 2 - Copilot (Purple)" -ForegroundColor Magenta
Write-Host "  Tab 3 - Gemini  (Blue)"   -ForegroundColor Cyan

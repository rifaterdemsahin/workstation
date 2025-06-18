# Requires: PowerShell 7+, jq (for JSON processing), and an OpenRouter API key set in the environment variable $env:OPENROUTER_API_KEY

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

# Configuration
$Model = $env:AI_MODEL
if (-not $Model) { $Model = "anthropic/claude-3.5-sonnet" }

$ContextDir = Join-Path $HOME ".ai_cli"
$ContextFile = Join-Path $ContextDir "conversation.json"

# Ensure context directory exists
if (-not (Test-Path $ContextDir)) {
    New-Item -ItemType Directory -Path $ContextDir | Out-Null
}

# Initialize context file if it doesn't exist
if (-not (Test-Path $ContextFile)) {
    '{"messages":[]}' | Out-File -Encoding UTF8 $ContextFile
}

# Helper functions
function Show-Help {
    Write-Host "Usage:"
    Write-Host "  ai.ps1 ""Your question here"""
    Write-Host "  ai.ps1 --new ""Start a new conversation"""
    Write-Host "  ai.ps1 --context  Show current conversation context"
    Write-Host "  ai.ps1 --clear    Clear conversation history"
    Write-Host "  ai.ps1 --save     Save conversation to second brain"
}

function Show-Context {
    if (Test-Path $ContextFile) {
        $messages = Get-Content $ContextFile | ConvertFrom-Json
        foreach ($msg in $messages.messages) {
            $role = $msg.role
            $content = $msg.content
            if ($role -eq "user") {
                Write-Host "You: $content" -ForegroundColor Yellow
            } else {
                Write-Host "AI: $content" -ForegroundColor Green
            }
            Write-Host ""
        }
    } else {
        Write-Host "No active conversation."
    }
}

function Add-To-Context($role, $content) {
    $context = Get-Content $ContextFile | ConvertFrom-Json
    $context.messages += @{ role = $role; content = $content }
    $context | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 $ContextFile
}

function Clear-Context {
    '{"messages":[]}' | Out-File -Encoding UTF8 $ContextFile
    Write-Host "Conversation history cleared."
}

function Save-To-SecondBrain {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $saveDir = Join-Path $HOME "secondbrain/ai_conversations"
    if (-not (Test-Path $saveDir)) {
        New-Item -ItemType Directory -Path $saveDir | Out-Null
    }
    $saveFile = Join-Path $saveDir "conversation_$timestamp.md"
    $context = Get-Content $ContextFile | ConvertFrom-Json
    $mdContent = "# AI Conversation - $(Get-Date)`n`n"
    foreach ($msg in $context.messages) {
        $role = if ($msg.role -eq "user") { "## User" } else { "## Assistant" }
        $mdContent += "$role`n$msg.content`n`n"
    }
    $mdContent | Out-File -Encoding UTF8 $saveFile
    Write-Host "Conversation saved to: $saveFile"
}

# Main logic
if ($Args.Count -eq 0) {
    Show-Help
    exit
}

switch ($Args[0]) {
    "--help" { Show-Help; exit }
    "--new" {
        Clear-Context
        if ($Args.Count -gt 1) {
            $inputText = ($Args | Select-Object -Skip 1) -join " "
        } else {
            $inputText = Read-Host "Enter your question"
        }
    }
    "--context" { Show-Context; exit }
    "--clear" { Clear-Context; exit }
    "--save" {
        Save-To-SecondBrain
        exit
    }
    default {
        $inputText = $Args -join " "
    }
}

if (-not $env:OPENROUTER_API_KEY) {
    Write-Host "❌ Error: OPENROUTER_API_KEY not set"
    Write-Host "💡 Set it with: `$env:OPENROUTER_API_KEY='your-api-key'"
    exit
}

# Add user input to context
Add-To-Context -role "user" -content $inputText

# Prepare API request
$context = Get-Content $ContextFile | ConvertFrom-Json
$payload = @{
    model = $Model
    messages = $context.messages
    max_tokens = 4000
}

# Send request to OpenRouter API
try {
    $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" `
        -Headers @{ Authorization = "Bearer $($env:OPENROUTER_API_KEY)"; "Content-Type" = "application/json" } `
        -Method Post `
        -Body ($payload | ConvertTo-Json -Depth 10)

    $content = $response.choices[0].message.content
    if ($content) {
        Add-To-Context -role "assistant" -content $content
        Write-Host "`nAI: $content`n" -ForegroundColor Green
    } else {
        Write-Host "❌ No response received from the API."
    }
} catch {
    Write-Host "❌ Failed to connect to the API: $_"
}

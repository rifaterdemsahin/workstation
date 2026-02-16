# PowerShell Script to Start Ollama Service
# Purpose: Automatically starts Ollama service and ensures nomic-embed-text model is available
# This script is designed to run at Windows startup

# Configuration
$LogFile = "$PSScriptRoot\start_ollama.log"
$ModelName = "nomic-embed-text"
$MaxRetries = 3
$RetryDelay = 5

# Function to write log messages
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Function to check if Ollama is installed
function Test-OllamaInstalled {
    try {
        $ollamaPath = Get-Command ollama -ErrorAction SilentlyContinue
        return $null -ne $ollamaPath
    }
    catch {
        return $false
    }
}

# Function to check if Ollama service is running
function Test-OllamaRunning {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -Method GET -TimeoutSec 5 -ErrorAction SilentlyContinue
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

# Function to start Ollama service
function Start-OllamaService {
    Write-Log "Starting Ollama service..."
    
    try {
        # Start Ollama in the background
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 5
        
        # Wait for service to be ready
        $retries = 0
        while (-not (Test-OllamaRunning) -and $retries -lt $MaxRetries) {
            Write-Log "Waiting for Ollama service to start (attempt $($retries + 1)/$MaxRetries)..."
            Start-Sleep -Seconds $RetryDelay
            $retries++
        }
        
        if (Test-OllamaRunning) {
            Write-Log "Ollama service started successfully."
            return $true
        }
        else {
            Write-Log "ERROR: Failed to start Ollama service after $MaxRetries attempts."
            return $false
        }
    }
    catch {
        Write-Log "ERROR: Exception while starting Ollama service: $_"
        return $false
    }
}

# Function to check if model exists
function Test-ModelExists {
    param([string]$Model)
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method GET -ErrorAction SilentlyContinue
        $modelExists = $response.models | Where-Object { $_.name -like "$Model*" }
        return $null -ne $modelExists
    }
    catch {
        Write-Log "ERROR: Failed to check if model exists: $_"
        return $false
    }
}

# Function to pull the model if it doesn't exist
function Get-OllamaModel {
    param([string]$Model)
    
    Write-Log "Checking if model '$Model' exists..."
    
    if (Test-ModelExists -Model $Model) {
        Write-Log "Model '$Model' is already available."
        return $true
    }
    
    Write-Log "Model '$Model' not found. Pulling model..."
    
    try {
        $pullProcess = Start-Process -FilePath "ollama" -ArgumentList "pull", $Model -Wait -PassThru -NoNewWindow
        
        if ($pullProcess.ExitCode -eq 0) {
            Write-Log "Model '$Model' pulled successfully."
            return $true
        }
        else {
            Write-Log "ERROR: Failed to pull model '$Model'. Exit code: $($pullProcess.ExitCode)"
            return $false
        }
    }
    catch {
        Write-Log "ERROR: Exception while pulling model: $_"
        return $false
    }
}

# Function to run a test with the model
function Test-ModelRunning {
    param([string]$Model)
    
    Write-Log "Running test with model '$Model'..."
    
    try {
        # Run a simple test by checking if model exists via API
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method GET -ErrorAction SilentlyContinue
        $modelExists = $response.models | Where-Object { $_.name -like "$Model*" }
        
        if ($null -ne $modelExists) {
            Write-Log "Model '$Model' is available and ready."
            return $true
        }
        else {
            Write-Log "WARNING: Model '$Model' not found in available models."
            return $false
        }
    }
    catch {
        Write-Log "WARNING: Could not test model: $_"
        return $false
    }
}

# Main execution
Write-Log "========================================="
Write-Log "Ollama Startup Script Started"
Write-Log "========================================="

# Check if Ollama is installed
if (-not (Test-OllamaInstalled)) {
    Write-Log "ERROR: Ollama is not installed or not in PATH."
    Write-Log "Please install Ollama from: https://ollama.ai"
    Write-Log "After installation, add Ollama to your system PATH."
    exit 1
}

Write-Log "Ollama is installed."

# Check if Ollama is already running
if (Test-OllamaRunning) {
    Write-Log "Ollama service is already running."
}
else {
    # Start Ollama service
    if (-not (Start-OllamaService)) {
        Write-Log "ERROR: Failed to start Ollama service. Exiting."
        exit 1
    }
}

# Ensure the model is available
if (-not (Get-OllamaModel -Model $ModelName)) {
    Write-Log "ERROR: Failed to ensure model '$ModelName' is available. Exiting."
    exit 1
}

# Optional: Test the model (commented out to avoid delays at startup)
# Test-ModelRunning -Model $ModelName

Write-Log "========================================="
Write-Log "Ollama startup completed successfully!"
Write-Log "Model '$ModelName' is ready to use."
Write-Log "========================================="

exit 0

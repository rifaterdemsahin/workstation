# PowerShell Script to Launch Chrome with Specific Profile and Open URLs
# Purpose: Open Chrome with a specific profile and navigate to Telegram and Gemini URLs
# Date: $(Get-Date -Format "yyyy-MM-dd")
# Version: 1.0

# Set error handling
$ErrorActionPreference = "Continue"

# Configuration
$Config = @{
    ChromePath    = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    ChromeProfile = "--profile-directory=`"Profile 21`""  # Adjust profile number as needed
    LogFile       = "$env:USERPROFILE\Desktop\StartupLog\TelegramGemini_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    URLs          = @(
        # --- Dashboards & Monitoring ---
        "http://localhost:9090/graph", # Prometheus
        "https://fal.ai/dashboard/keys",
        "https://studio.youtube.com/channel/UCSJyG3bTM7lnjMIZcV8C4OQ/analytics/tab-overview/period-default",
        "http://localhost:3000/a/grafana-metricsdrilldown-app/drilldown?uel_pid=grafana-metricsdrilldown-app&uel_epid=grafana%2Fexplore%2Ftoolbar%2Faction&from=now-6h&to=now&timezone=browser&var-metrics_filters=&var-filters=&var-labelsWingman=%28none%29&layout=grid&filters-rule=&filters-prefix=&filters-suffix=&search_txt=&var-metrics-reducer-sort-by=default&filters-recent=&var-ds=ffcmoxn8ueepsd&var-other_metric_filters=&actionView=breakdown&var-groupby=$__all",
        "https://fal.ai/dashboard",
        "https://kreatli.com/project/6987ddc3220b1c5e7a53cdb5/dashboard",
        "https://www.speedtest.net/result/18645473959",
        "https://fal.ai/login?returnTo=%2Fdashboard",

        # --- AI Models & Tools ---
        "https://gemini.google.com/u/1/app/736814cf49989003?pageId=none",
        "https://gemini.google.com/u/1/app/ce5464009e31da55?pageId=none",
        "https://fal.ai/models/Beatoven/music-generation",
        "https://huggingface.co/models",
        "https://elevenlabs.io/app/home",
        "https://elevenlabs.io/app/studio/p7m9RUs7xmlphEslgAnV?chapterId=awT2lWRjfjFutjuPzMuU",
        "https://grok.com/share/c2hhcmQtNA_952b9c41-f150-4a7a-a204-7312dd40b25f?rid=64990627-645a-4195-ac63-22eba710332c",
        "https://claude.ai/chat/3ee0d1d7-34e8-47e0-ba45-74c1a3346ac9",
        "https://openrouter.ai/models",
        "https://chatgpt.com/",

        # --- Communication & Social ---
        "https://web.telegram.org/a/#-1003885494482",
        "https://web.telegram.org/a/#-5280743505",
        "https://web.telegram.org/a/#-1002793496878",
        "https://www.linkedin.com/messaging/thread/2-YmYyNzM1Y2EtY2M0Yy00OTg2LWJkMzgtNGI4NjhhNTc1MDIyXzEwMA==/",
        "https://mail.google.com/mail/u/0/#advanced-search/is_unread=true&query=label%3A1_borrow_followup&isrefinement=true",
        "https://wp.titan.email/calendar/",

        # --- Development & Work ---
        "https://github.com/rifaterdemsahin/fal.ai/settings/secrets/actions",
        "https://github.com/rifaterdemsahin/fal.ai/tree/main",
        "https://github.com/rifaterdemsahin/delivery-pilot-web/pull/116",
        "https://www.us.fieldglass.cloud.sap/worker_desktop.do",
        "https://cgem.us.fieldglass.cloud.sap/rate_schedule_time_sheet_form.do",
        "https://github.com/rifaterdemsahin/remotion",
        "https://github.com/rifaterdemsahin/pexels/settings/secrets/actions",
        "https://www.pexels.com/api/key/",

        # --- Learning ---
        "https://www.coursera.org/learn/secure-ai-interpret-and-protect-models",
        "https://www.coursera.org/instructor/~184662540",
        
        # --- Files & Drives ---
        "https://drive.google.com/drive/folders/1Aw7z1fhBPbMKdd_1oswbzaWk6Q2gLtJf",
        "https://drive.google.com/drive/folders/1WNtY8IrYCiHaBaLshQZqWQPtJugPu9Mr",

        # --- Other / Personal / Misc ---
        "https://calendly.com/app/scheduled_events/user/me",
        "https://deliverypilot.net/5_Symbols/pricing.html",
        "http://localhost:3000/MapOfConsciousness",
        "https://rifaterdemsahin.github.io/contractormarketing-email-helper/blacklist.html",
        "https://accounts.intuit.com/app/sign-in?app_group=QBO&asset_alias=Intuit.accounting.core.qbowebapp&app_environment=prod",
        "https://www.google.com/maps/dir/52.2056439,0.1194247/The+Hub+-+AstraZeneca,+The+Hub,+Cambridge+Biomedical+Campus,+Francis+Crick+Ave,+Trumpington,+Cambridge+CB2+0AA/@52.1903475,0.1055185,14.24z/data=!4m10!4m9!1m1!4e1!1m5!1m1!1s0x47d87be4ccc63cbf:0xadc96b2e03c28d9d!2m2!1d0.1323067!2d52.1720215!3e1!5m1!1e4!17m2!4m1!1e3!18m1!1e1?entry=ttu&g_ep=EgoyMDI2MDEyOC4wIKXMDSoKLDEwMDc5MjA2OUgBUAM%3D",
        "https://templated.io/",
        "https://www.g2.com/products/bunny-cdn/reviews",
        "https://music.youtube.com/watch?v=mq0J9z8FlpM&list=OLAK5uy_mdo517ij36keU82dSWcU5-vK3EBF6KZRE",
        "https://www.youtube.com/watch?v=rrqFdwg58BY&list=RDrrqFdwg58BY&start_radio=1",
        "https://kreatli.com/?utm_source=chatgpt.com",
        "https://www.google.com/maps/@41.0722003,29.0293371,3a,75y,155.63h,85.58t/data=!3m7!1e1!3m5!1sr8d1e3yo1TSwiSqY_czhPQ!2e0!6shttps:%2F%2Fstreetviewpixels-pa.googleapis.com%2Fv1%2Fthumbnail%3Fcb_client%3Dmaps_sv.tactile%26w%3D900%26h%3D600%26pitch%3D4.419005533201741%26panoid%3Dr8d1e3yo1TSwiSqY_czhPQ%26yaw%3D155.62861298225172!7i16384!8i8192?entry=ttu&g_ep=EgoyMDI2MDIwNC4wIKXMDSoKLDEwMDc5MjA2OUgBUAM%3D"
    )
}

# Ensure log directory exists
try {
    $logDir = Split-Path -Parent $Config.LogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        Write-Host "Created log directory: $logDir" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error creating log directory: $_" -ForegroundColor Red
    $Config.LogFile = "$env:TEMP\TelegramGemini_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
}

# Logging function
function Write-Log {
    param ([string]$Message)
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $Config.LogFile -Append -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
    }
    Write-Host $Message
}

# Function to launch Chrome with specific profile and URLs
function Launch-ChromeWithProfile {
    try {
        Write-Log "Starting Chrome launch process..."
        
        # Check if Chrome exists
        if (-not (Test-Path $Config.ChromePath)) {
            Write-Log "Chrome not found at: $($Config.ChromePath)"
            
            # Try alternative Chrome paths
            $possiblePaths = @(
                "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
            )
            
            foreach ($path in $possiblePaths) {
                if (Test-Path $path) {
                    Write-Log "Found Chrome at: $path"
                    $Config.ChromePath = $path
                    break
                }
            }
            
            if (-not (Test-Path $Config.ChromePath)) {
                Write-Log "Chrome not found in any standard location. Please install Chrome or update the path."
                return $false
            }
        }
        
        # Launch Chrome with profile and URLs
        Write-Log "Launching Chrome with profile: $($Config.ChromeProfile)"
        
        foreach ($url in $Config.URLs) {
            try {
                Write-Log "Opening URL: $url"
                
                # Launch Chrome with specific profile and URL
                $chromeArgs = @($Config.ChromeProfile, $url)
                Start-Process -FilePath $Config.ChromePath -ArgumentList $chromeArgs
                
                # Small delay between launches to prevent overwhelming the system
                Start-Sleep -Milliseconds 1000
                
                Write-Log "Successfully launched: $url"
            }
            catch {
                Write-Log "Failed to launch URL $url : $_"
            }
        }
        
        Write-Log "Chrome launch process completed successfully"
        return $true
        
    }
    catch {
        Write-Log "Error in Launch-ChromeWithProfile: $_"
        return $false
    }
}

# Function to verify Chrome profile exists
function Test-ChromeProfile {
    try {
        $profilePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\$($Config.ChromeProfile -replace '--profile-directory=`"', '' -replace '`"', '')"
        Write-Log "Checking for Chrome profile at: $profilePath"
        
        if (Test-Path $profilePath) {
            Write-Log "Chrome profile found: $profilePath"
            return $true
        }
        else {
            Write-Log "Chrome profile not found. Using default profile."
            $Config.ChromeProfile = ""
            return $false
        }
    }
    catch {
        Write-Log "Error checking Chrome profile: $_"
        return $false
    }
}

# Function to wait for Chrome to be ready
function Wait-ForChrome {
    param([int]$TimeoutSeconds = 30)
    
    try {
        Write-Log "Waiting for Chrome to be ready..."
        $timeout = (Get-Date).AddSeconds($TimeoutSeconds)
        
        while ((Get-Date) -lt $timeout) {
            $chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
            if ($chromeProcesses) {
                Write-Log "Chrome processes detected: $($chromeProcesses.Count)"
                return $true
            }
            Start-Sleep -Milliseconds 500
        }
        
        Write-Log "Timeout waiting for Chrome to start"
        return $false
    }
    catch {
        Write-Log "Error waiting for Chrome: $_"
        return $false
    }
}

# Main execution
try {
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "🚀 Telegram & Gemini Chrome Launcher" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Cyan
    
    Write-Host "#########################################################" -ForegroundColor Yellow
    Write-Host "#                                                       #" -ForegroundColor Yellow
    Write-Host "#   PLEASE OPEN CHROME IN THE VERTICAL SCREEN           #" -ForegroundColor Yellow
    Write-Host "#                                                       #" -ForegroundColor Yellow
    Write-Host "#   USE VERTICAL TABS CHROME EXTENSION                  #" -ForegroundColor Yellow
    Write-Host "#                                                       #" -ForegroundColor Yellow
    Write-Host "#########################################################" -ForegroundColor Yellow
    
    Write-Log "Script started at $(Get-Date)"
    
    # Test Chrome profile
    Test-ChromeProfile
    
    # Launch Chrome with profile and URLs
    $success = Launch-ChromeWithProfile
    
    if ($success) {
        # Wait for Chrome to be ready
        Wait-ForChrome
        
        Write-Host "`n=======================================" -ForegroundColor Green
        Write-Host "✅ Chrome launched successfully!" -ForegroundColor Green
        Write-Host "✅ URLs opened:" -ForegroundColor Green
        foreach ($url in $Config.URLs) {
            Write-Host "   • $url" -ForegroundColor White
        }
        Write-Host "=======================================" -ForegroundColor Green
    }
    else {
        Write-Host "`n=======================================" -ForegroundColor Red
        Write-Host "❌ Failed to launch Chrome" -ForegroundColor Red
        Write-Host "=======================================" -ForegroundColor Red
    }
    
    Write-Log "Script completed at $(Get-Date)"
    
}
catch {
    Write-Host "`n=======================================" -ForegroundColor Red
    Write-Host "❌ Script encountered an error!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "=======================================" -ForegroundColor Red
    Write-Log "Script error: $_"
}

# Keep window open for a moment to show results
Write-Host "`nPress Enter to close..." -ForegroundColor Yellow
Read-Host | Out-Null

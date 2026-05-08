@echo off
REM ============================================================================
REM Obsidian Custom Frames Servers - Windows Startup Script
REM ============================================================================
REM Purpose: Auto-start Downloads Browser and Semantic Search servers
REM Location: Add to Windows Startup folder or Task Scheduler
REM ============================================================================

echo.
echo ========================================
echo  Starting Obsidian Servers...
echo ========================================
echo.

REM Change to script directory
cd /d "%~dp0"

REM Check if Qdrant is running
echo [1/4] Checking Qdrant...
curl -s http://localhost:6333/healthz >nul 2>&1
if %errorlevel% neq 0 (
    echo   ^> Qdrant not running, starting Docker container...
    docker compose -f "F:\secondbrain_v4\secondbrain\docker-compose.yaml" up -d
    timeout /t 5 /nobreak >nul
    echo   ^> Qdrant started
) else (
    echo   ^> Qdrant already running
)

echo.
echo [2/4] Starting Downloads Browser (port 8765)...
start /min pythonw.exe "%~dp0obsidian_downloads_server.py"
echo   ^> Downloads Browser started in background

echo.
echo [3/4] Starting Semantic Search (port 7777)...
cd ..\qdrant
start /min pythonw.exe "search_server.py"
echo   ^> Semantic Search started in background

echo.
echo [4/4] Verifying servers...
timeout /t 3 /nobreak >nul

netstat -ano | findstr ":8765" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ^> Downloads Browser: RUNNING on port 8765
) else (
    echo   ^> Downloads Browser: FAILED TO START
)

netstat -ano | findstr ":7777" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ^> Semantic Search: RUNNING on port 7777
) else (
    echo   ^> Semantic Search: FAILED TO START
)

echo.
echo ========================================
echo  All servers started!
echo ========================================
echo.
echo  Downloads Browser: http://localhost:8765
echo  Semantic Search  : http://localhost:7777
echo  Qdrant Vector DB : http://localhost:6333
echo.
echo  Open Obsidian and use Custom Frames!
echo ========================================
echo.

REM Wait 5 seconds before closing (so you can see the output)
timeout /t 5 /nobreak >nul

exit

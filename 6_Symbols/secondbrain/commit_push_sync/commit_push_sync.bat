@echo off
REM Lightweight version — just git commit & push, no note creation
start "Commit & Push" powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0commit_push_sync.ps1"

@echo off
REM Saves clipboard image to second brain and git commits + pushes
start "Clipboard Image Sync" powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0clipboard_image_sync.ps1"

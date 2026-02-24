@echo off
REM Type a quick note in the terminal — appends to quick_notes.md and pushes
start "Quick Note" powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0quick_note.ps1"

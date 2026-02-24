@echo off
REM StreamDeck launcher for addnote.ps1
REM
REM WHY "start" IS REQUIRED:
REM   StreamDeck "System: Open" runs .bat files via cmd.exe /c
REM   That cmd.exe process exits immediately after launching the script.
REM   Without "start", PowerShell is a child of that cmd.exe and dies with it.
REM   "start" spawns PowerShell as a fully independent process (its own window),
REM   so it survives after cmd.exe closes.
REM
REM   "Add Note" = title shown in the PowerShell window title bar
start "Add Note" powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0addnote.ps1"

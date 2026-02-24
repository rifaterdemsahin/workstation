@echo off
REM StreamDeck launcher for addnote.ps1
REM Point StreamDeck "Open Application" at THIS .bat file, not the .ps1
REM -NoExit  : keeps the window open after the script finishes or errors
REM -ExecutionPolicy Bypass : avoids policy blocks without changing system settings
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0addnote.ps1"

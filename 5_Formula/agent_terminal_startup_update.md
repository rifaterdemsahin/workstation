# Agent Terminal Startup Update Report - 2026-05-08

This report documents the changes made to the `6_Symbols\startup\start_ai_agents_tabs.ps1` script on 2026-05-08.

## Changes Implemented:

1.  **Terminal Agents:** The script was modified to launch only **Gemini** and **OpenCode** terminals at startup. The previous agents (Claude, Copilot) have been removed from the startup sequence.
2.  **Startup Directory:** The default working directory for the launched terminals has been updated from `C:\projects\workstation` to `C:\Users\Pexabo\ObsidianVault`.
3.  **OpenCode Integration:** A new entry for "OpenCode" was added, which launches Visual Studio Code (`code .`) in a dedicated green-colored tab.
4.  **Output Messages:** The informational messages displayed in the console upon script execution have been updated to reflect the current startup configuration (Gemini and OpenCode).

## Rationale:

The changes align with the user's request to streamline the terminal startup process, focusing on the primary AI agent (Gemini) and development environment (OpenCode) and setting a specific working directory for convenience.

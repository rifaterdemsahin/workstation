#!/bin/bash
# Workstation Aliases and Functions
# Source this file in your .bashrc or .bash_profile:
# source ~/projects/workstation/6_Symbols/aliases.sh

# Reset Stream Deck - Kills Stream Deck, sets LG as primary, restarts Stream Deck
reset-streamdeck() {
    powershell -ExecutionPolicy Bypass -File "C:/projects/workstation/6_Symbols/streamdeck/Reset-StreamDeck.ps1"
}

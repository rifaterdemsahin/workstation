#!/bin/bash
# macOS Homebrew Full Upgrade & Cleanup Script
echo "==> Updating Homebrew formulae and casks..."
brew update
brew upgrade
brew cleanup
echo "==> Brew upgrade complete."

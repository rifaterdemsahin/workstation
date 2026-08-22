# macOS Homebrew Upgrade Report — 2026-08-22

This report records the complete `brew upgrade` execution performed on **MacBook Pro** (`Rifats-MacBook-Pro-25457`).

---

## 📋 Executive Summary

- **Host**: `Rifats-MacBook-Pro-25457`
- **Execution Date**: 2026-08-22
- **Command Executed**: `brew upgrade`
- **Total Packages Upgraded**: 35 packages / casks (+ 1 new dependency installed)
- **Status**: Successfully upgraded all targets

---

## 📦 Upgraded Formulae & Casks

### 🛠 Command Line Tools & Formulae (26)

| Package | Old Version | New Version | Size / Notes |
| :--- | :--- | :--- | :--- |
| `simdutf` | 9.0.0 | 9.1.0 | 395.4 KB |
| `node@22` | 22.23.2 | 22.23.2_1 | 15.2 MB (Keg-only) |
| `openshift-cli` | 4.22.8 | 4.22.9 | 30.8 MB |
| `merve` | 1.2.2_1 | 1.2.2_2 | 33 KB |
| `flyctl` | 0.4.83 | 0.4.87 | 25 MB |
| `go` | 1.26.6 | 1.27.0 | 67.6 MB |
| `gh` | 2.97.0 | 2.98.0 | 13.7 MB |
| `aws-c-sdkutils` | 0.2.9 | 0.2.10 | 51.6 KB |
| `aws-c-cal` | 0.9.15 | 0.9.15_1 | 43.8 KB |
| `aws-c-compression` | 0.3.2 | 0.3.3 | 15.3 KB |
| `s2n` | 1.7.7 | 1.7.8 | 755.6 KB |
| `aws-c-io` | 0.27.6 | 0.27.7 | 198.2 KB |
| `aws-c-http` | 0.11.0 | 0.11.1 | 167.8 KB |
| `yt-dlp` | 2026.7.4 | 2026.8.19 | 5.4 MB |
| `aws-c-mqtt` | 0.16.1 | 0.16.2 | 145 KB |
| `aws-checksums` | 0.2.10 | 0.2.11 | 78.7 KB |
| `aws-c-event-stream` | 0.7.1 | 0.7.2 | 46.8 KB |
| `aws-c-auth` | 0.10.4 | 0.10.5 | 107.4 KB |
| `aws-c-s3` | 0.13.5 | 0.13.7 | 128.5 KB |
| `awscli` | 2.36.24 | 2.36.29 | 23.2 MB |
| `mlx` | 0.32.0 | 0.32.1 | 39.7 MB |
| `mlx-c` | 0.6.0_3 | 0.6.0_4 | 187.6 KB |
| `htop` | 3.5.2 | 3.5.3 | 156.0 KB |
| `tmux` | 3.7b | 3.7c | 543 KB |
| `kubernetes-cli` | 1.36.3 | 1.36.4 | 18.3 MB |
| `ollama` | 0.32.13 | 0.32.15 | 17.3 MB |

### 🧩 New Dependencies Installed (1)
- `jemalloc` 5.3.1 (Dependency installed for `tmux`)

### 🖥 GUI Applications / Casks (9)

| Cask Name | Old Version | New Version |
| :--- | :--- | :--- |
| `bettertouchtool` | 6.726,2026081403 | 6.746,2026082105 |
| `loom` | 0.368.1 | 0.369.2 |
| `obs` | 32.2.1 | 32.2.2 |
| `rectangle` | 0.98 | 0.99 |
| `virtualbox` | 7.2.14,174565 | 7.2.16,174877 |
| `visual-studio-code` | 1.133.0 | 1.134.0 |
| `warp` | 0.2026.08.12.21.54.stable_00 | 0.2026.08.19.08.15.stable_01 |
| `whatsapp` | 26.32.19 | 26.33.19 |
| `wispr-flow` | 1.6.531 | 1.6.606 |

---

## ⚠️ Notices & Tap Trust Warnings

### 1. Untrusted Taps
Homebrew reported the following taps require explicit trust:
- `anomalyco/tap`
- `dopplerhq/doppler`

**Action options**:
- Trust taps: `brew trust anomalyco/tap dopplerhq/doppler`
- Untap taps: `brew untap anomalyco/tap dopplerhq/doppler`

### 2. Disabled Packages
- `microsoft-remote-desktop` is marked as disabled in Homebrew Cask.

---

## ⚙️ Caveats & Post-Install Notes

- **`node@22`**: Keg-only formula. If `node@22` is needed first in PATH:
  ```bash
  export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
  ```
- **`htop`**: Requires root privileges to accurately show all processes (`sudo htop`).
- **`ollama`**: Can be started as a service or manually:
  ```bash
  brew services start ollama
  # or
  OLLAMA_FLASH_ATTENTION="1" OLLAMA_KV_CACHE_TYPE="q8_0" /opt/homebrew/opt/ollama/bin/ollama serve
  ```
- **`awscli`**: Examples placed in `/opt/homebrew/share/awscli/examples`.
- **`tmux`**: Example configs in `/opt/homebrew/opt/tmux/share/tmux`.
- **`zsh completions`**: Installed to `/opt/homebrew/share/zsh/site-functions`.

---

## 📁 Related Log Artifacts
- Raw Log: [macos_brew_upgrade_2026-08-22.log](../6_Symbols/Logs/macos_brew_upgrade_2026-08-22.log)

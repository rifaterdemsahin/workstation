# YouTube Video Downloader

A two-file Windows utility that opens a terminal, prompts for a YouTube URL, and downloads the video (or audio) to your `Downloads` folder. **Debug mode is on by default** — every step is logged to the terminal and to a log file.

---

## Files

| File | Purpose |
|------|---------|
| `yt-download.bat` | Double-click launcher — opens terminal and runs the PowerShell script |
| `yt-download.ps1` | Core logic — locate/install yt-dlp, collect URL, download, log everything |

---

## Requirements

- **Windows 10/11**
- **PowerShell 5.1+** (built-in)
- **yt-dlp** — auto-installed via `winget` on first run
  - Manual install: https://github.com/yt-dlp/yt-dlp#installation
- **FFmpeg** *(optional but recommended for 1080p quality merging)*
  - `winget install Gyan.FFmpeg`

---

## Usage

### Option A — Double-click (easiest)
1. Double-click **`yt-download.bat`**
2. Terminal opens — debug info appears at each step
3. Paste a YouTube URL when prompted
4. Choose a quality option
5. Watch verbose yt-dlp output as the file downloads
6. File is saved to `C:\Users\<you>\Downloads\`

### Option B — PowerShell directly
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\yt-download.ps1
```

---

## Quality Options

| Choice | Format | Output |
|--------|--------|--------|
| 1 | Best available (default) | MP4 |
| 2 | Up to 1080p | MP4 |
| 3 | Up to 720p | MP4 |
| 4 | Up to 480p | MP4 |
| 5 | Audio only | MP3 |

---

## Debug Mode

Debug mode is **on by default**. Every execution step is printed to the terminal with timestamps and level tags, and also written to a log file:

```
C:\Users\<you>\Downloads\yt-download-debug.log
```

### What gets logged

| Step | What you see |
|------|-------------|
| Startup | PowerShell version, OS, username, paths |
| Downloads folder check | Exists or created |
| yt-dlp search | Checked PATH → WinGet → Scoop |
| winget install | Full winget output (if needed) |
| PATH refresh | Confirms PATH is updated after install |
| yt-dlp version check | Confirms the binary actually runs |
| ffmpeg check | Found or missing + how to fix |
| URL input | Raw value entered + regex validation result |
| Quality selection | Format string chosen |
| yt-dlp command | Full executable path + every argument |
| Download | Full `--verbose` yt-dlp output |
| Exit code | `0` = success, anything else = failure |

### Turning debug off

In `yt-download.ps1`, change line 9:
```powershell
$DebugMode = $false
```
Errors will still be shown — only the `[INFO]` debug lines are suppressed.

---

## Supported URL Formats

- `https://www.youtube.com/watch?v=XXXX`
- `https://youtu.be/XXXX`
- `https://www.youtube.com/shorts/XXXX`

---

## Troubleshooting

**Terminal closes immediately** — The BAT now catches hard crashes and holds the window. Check `yt-download-debug.log` in your Downloads folder.

**yt-dlp not found after winget install** — The script refreshes PATH automatically. If it still fails, close the terminal completely and re-run `yt-download.bat`.

**"Execution policy" error** — Always run via the `.bat` file (it passes `-ExecutionPolicy Bypass` automatically).

**No audio track / 1080p looks bad** — Install ffmpeg:
```powershell
winget install Gyan.FFmpeg
```

**yt-dlp is outdated** — Update it:
```powershell
yt-dlp -U
```

---

## Output Location

```
C:\Users\<YourUsername>\Downloads\<Video Title>.mp4
C:\Users\<YourUsername>\Downloads\yt-download-debug.log
```

---

## Changelog

| Date | Change |
|------|--------|
| 2026-02-24 | Initial release |
| 2026-02-24 | Added full debug mode — step-by-step logging, `--verbose` yt-dlp output, log file, ffmpeg check, PATH refresh after winget install, fixed duplicate `pause` in BAT |

---

*Built for solo content creators who want a fast, no-fuss YouTube downloader with full visibility into what's happening under the hood.*

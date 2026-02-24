# Clipboard Image Sync

Saves whatever image is on your clipboard directly into your Second Brain repo,
then commits and pushes — triggered by a single StreamDeck button press.

---

## Use Case

You're doing research, reading an article, or watching a video and you see
something worth keeping. You hit **Print Screen** (or use LightShot / Snipping Tool)
to capture it. Instead of digging through a downloads folder or losing it to
clipboard history, you press a StreamDeck button and the image is:

1. Saved as a timestamped PNG inside your Second Brain vault
2. Committed to git with an automatic message
3. Pushed to GitHub

No file naming, no drag-and-drop, no manual commits. One button.

---

## Files

| File | Purpose |
|---|---|
| `clipboard_image_sync.bat` | **StreamDeck entry point.** Point your StreamDeck action at this file. |
| `clipboard_image_sync.ps1` | PowerShell script that does the actual work. |

---

## How It Works

```
Copy image to clipboard (PrintScreen / LightShot / Snipping Tool)
        │
        ▼
StreamDeck button press
        │
        ▼
  clipboard_image_sync.bat
  (launches PowerShell with -NoExit -ExecutionPolicy Bypass)
        │
        ▼
  clipboard_image_sync.ps1
  1. Read image from clipboard (fails fast if clipboard has no image)
  2. Validate the repo path exists
  3. Save PNG to  <repo>/screenshots/screenshot_YYYY-MM-DD_HH-mm-ss.png
  4. git pull   (get latest)
  5. git add -A (stage the new file)
  6. git commit -m "StreamDeck clipboard image YYYY-MM-DD HH:MM:SS"
  7. git push
  8. Print saved path and commit message
  9. Wait for Enter before closing
```

---

## Output Location

Images are saved to the `screenshots/` subfolder of your repo:

```
F:\secondbrain_v4\secondbrain\secondbrain\screenshots\
    screenshot_2026-02-24_14-35-22.png
    screenshot_2026-02-24_15-01-07.png
    ...
```

The folder is created automatically if it doesn't exist.

---

## Commit Message Format

```
StreamDeck clipboard image 2026-02-24 14:35:22
```

Fully automatic — no prompts.

---

## StreamDeck Setup

1. Add an **Open** action in StreamDeck
2. Set the file path to:
   ```
   C:\projects\workstation\6_Symbols\secondbrain\clipboard_image_sync\clipboard_image_sync.bat
   ```
3. Do **not** point it at the `.ps1` directly — the window will close before
   you can read the output.

---

## Configuration

Edit these variables at the top of `clipboard_image_sync.ps1`:

| Variable | Default | Purpose |
|---|---|---|
| `$repoPath` | `F:\secondbrain_v4\...\secondbrain\` | Path to your local git repo |
| `$imageFolder` | `screenshots` | Subfolder inside the repo to save images |
| `$branch` | `main` | Branch to pull from and push to |
| `$remoteRepo` | `origin` | Git remote name |

---

## Debugging

Every run writes a full transcript to:
```
C:\Temp\clipboard_image_sync_log.txt
```

If the window closes before you can read it, open that file.

---

## Error: No Image on Clipboard

If you run the script without an image on the clipboard, it exits immediately with:
```
ERROR: No image found on clipboard.
       Copy a screenshot or image first, then run this script.
```
Text, files, and other clipboard content are ignored — only images are accepted.

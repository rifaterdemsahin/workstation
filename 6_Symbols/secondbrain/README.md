# Second Brain - StreamDeck Git Sync

Automates committing and pushing notes and images from a local Second Brain vault to GitHub,
triggered by a single StreamDeck button press.

---

## Files

| File | Purpose |
|---|---|
| `addnote.bat` | **StreamDeck entry point — full flow.** Creates a timestamped note, commits, pushes, and opens Obsidian. |
| `addnote.ps1` | PowerShell script behind `addnote.bat`. |
| [`commit_push_sync/commit_push_sync.bat`](commit_push_sync/commit_push_sync.bat) | **StreamDeck entry point — sync only.** Just stages, commits, and pushes. No note creation, no Obsidian. |
| [`commit_push_sync/commit_push_sync.ps1`](commit_push_sync/commit_push_sync.ps1) | PowerShell script behind `commit_push_sync.bat`. |
| [`clipboard_image_sync/clipboard_image_sync.bat`](clipboard_image_sync/clipboard_image_sync.bat) | **StreamDeck entry point — clipboard image.** Saves clipboard image to repo, commits, and pushes. |
| [`clipboard_image_sync/clipboard_image_sync.ps1`](clipboard_image_sync/clipboard_image_sync.ps1) | PowerShell script behind `clipboard_image_sync.bat`. |
| `readme.tct` | Original scratch notes (screenshots, tools used). |

---

## How It Works

### Full Flow (`addnote`)

```
StreamDeck button press
        │
        ▼
  addnote.bat
  (launches PowerShell with -NoExit -ExecutionPolicy Bypass)
        │
        ▼
  addnote.ps1
  1. Ask for a commit message (defaults to "Update YYYY-MM-DD HH:MM")
  2. Validate the repo path exists
  3. git pull  (get latest changes)
  4. git add . (stage everything)
  5. git commit -m "<message>"
  6. git push
  7. Open note in Obsidian via obsidian:// URI
  8. Wait for Enter before closing
```

### Sync Only (`commit_push_sync`)

```
StreamDeck button press
        │
        ▼
  commit_push_sync.bat
  (launches PowerShell with -NoExit -ExecutionPolicy Bypass)
        │
        ▼
  commit_push_sync.ps1
  1. Ask for a commit message (clipboard → manual → timestamp fallback)
  2. Validate the repo path exists
  3. git pull  (get latest changes)
  4. git add -A (stage everything)
  5. git commit -m "<message>"
  6. git push
  7. Wait for Enter before closing
```

---

## StreamDeck Setup

1. Add a **Multi Action** or **Open** action in StreamDeck
2. Set the app/file path to the full path of the `.bat` you want:
   - Full flow: `C:\projects\workstation\6_Symbols\secondbrain\addnote.bat`
   - Sync only: `C:\projects\workstation\6_Symbols\secondbrain\commit_push_sync\commit_push_sync.bat`
3. Do **not** point it at the `.ps1` directly — Windows will open it without
   the `-NoExit` flag and the window will close before you can read the output.

---

## Why .bat Instead of .ps1 Directly

StreamDeck's "Open Application" action uses the Windows file association for `.ps1`,
which runs:
```
powershell.exe -File script.ps1
```
This closes the window the moment the script ends or hits an error.

The `.bat` wrapper runs:
```
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0script.ps1"
```
- `-NoExit` keeps the window open so you can read the output
- `-ExecutionPolicy Bypass` prevents policy blocks without changing system settings
- `%~dp0` resolves to the folder containing the `.bat`, so the path always works

---

## Debugging

Every run writes a full transcript to:

| Script | Log |
|---|---|
| `addnote.ps1` | `C:\Temp\addnote_log.txt` |
| `commit_push_sync.ps1` | `C:\Temp\commit_push_sync_log.txt` |

If the window closes before you can read it, open the relevant log file.

---

## Repo Target

Both scripts commit files from:
```
F:\secondbrain_v4\secondbrain\secondbrain\
```
Edit `$repoPath` in the respective `.ps1` to change this.

---

## Tools in the Second Brain Workflow

From the original notes (`readme.tct`):

| Tool | Role |
|---|---|
| **LightShot** | Windows screenshots, hotkey mapped via StreamDeck |
| **XMind** | Mind mapping |
| **Loom** | Screen recordings (https://www.loom.com) |
| **StreamDeck** | One-button trigger for these git sync scripts |

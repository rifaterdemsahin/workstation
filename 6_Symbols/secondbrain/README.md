# Second Brain - StreamDeck Git Sync

Automates committing and pushing notes from a local Second Brain vault to GitHub,
triggered by a single StreamDeck button press.

---

## Files

| File | Purpose |
|---|---|
| `addnote.bat` | **StreamDeck entry point.** Point your StreamDeck action at this file. |
| `addnote.ps1` | PowerShell script that does the actual git work. |
| `readme.tct` | Original scratch notes (screenshots, tools used). |

---

## How It Works

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
  7. Wait for Enter before closing
```

---

## StreamDeck Setup

1. Add a **Multi Action** or **Open** action in StreamDeck
2. Set the app/file path to the full path of `addnote.bat`:
   ```
   C:\projects\workstation\6_Symbols\secondbrain\addnote.bat
   ```
3. Do **not** point it at `addnote.ps1` directly — Windows will open it without
   the `-NoExit` flag and the window will close before you can read the output.

---

## Why .bat Instead of .ps1 Directly

StreamDeck's "Open Application" action uses the Windows file association for `.ps1`,
which runs:
```
powershell.exe -File addnote.ps1
```
This closes the window the moment the script ends or hits an error.

The `.bat` wrapper runs:
```
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0addnote.ps1"
```
- `-NoExit` keeps the window open so you can read the output
- `-ExecutionPolicy Bypass` prevents policy blocks without changing system settings
- `%~dp0` resolves to the folder containing the `.bat`, so the path always works

---

## Debugging

Every run writes a full transcript to:
```
C:\Temp\addnote_log.txt
```
If the window closes before you can read it, open that file to see exactly
what happened and which step failed.

---

## Repo Target

The script commits files from:
```
F:\secondbrain_v4\secondbrain\secondbrain\
```
Edit `$repoPath` in `addnote.ps1` to change this.

---

## Tools in the Second Brain Workflow

From the original notes (`readme.tct`):

| Tool | Role |
|---|---|
| **LightShot** | Windows screenshots, hotkey mapped via StreamDeck |
| **XMind** | Mind mapping |
| **Loom** | Screen recordings (https://www.loom.com) |
| **StreamDeck** | One-button trigger for this git sync script |

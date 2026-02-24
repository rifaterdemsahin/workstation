# Quick Note

Type a short note directly in the terminal and push it to your Second Brain —
triggered by a single StreamDeck button press.

---

## Use Case

You have a thought, a URL, a task, or a reference you don't want to lose.
You don't want to open Obsidian, create a file, format anything. You just want
to type it and have it saved and backed up instantly.

Press the StreamDeck button, type your note, hit Enter. Done.

Every note is appended with a timestamp to a single running file
(`quick_notes/quick_notes.md`) inside your Second Brain repo and pushed to GitHub.

---

## Files

| File | Purpose |
|---|---|
| `quick_note.bat` | **StreamDeck entry point.** Point your StreamDeck action at this file. |
| `quick_note.ps1` | PowerShell script that captures, saves, commits, and pushes the note. |

---

## How It Works

```
StreamDeck button press
        │
        ▼
  quick_note.bat
  (launches PowerShell with -NoExit -ExecutionPolicy Bypass)
        │
        ▼
  quick_note.ps1
  1. Prompt: "Type your note:"
  2. Validate the repo path exists
  3. Append to  <repo>/quick_notes/quick_notes.md  with timestamp header
  4. git pull   (get latest)
  5. git add -A (stage the updated file)
  6. git commit -m "StreamDeck quick note YYYY-MM-DD HH:MM:SS"
  7. git push
  8. Print saved file path and note preview
  9. Wait for Enter before closing
```

---

## Output Format

Notes accumulate in a single file:

```
F:\secondbrain_v4\secondbrain\secondbrain\quick_notes\quick_notes.md
```

Each entry looks like:

```markdown
## 2026-02-24 14:35:22

Look into the new React compiler docs — could replace memo everywhere.

---

## 2026-02-24 16:02:11

Book recommendation from Alex: "The Pragmatic Programmer"

---
```

---

## Commit Message Format

```
StreamDeck quick note 2026-02-24 14:35:22
```

---

## StreamDeck Setup

1. Add an **Open** action in StreamDeck
2. Set the file path to:
   ```
   C:\projects\workstation\6_Symbols\secondbrain\quick_note\quick_note.bat
   ```
3. Do **not** point it at the `.ps1` directly — the window will close before
   you can read the output or type your note.

---

## Configuration

Edit these variables at the top of `quick_note.ps1`:

| Variable | Default | Purpose |
|---|---|---|
| `$repoPath` | `F:\secondbrain_v4\...\secondbrain\` | Path to your local git repo |
| `$notesFolder` | `quick_notes` | Subfolder inside the repo |
| `$notesFile` | `quick_notes.md` | File all notes are appended to |
| `$branch` | `main` | Branch to pull from and push to |
| `$remoteRepo` | `origin` | Git remote name |

---

## Debugging

Every run writes a full transcript to:
```
C:\Temp\quick_note_log.txt
```

If the window closes before you can read it, open that file.

---

## Error: Empty Note

If you press Enter without typing anything, the script exits immediately with:
```
ERROR: Note is empty. Nothing to save.
```
Nothing is written to the file and no commit is made.

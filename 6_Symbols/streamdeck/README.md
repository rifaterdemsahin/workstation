# Reset-StreamDeck Script

Automatically resets your Stream Deck setup by killing the application, setting your LG monitor as the primary display, and restarting Stream Deck.

## Features

- **Kills Stream Deck processes** - Stops all running Stream Deck processes
- **Auto-detects LG monitor** - Detects LG monitors by manufacturer code (GSM) or name
- **Sets primary display** - Changes Windows primary display to the LG monitor
- **Restarts Stream Deck** - Launches Stream Deck application after reset
- **Detailed monitor info** - Shows all connected displays with adapter and monitor details
- **Manual override support** - Fallback option if auto-detection fails

## Usage

### Quick Run (from anywhere)

```powershell
reset-streamdeck
```

### Setup the Alias

Add this function to your PowerShell profile to use `reset-streamdeck` from anywhere:

1. Open your PowerShell profile:
   ```powershell
   notepad $PROFILE
   ```

2. Add this function:
   ```powershell
   function reset-streamdeck {
       & powershell -ExecutionPolicy Bypass -File "C:\projects\workstation\6_Symbols\streamdeck\Reset-StreamDeck.ps1"
   }
   ```

3. Reload your profile:
   ```powershell
   . $PROFILE
   ```

### Direct Execution

```powershell
powershell -ExecutionPolicy Bypass -File "C:\projects\workstation\6_Symbols\streamdeck\Reset-StreamDeck.ps1"
```

## Output Example

```
Stopping Stream Deck...
   Killing: StreamDeck (PID 2984048)
   Stream Deck stopped.

Loading display helper...
Detecting monitors...

   {DISPLAY}        {ADAPTER}                  {MONITOR NAME}              {MONITOR ID}
   ----------------------------------------------------------------------------------------------------
   \\.\DISPLAY1   AMD Radeon RX 6900 XT   Generic PnP Monitor   \\?\DISPLAY#AUS28B1#...
   \\.\DISPLAY2   AMD Radeon RX 6900 XT   Generic PnP Monitor   \\?\DISPLAY#GSM774F#...

LG monitor found: Generic PnP Monitor (\\.\DISPLAY2)
Setting as primary display...
LG is now the primary display.

Starting Stream Deck...
Stream Deck launched: C:\Program Files\Elgato\StreamDeck\StreamDeck.exe

Done!
```

## Manual Override

If auto-detection fails, you can manually specify the display:

1. Run the script once to see the monitor list
2. Edit `Reset-StreamDeck.ps1`
3. Set `$LG_DISPLAY_OVERRIDE = "\\.\DISPLAY2"` (replace with your LG display)

## Requirements

- Windows with PowerShell
- Elgato Stream Deck installed
- LG monitor connected (or manual override configured)

## Technical Details

The script uses Windows API calls via C# P/Invoke to:
- Enumerate display devices (`EnumDisplayDevices`)
- Query display settings (`EnumDisplaySettings`)
- Change primary display (`ChangeDisplaySettingsEx`)

Monitors are detected by matching:
- "LG" in monitor name
- "LG" in monitor ID
- "GSM" in monitor ID (LG's manufacturer code)

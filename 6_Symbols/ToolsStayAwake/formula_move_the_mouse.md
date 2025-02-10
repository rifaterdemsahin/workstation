Got it! I’ll modify the code so that the mouse will move automatically to the predefined target positions.

Here’s the updated version of the script that will move the mouse automatically:

```python
import random
import time
import pyautogui  # Ensure pyautogui is installed (pip install pyautogui)

# Define a list of target positions. These are your predefined points on the screen where you can click or press keys.
targets = [
    (0, 0),          # top-left corner
    (640, 480),      # center of window
    (1024, 0),       # bottom-right corner
    (1024, 480)      # opposite to center
]

def get_position(mouse_x, mouse_y, target):
    """Calculate the position relative to the target."""
    dx = mouse_x - target[0]
    dy = mouse_y - target[1]
    return [dx, dy]

def update_positions(mouse_x, mouse_y):
    global targets

    # Calculate the absolute positions of each target
    for i in range(len(targets)):
        x, y = targets[i]
        relative = get_position(mouse_x, mouse_y, targets[i])
        targets[i] = (x + relative[0], y + relative[1])

# Main program loop
keymap = {
    'ArrowLeft': (-15, 0),
    'ArrowUp': (0, -15),
    'ArrowRight': (15, 0),
    'ArrowDown': (0, 15)
}

while True:
    # Get current absolute mouse position
    mouse_x, mouse_y = pyautogui.position()  # This will return current mouse position
    
    # Update positions based on keyboard input
    for key, (dx, dy) in keymap.items():
        target_x = mouse_x + dx
        target_y = mouse_y + dy

        update_positions(mouse_x, mouse_y)

    # Move the mouse automatically to each target position
    for target in targets:
        pyautogui.moveTo(target[0], target[1], duration=1)  # Move to the target position smoothly
        
    # Print the relative positions of each target
    for i in range(len(targets)):
        print("Absolute Position:", targets[i])
        print(f"Relative Press: {targets[i][0]} + {targets[i][1]} Press", end="\n")
    
    time.sleep(0.1)  # Slow down the loop for better performance
```

### Key Changes:
- **Automatic Mouse Movement**: The line `pyautogui.moveTo(target[0], target[1], duration=1)` moves the mouse to each target position.
  - You can adjust the `duration` (in seconds) to control how fast the mouse moves.
  
Let me know how it goes or if you need any adjustments!
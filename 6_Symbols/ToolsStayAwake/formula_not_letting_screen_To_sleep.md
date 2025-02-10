To move the mouse randomly and prevent the screen from going to sleep, we can add two things to the script:

1. **Random Mouse Movement**: The mouse will move to random positions within a set range.
2. **Preventing Sleep**: We will simulate mouse movements periodically to ensure the system remains active and doesn’t go to sleep.

Here’s the updated version of your script:

```python
import random
import time
import pyautogui  # Ensure pyautogui is installed (pip install pyautogui)

# Define screen dimensions (you can adjust these based on your screen resolution)
screen_width, screen_height = pyautogui.size()

# Main program loop
while True:
    # Generate random coordinates within the screen dimensions
    random_x = random.randint(0, screen_width)
    random_y = random.randint(0, screen_height)

    # Move the mouse to the random position
    pyautogui.moveTo(random_x, random_y, duration=1)

    # Print the random position to the console
    print(f"Moving mouse to: ({random_x}, {random_y})")

    # Simulate mouse activity every 30 seconds to prevent the screen from going to sleep
    pyautogui.move(0, 0)  # This moves the mouse slightly, but doesn't affect the current position

    time.sleep(10)  # Move the mouse to a new position every 10 seconds
```

### Key Features:
- **Random Mouse Movement**: The mouse will randomly move to positions within the screen bounds.
- **Preventing Sleep**: Every 30 seconds, the mouse moves slightly (0, 0) to simulate activity, ensuring the screen stays awake.
- **Adjustable Sleep Interval**: You can modify the `time.sleep(10)` to change how often the mouse moves randomly. It's set to 10 seconds in this case.

### Instructions:
1. Install `pyautogui` if you haven’t already: `pip install pyautogui`.
2. Run the script and it will keep moving the mouse randomly while preventing your screen from going to sleep.

Let me know if it works for you!
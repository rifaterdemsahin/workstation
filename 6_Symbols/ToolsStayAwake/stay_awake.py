# PS C:\Users\Pexabo\Downloads> mv .\stay_awake.pl .\stay_awake.py                              
# python3 -m venv .venv
# C:\Users\Pexabo\Downloads\stayawake\.venv\Scripts\activate
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

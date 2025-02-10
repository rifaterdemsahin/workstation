import random
import time

# Define a list of target positions. These are your predefined points on the screen where you can click or press keys.
targets = [
    (0, 0),          # top-left corner
    (640, 480),       # center of window
    (1024, 0),       # bottom-right corner
    (1024, 480)        # opposite to center
]

def get_position(mouse_x, mouse_y, target):
    """Calculate the position relative to the target."""
    dx = mouse_x - target[0]
    dy = mouse_y - target[1]
    return [dx, dy]

def update_positions():
    global targets

    # Calculate the absolute positions of each target
    for i in range(len(targets)):
        x, y = targets[i]
        relative = get_position(mouse_x, mouse_y, targets[i][0], targets[i][1])
        targets[i] = (x + relative[0], y + relative[1])

# Main program loop
keymap = {
    'ArrowLeft': (-15, 0),
    'ArrowUp': (0, -15),
    'ArrowRight': (15, 0),
    'ArrowDown': (0, 15)
}

# Get the current position of the mouse
mouse_x, mouse_y = time.time(), time.time()

while True:
    # Get current absolute mouse position
    mouse_pos = (time.time(), time.time())
    
    # Update positions based on keyboard input
    for key, (dx, dy) in keymap.items():
        if abs(dx) > abs(dy):
            target_x = x + dx
            target_y = y + dy
        else:
            target_x = x + dy
            target_y = y + dx
        
        update_positions()
        
    # Print the relative positions of each target
    for i in range(len(targets)):
        print("Absolute Position:", targets[i])
        print("Relative Press:", targets[i][0] + " +", targets[i][1], 
              "Press", end=" \n")

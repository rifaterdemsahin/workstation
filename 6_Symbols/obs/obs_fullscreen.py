import obswebsocket
from obswebsocket import requests
import time
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Get the password from the .env file
obs_password = os.getenv("OBS_PASSWORD")

        import obswebsocket
        from obswebsocket import obsws, requests
        
        host = "localhost"
        port = 4455  # Ensure this matches the port set in OBS WebSocket settings
        password = "your_password"  # Use the correct password or an empty string if authentication is disabled
        
        ws = obsws(host, port, password)
        ws.connect()

# Connect to OBS WebSocket
client = obswebsocket.obsws("localhost", 4455, obs_password)  # Use the password from .env
client.connect()

# Wait briefly to ensure OBS is fully loaded
time.sleep(5)

# Open Fullscreen Projector (e.g., on Monitor 0, adjust as needed)
client.call(requests.OpenProjector(type="Preview", monitor=0))

# Disconnect after sending the command
client.disconnect()
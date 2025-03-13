import logging
import time
from dotenv import load_dotenv
import os
from obswebsocket import obsws, requests

# Configure logging
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s')

# Load environment variables from .env file
load_dotenv()

# Get the password from the .env file
obs_password = os.getenv("OBS_PASSWORD")

# Ensure the password is retrieved successfully
if obs_password is None:
    logging.error("OBS_PASSWORD not found in environment variables.")
    exit(1)

# OBS WebSocket connection parameters
host = "localhost"
port = 4455  # Ensure this matches the port set in OBS WebSocket settings
password = obs_password  # Use the password from .env

# Connect to OBS WebSocket
try:
    client = obsws(host, port, password)
    client.connect()
    logging.info("Connected to OBS WebSocket.")
except Exception as e:
    logging.error(f"Failed to connect to OBS WebSocket: {e}")
    exit(1)

# Wait briefly to ensure OBS is fully loaded
time.sleep(5)
logging.debug("Waited 5 seconds to ensure OBS is fully loaded.")

# Open Fullscreen Projector (e.g., on Monitor 0, adjust as needed)
try:
    client.call(requests.OpenProjector(type="Preview", monitor=0))
    logging.info("Opened Fullscreen Projector on Monitor 0.")
except Exception as e:
    logging.error(f"Failed to open Fullscreen Projector: {e}")

# Disconnect after sending the command
client.disconnect()
logging.info("Disconnected from OBS WebSocket.")
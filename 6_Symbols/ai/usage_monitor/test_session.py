from models.data_structures import SessionClass, UsageEntry
from datetime import datetime, timezone

# Test creating a session
session = SessionClass.get_current_session()
print(f"Session ID: {session.session_id}")
print(f"Session entries: {len(session.entries)}")
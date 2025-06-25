import json
import os
from pathlib import Path
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any, List
import uuid

class SessionStorage:
    def __init__(self):
        self.storage_dir = Path.home() / '.ai_cli'
        self.current_session_file = self.storage_dir / 'current_session.json'
        self.storage_dir.mkdir(exist_ok=True)
    
    def get_session_file(self, session_id: str) -> Path:
        """Get path to session's JSONL file"""
        return self.storage_dir / f'session_{session_id}.jsonl'
    
    def get_active_session_id(self) -> Optional[str]:
        """Get current active session ID if it exists and is still valid"""
        current_session = self._get_current_session_info()
        
        if current_session and self._is_session_active(current_session['session_id']):
            return current_session['session_id']
        return None
    
    def create_new_session_id(self) -> str:
        """Create and register a new session ID"""
        session_id = str(uuid.uuid4())[:8]
        
        current_session_info = {
            'session_id': session_id,
            'created_at': datetime.now(timezone.utc).isoformat()
        }
        
        with open(self.current_session_file, 'w') as f:
            json.dump(current_session_info, f)
        
        return session_id
    
    def load_session_entries(self, session_id: str) -> List[Dict[str, Any]]:
        """Load all entries for a session as raw dictionaries"""
        entries = []
        session_file = self.get_session_file(session_id)
        
        if session_file.exists():
            with open(session_file, 'r') as f:
                for line in f:
                    try:
                        entry_data = json.loads(line.strip())
                        entries.append(entry_data)
                    except (json.JSONDecodeError, ValueError):
                        continue  # Skip malformed lines
        
        return entries
    
    def save_entry(self, session_id: str, entry_data: Dict[str, Any]):
        """Append a new entry to session file"""
        session_file = self.get_session_file(session_id)
        
        with open(session_file, 'a') as f:
            f.write(json.dumps(entry_data) + '\n')
    
    def _get_current_session_info(self) -> Optional[Dict[str, Any]]:
        """Get info about current active session"""
        if not self.current_session_file.exists():
            return None
        
        try:
            with open(self.current_session_file, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            return None
    
    def _is_session_active(self, session_id: str) -> bool:
        """Check if session is still active (within 30 minutes of last activity)"""
        session_file = self.get_session_file(session_id)
        if not session_file.exists():
            return False
        
        try:
            # Get last line (most recent entry)
            with open(session_file, 'r') as f:
                lines = f.readlines()
                if not lines:
                    return False
                
                last_entry = json.loads(lines[-1])
                last_timestamp = datetime.fromisoformat(last_entry['timestamp'].replace('Z', '+00:00'))
                
                # Check if within 30 minutes (temporarily reduced to 10 seconds for testing)
                return datetime.now(timezone.utc) - last_timestamp < timedelta(seconds=10)
        except (json.JSONDecodeError, KeyError, ValueError):
            return False
    
    def list_all_sessions(self) -> List[str]:
        """Get list of all session IDs that have files"""
        session_files = self.storage_dir.glob('session_*.jsonl')
        return [f.stem.replace('session_', '') for f in session_files]
    
    def get_session_summary(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get basic stats about a session without loading all entries"""
        session_file = self.get_session_file(session_id)
        if not session_file.exists():
            return None
        
        try:
            with open(session_file, 'r') as f:
                lines = f.readlines()
                if not lines:
                    return None
                
                first_entry = json.loads(lines[0])
                last_entry = json.loads(lines[-1])
                
                return {
                    'session_id': session_id,
                    'entry_count': len(lines),
                    'first_timestamp': first_entry['timestamp'],
                    'last_timestamp': last_entry['timestamp'],
                    'is_active': self._is_session_active(session_id)
                }
        except (json.JSONDecodeError, KeyError, ValueError):
            return None
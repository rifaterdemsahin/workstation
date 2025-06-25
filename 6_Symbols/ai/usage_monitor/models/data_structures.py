"""
{
  "timestamp": "2025-06-25T11:36:34.3NZ",
  "model": "anthropic/claude-3.5-sonnet",
  "input_tokens": 87,
  "output_tokens": 87,
  "cost_usd": 0.001566,
  "response_time_ms": 4210,
  "request_id": "0bc578a5"
}
this is a data structure for usage monitoring in AI applications.
It includes fields for timestamp, model, input and output tokens, cost in USD, response time in milliseconds, and a request ID.
This structure can be used to log and analyze the usage of AI models, 
helping developers and organizations track performance, costs, and efficiency of their AI systems.
"""

from dataclasses import dataclass
from datetime import datetime, timezone
from models.session_storage import SessionStorage

@dataclass
class UsageEntry:
    timestamp: datetime
    model: str
    input_tokens: int
    output_tokens: int
    total_tokens: int
    cost_usd: float
    request_id: str


    @classmethod
    def from_openrouter_response(cls, response_data: dict, response_headers: dict):
        # Parse the GMT date from headers
        date_str = response_headers.get('Date')
        if date_str:
            # Parse GMT format: 'Wed, 25 Jun 2025 15:22:21 GMT'
            timestamp = datetime.strptime(date_str, '%a, %d %b %Y %H:%M:%S %Z')
            timestamp = timestamp.replace(tzinfo=timezone.utc)
        else:
            timestamp = datetime.now(timezone.utc)
        
        usage = response_data.get('usage', {})
        
        return cls(
            timestamp=timestamp,
            model=response_data.get('model', ''),
            input_tokens=usage.get('prompt_tokens', 0),
            output_tokens=usage.get('completion_tokens', 0),
            total_tokens=usage.get('total_tokens', 0),
            cost_usd=0.0,  # Calculate this later based on pricing
            request_id=response_data.get('id', '')
        )

    @classmethod
    def from_dict(cls, entry_dict: dict):
        return cls(
            timestamp=datetime.fromisoformat(entry_dict['timestamp']),
            model=entry_dict['model'],
            input_tokens=entry_dict['input_tokens'],
            output_tokens=entry_dict['output_tokens'],
            total_tokens=entry_dict.get('total_tokens', entry_dict['input_tokens'] + entry_dict['output_tokens']),
            cost_usd=entry_dict['cost_usd'],
            request_id=entry_dict['request_id']
        )


class SessionClass:
    def __init__(self, session_id: str):
        self.session_id = session_id
        self.entries = []
        self.storage = SessionStorage()

        # Load existing session entries from storage
        entry_dicts = self.storage.load_session_entries(session_id)
        for entry_dict in entry_dicts:
            self.entries.append(UsageEntry.from_dict(entry_dict))

    def add_entry(self, entry: UsageEntry):
        print(f"DEBUG: add_entry called with: {entry}")
        self.entries.append(entry)
        print(f"DEBUG: entries length now: {len(self.entries)}")
        
        # Convert to dict for storage
        entry_dict = {
            'timestamp': entry.timestamp.isoformat(),
            'model': entry.model,
            'input_tokens': entry.input_tokens,
            'output_tokens': entry.output_tokens,
            'cost_usd': entry.cost_usd,
            'request_id': entry.request_id
        }
        print(f"DEBUG: entry_dict: {entry_dict}")
        
        self.storage.save_entry(self.session_id, entry_dict)
        print("DEBUG: save_entry completed")
    
    def is_session_alive(self) -> bool:
        """Check if the session is still active based on the last entry's timestamp."""
        if not self.entries:
            return False
        last_entry_time = self.entries[-1].timestamp
        current_time = datetime.now(timezone.utc)
        return (current_time - last_entry_time).total_seconds() < 1800
    
    @classmethod
    def get_current_session(cls):
        """Get the current active session, or create a new one if none exists."""
        storage = SessionStorage()
        session_id = storage.get_active_session_id()
        
        if session_id:
            return cls(session_id)
        else:
            new_session_id = storage.create_new_session_id()
            return cls(new_session_id)

    @property
    def total_cost(self) -> float:
        """Calculate the total cost of all entries in the session."""
        return sum(entry.cost_usd for entry in self.entries)

    @property
    def total_response_time(self) -> int:
        """Calculate the total response time of all entries in the session."""
        return sum(entry.response_time_ms for entry in self.entries)
    
    @property
    def total_tokens(self) -> int:
        """Calculate the total number of tokens used in the session."""
        return sum(entry.total_tokens for entry in self.entries)
    
    @property
    def models_used(self) -> set:
        """Get a set of unique models used in the session."""
        return {entry.model for entry in self.entries}
    
    @property
    def average_response_time(self) -> float:
        """Calculate the average response time of all entries in the session."""
        if not self.entries:
            return 0.0
        return self.total_response_time / len(self.entries)
    
    @property
    def average_cost(self) -> float:
        """Calculate the average cost of all entries in the session."""
        if not self.entries:
            return 0.0
        return self.total_cost / len(self.entries)
    
    @property
    def session_alive_time(self) -> str:
        """Calculate the total time the session has been alive."""
        if not self.entries:
            return "0 seconds"
        start_time = self.entries[0].timestamp
        current_time = datetime.now(timezone.utc)
        delta = current_time - start_time
        return str(delta)
    
    def __repr__(self):
        return f"SessionClass(session_id={self.session_id}, total_entries={len(self.entries)})"
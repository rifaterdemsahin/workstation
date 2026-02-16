import requests
import json
import os
from models.data_structures import SessionClass, UsageEntry
from datetime import datetime, timezone

def query_model(prompt: str, session=None):
    """
    Query the OpenRouter API with a given prompt and return the response.
    
    Args:
        prompt (str): The prompt to send to the model.
        session (SessionUsage, optional): The session object to track usage. Defaults to None.
    
    Returns:
        str: The response from the model.
    """
    openrouter_api_key = os.getenv("OPENROUTER_API_KEY")

    if not openrouter_api_key:
        raise ValueError("OPENROUTER_API_KEY environment variable is not set.")
    
    if not prompt:
        raise ValueError("Prompt cannot be empty.")

    # Prepare the API request
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {openrouter_api_key}",
        "Content-Type": "application/json"
    }
    data = {
        "model": "openai/gpt-4o",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 500,
    }
    
    response = requests.post(url, headers=headers, json=data)    

    if response.status_code == 200:
        response_data = response.json()

        if session:
            date_str = response.headers.get('Date')
            if date_str:
                # Parse GMT format: 'Wed, 25 Jun 2025 15:22:21 GMT'
                timestamp = datetime.strptime(date_str, '%a, %d %b %Y %H:%M:%S %Z')
                timestamp = timestamp.replace(tzinfo=timezone.utc)
            else:
                timestamp = datetime.now(timezone.utc)
            
            usage = response_data.get('usage', {})
    
            entry = UsageEntry(
                timestamp=timestamp,  # Use the parsed datetime, not the raw string
                model=response_data.get('model', ''),
                input_tokens=usage.get('prompt_tokens', 0),
                output_tokens=usage.get('completion_tokens', 0),
                total_tokens=usage.get('total_tokens', 0),
                cost_usd=usage.get('total_tokens', 0) * 0.0001,
                request_id=response_data.get('id', '')
            )
            session.add_entry(entry)
        return response_data['choices'][0]['message']['content']
    else:
        print(f"Error: {response.status_code} - {response.text}")
        return None
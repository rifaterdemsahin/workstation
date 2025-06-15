#!/bin/bash

# Simple AI CLI Tool
# Usage: ai "your question here"
# Or: ai < file.txt
# Or: echo "question" | ai

# Default model
MODEL="${AI_MODEL:-anthropic/claude-3.5-sonnet}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if API key is set
if [[ -z "$OPENROUTER_API_KEY" ]]; then
    echo -e "${RED}❌ Error: OPENROUTER_API_KEY not set${NC}"
    echo -e "${YELLOW}💡 Set it with: export OPENROUTER_API_KEY='your-api-key'${NC}"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ Error: jq is required${NC}"
    echo -e "${YELLOW}💡 Install with: brew install jq${NC}"
    exit 1
fi

# Help function
show_help() {
    echo -e "${BLUE}🤖 Simple AI CLI${NC}"
    echo ""
    echo -e "${GREEN}Usage:${NC}"
    echo "  ai \"What is today's date?\""
    echo "  ai \"Explain quantum physics\""
    echo "  echo \"Hello\" | ai"
    echo "  ai < myfile.txt"
    echo ""
    echo -e "${GREEN}Environment Variables:${NC}"
    echo "  OPENROUTER_API_KEY    Your API key (required)"
    echo "  AI_MODEL              Model to use (default: anthropic/claude-3.5-sonnet)"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  export AI_MODEL=\"openai/gpt-4o\""
    echo "  ai \"Write a haiku about cats\""
}

# Get input from command line argument, pipe, or stdin
if [[ $# -eq 0 ]]; then
    if [[ -p /dev/stdin ]]; then
        # Input from pipe
        INPUT=$(cat)
    else
        # No input provided
        show_help
        exit 1
    fi
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
else
    # Input from command line argument
    INPUT="$*"
fi

# Check if input is empty
if [[ -z "$INPUT" ]]; then
    echo -e "${RED}❌ No input provided${NC}"
    exit 1
fi

# Show what we're doing
echo -e "${BLUE}🤖 Thinking...${NC}"

# Escape quotes in input for JSON
ESCAPED_INPUT=$(echo "$INPUT" | sed 's/"/\\"/g' | sed 's/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
    "model": "$MODEL",
    "messages": [
        {"role": "user", "content": "$ESCAPED_INPUT"}
    ],
    "max_tokens": 4000
}
EOF
)

# Make API call
RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

# Check for curl error
if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Failed to connect to API${NC}"
    exit 1
fi

# Extract response
CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')
ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.error.message // empty')

# Handle errors
if [[ -n "$ERROR_MESSAGE" ]]; then
    echo -e "${RED}❌ API Error: $ERROR_MESSAGE${NC}"
    exit 1
fi

if [[ -z "$CONTENT" || "$CONTENT" == "null" ]]; then
    echo -e "${RED}❌ No response received${NC}"
    echo -e "${YELLOW}Raw response: $RESPONSE${NC}"
    exit 1
fi

# Output the response
echo ""
echo -e "${GREEN}✨ Response:${NC}"
echo "$CONTENT"
echo ""

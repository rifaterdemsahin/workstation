#!/bin/bash

# Simple AI CLI Tool with Context Support
# Usage: ai "your question here"
# Or: ai < file.txt
# Or: echo "question" | ai
# Or: ai --new "start a new conversation"
# Or: ai --context "show current conversation context"
# Or: ai --clear "clear conversation history"
# Or: ai --save "save conversation to second brain"

# Default model
MODEL="${AI_MODEL:-anthropic/claude-3.5-sonnet}"

# Context file location
CONTEXT_DIR="${HOME}/.ai_cli"
CONTEXT_FILE="${CONTEXT_DIR}/conversation.json"

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
    echo -e "${BLUE}🤖 Simple AI CLI with Context Support${NC}"
    echo ""
    echo -e "${GREEN}Usage:${NC}"
    echo "  ai \"What is today's date?\""
    echo "  ai \"Explain quantum physics\""
    echo "  echo \"Hello\" | ai"
    echo "  ai < myfile.txt"
    echo ""
    echo -e "${GREEN}Context Options:${NC}"
    echo "  ai --new \"Start a new conversation\""
    echo "  ai --context          Show current conversation context"
    echo "  ai --clear            Clear conversation history"
    echo "  ai --save \"Query to save to second brain\""
    echo ""
    echo -e "${GREEN}Environment Variables:${NC}"
    echo "  OPENROUTER_API_KEY    Your API key (required)"
    echo "  AI_MODEL              Model to use (default: anthropic/claude-3.5-sonnet)"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  export AI_MODEL=\"openai/gpt-4o\""
    echo "  ai \"Write a haiku about cats\""
    echo "  ai \"Tell me more about their behavior\""
}

# Initialize context directory if it doesn't exist
init_context() {
    if [[ ! -d "$CONTEXT_DIR" ]]; then
        mkdir -p "$CONTEXT_DIR"
    fi
    
    if [[ ! -f "$CONTEXT_FILE" || "$1" == "new" ]]; then
        echo '{"messages":[]}' > "$CONTEXT_FILE"
        echo -e "${GREEN}✨ Started a new conversation${NC}"
    fi
}

# Show current conversation context
show_context() {
    if [[ ! -f "$CONTEXT_FILE" ]]; then
        echo -e "${YELLOW}⚠️ No active conversation${NC}"
        return
    fi
    
    echo -e "${BLUE}🔄 Current Conversation:${NC}"
    echo ""
    
    # Extract and display messages in a readable format
    jq -r '.messages[] | "\(.role): \(.content)"' "$CONTEXT_FILE" | while read -r line; do
        role=${line%%: *}
        content=${line#*: }
        
        if [[ "$role" == "user" ]]; then
            echo -e "${YELLOW}You: ${NC}$content"
        else
            echo -e "${GREEN}AI: ${NC}$content"
        fi
        echo ""
    done
}

# Add a message to the context
add_to_context() {
    local role="$1"
    local content="$2"
    
    # Create a temporary file with the new message added
    jq --arg role "$role" --arg content "$content" '.messages += [{"role": $role, "content": $content}]' "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp"
    mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"
}

# Save conversation to second brain
save_to_secondbrain() {
    local conversation_id=$(date +%Y%m%d%H%M%S)
    local save_dir="${HOME}/secondbrain/ai_conversations"
    local save_file="${save_dir}/conversation_${conversation_id}.md"
    
    # Create directory if it doesn't exist
    if [[ ! -d "$save_dir" ]]; then
        mkdir -p "$save_dir"
    fi
    
    # Create markdown file with conversation
    echo "# AI Conversation - $(date)" > "$save_file"
    echo "" >> "$save_file"
    
    # Extract and save messages in markdown format
    jq -r '.messages[] | "\(.role): \(.content)"' "$CONTEXT_FILE" | while read -r line; do
        role=${line%%: *}
        content=${line#*: }
        
        if [[ "$role" == "user" ]]; then
            echo "## User" >> "$save_file"
        else
            echo "## Assistant" >> "$save_file"
        fi
        
        echo "$content" >> "$save_file"
        echo "" >> "$save_file"
    done
    
    echo -e "${GREEN}✨ Conversation saved to second brain: $save_file${NC}"
}

# Get input from command line argument, pipe, or stdin
NEW_CONVERSATION=false
SHOW_CONTEXT=false
CLEAR_CONTEXT=false
SAVE_TO_SECONDBRAIN=false

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
elif [[ "$1" == "--new" ]]; then
    NEW_CONVERSATION=true
    shift
    INPUT="$*"
elif [[ "$1" == "--context" ]]; then
    SHOW_CONTEXT=true
elif [[ "$1" == "--clear" ]]; then
    CLEAR_CONTEXT=true
elif [[ "$1" == "--save" ]]; then
    SAVE_TO_SECONDBRAIN=true
    shift
    INPUT="$*"
else
    # Input from command line argument
    INPUT="$*"
fi

# Initialize context
if [[ "$NEW_CONVERSATION" == true ]]; then
    init_context "new"
else
    init_context
fi

# Show context if requested
if [[ "$SHOW_CONTEXT" == true ]]; then
    show_context
    exit 0
fi

# Clear context if requested
if [[ "$CLEAR_CONTEXT" == true ]]; then
    init_context "new"
    echo -e "${GREEN}✨ Conversation history cleared${NC}"
    exit 0
fi

# Check if input is empty
if [[ -z "$INPUT" ]]; then
    echo -e "${RED}❌ No input provided${NC}"
    exit 1
fi

# Show what we're doing
echo -e "${BLUE}🧠 AI is thinking...${NC}"

# Escape quotes in input for JSON
ESCAPED_INPUT=$(echo "$INPUT" | sed 's/"/\\"/g' | sed 's/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

# Add user message to context
add_to_context "user" "$INPUT"

# Create JSON payload with full conversation history
JSON_PAYLOAD=$(jq --arg model "$MODEL" '{model: $model, messages: .messages, max_tokens: 4000}' "$CONTEXT_FILE")

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

# Add assistant response to context
add_to_context "assistant" "$CONTENT"

# Save to second brain if requested
if [[ "$SAVE_TO_SECONDBRAIN" == true ]]; then
    save_to_secondbrain
fi

# Output the response with visual separator
echo ""
echo -e "${RED}████████████████████████████████████████████████████████████████████████████████${NC}"
echo -e "${GREEN}🤖 AI Response:${NC}"
echo -e "${RED}████████████████████████████████████████████████████████████████████████████████${NC}"
echo ""
echo "$CONTENT"
echo ""
echo -e "${RED}████████████████████████████████████████████████████████████████████████████████${NC}"

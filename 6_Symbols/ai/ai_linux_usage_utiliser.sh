#!/bin/bash

# Enhanced AI CLI Tool with Usage Tracking
# Usage: ai "your question here"
# Or: ai burn      (show burn rate)
# Or: ai stats     (show usage statistics)
# Or: ai limits    (show model limits)

# Default model
MODEL="${AI_MODEL:-anthropic/claude-3.5-sonnet}"

# Context file location
CONTEXT_DIR="${HOME}/.ai_cli"
CONTEXT_FILE="${CONTEXT_DIR}/conversation.json"
USAGE_LOG="${CONTEXT_DIR}/usage.jsonl"

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

# Check for dependencies
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ Error: jq is required${NC}"
        echo -e "${YELLOW}💡 Install with: brew install jq${NC}"
        exit 1
    fi
    
    # Check for bc (basic calculator) - needed for cost calculations
    if ! command -v bc &> /dev/null; then
        echo -e "${YELLOW}⚠️ Warning: bc not found, cost estimates will be unavailable${NC}"
        echo -e "${YELLOW}💡 Install with: apt install bc (Ubuntu) or brew install bc (Mac)${NC}"
    fi
}

# Initialize usage tracking
init_usage_tracking() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        touch "$USAGE_LOG"
        echo -e "${GREEN}✨ Initialized usage tracking${NC}"
    fi
}

init_context() {
    if [[ ! -d "$CONTEXT_DIR" ]]; then
        mkdir -p "$CONTEXT_DIR"
    fi
    
    if [[ ! -f "$CONTEXT_FILE" || "$1" == "new" ]]; then
        echo '{"messages":[]}' > "$CONTEXT_FILE"
        echo -e "${GREEN}✨ Started a new conversation${NC}"
    fi
}

show_context() {
    if [[ ! -f "$CONTEXT_FILE" ]]; then
        echo -e "${YELLOW}⚠️ No active conversation${NC}"
        return
    fi
    
    echo -e "${BLUE}🔄 Current Conversation:${NC}"
    echo ""
    
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

add_to_context() {
    local role="$1"
    local content="$2"
    
    jq --arg role "$role" --arg content "$content" '.messages += [{"role": $role, "content": $content}]' "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp"
    mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"
}

# Cross-platform timestamp function
get_timestamp_ms() {
    # Try different approaches for cross-platform millisecond timestamps
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        python3 -c "import time; print(int(time.time() * 1000))" 2>/dev/null || echo $(($(date +%s) * 1000))
    elif command -v date >/dev/null 2>&1 && date +%s%3N >/dev/null 2>&1; then
        # Linux with millisecond support
        date +%s%3N
    else
        # Fallback: seconds * 1000
        echo $(($(date +%s) * 1000))
    fi
}

# Safe arithmetic for large numbers
safe_subtract() {
    local end_time="$1"
    local start_time="$2"   
    # Use bc if available, otherwise python, otherwise basic subtraction
    if command -v bc &> /dev/null; then
        echo "$end_time - $start_time" | bc
    elif command -v python3 &> /dev/null; then
        python3 -c "print(int($end_time) - int($start_time))"
    else
        # Fallback to bash arithmetic (may overflow with large numbers)
        echo $(($end_time - $start_time))
    fi
}
log_usage() {
    local model="$1"
    local input_tokens="$2"
    local output_tokens="$3"
    local cost="$4"
    local response_time_ms="$5"
    local request_id="$6"
    
    # Create usage entry as JSON
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local usage_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg model "$model" \
        --arg input_tokens "$input_tokens" \
        --arg output_tokens "$output_tokens" \
        --arg cost "$cost" \
        --arg response_time "$response_time_ms" \
        --arg request_id "$request_id" \
        '{
            timestamp: $timestamp,
            model: $model,
            input_tokens: ($input_tokens | tonumber),
            output_tokens: ($output_tokens | tonumber),
            cost_usd: ($cost | tonumber),
            response_time_ms: ($response_time | tonumber),
            request_id: $request_id
        }')
    
    # Append to usage log
    echo "$usage_entry" >> "$USAGE_LOG"
}

# Extract token counts from OpenRouter response
extract_usage_data() {
    local response="$1"
    local model="$2"
    
    # Extract usage data from response
    local input_tokens=$(echo "$response" | jq -r '.usage.prompt_tokens // 0')
    local output_tokens=$(echo "$response" | jq -r '.usage.completion_tokens // 0')
    local total_tokens=$(echo "$response" | jq -r '.usage.total_tokens // 0')
    
    # Calculate cost estimate (OpenRouter doesn't always provide cost)
    local cost=$(echo "$response" | jq -r '.usage.cost // null')
    if [[ "$cost" == "null" ]] && command -v bc &> /dev/null; then
        # Estimate cost based on model (rough estimates in USD per 1M tokens)
        case "$model" in
            *claude-3.5-sonnet*)
                cost=$(echo "scale=6; ($input_tokens * 3.0 + $output_tokens * 15.0) / 1000000" | bc -l 2>/dev/null || echo "0.0")
                ;;
            *claude-3-opus*)
                cost=$(echo "scale=6; ($input_tokens * 15.0 + $output_tokens * 75.0) / 1000000" | bc -l 2>/dev/null || echo "0.0")
                ;;
            *gpt-4*)
                cost=$(echo "scale=6; ($input_tokens * 10.0 + $output_tokens * 30.0) / 1000000" | bc -l 2>/dev/null || echo "0.0")
                ;;
            *)
                cost="0.0"
                ;;
        esac
    elif [[ "$cost" == "null" ]]; then
        cost="0.0"
    fi
    
    echo "$input_tokens:$output_tokens:$cost"
}
get_timestamp_ms() {
    # Try different approaches for cross-platform millisecond timestamps
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        python3 -c "import time; print(int(time.time() * 1000))" 2>/dev/null || echo $(($(date +%s) * 1000))
    elif command -v date >/dev/null 2>&1 && date +%s%3N >/dev/null 2>&1; then
        # Linux with millisecond support
        date +%s%3N
    else
        # Fallback: seconds * 1000
        echo $(($(date +%s) * 1000))
    fi
}

safe_subtract() {
    local end_time="$1"
    local start_time="$2"
    
    # Use bc if available, otherwise python, otherwise basic subtraction
    if command -v bc &> /dev/null; then
        echo "$end_time - $start_time" | bc
    elif command -v python3 &> /dev/null; then
        python3 -c "print(int($end_time) - int($start_time))"
    else
        # Fallback to bash arithmetic (may overflow with large numbers)
        echo $(($end_time - $start_time))
    fi
}
# Usage tracking CLI commands
handle_monitoring_commands() {
    case "$1" in
        "burn")
            python3 -c "
import sys
sys.path.append('$CONTEXT_DIR')
try:
    from usage_monitor.cli.commands import show_burn_rate
    show_burn_rate()
except ImportError:
    print('Usage monitoring not yet installed. Run: ai setup-monitoring')
except Exception as e:
    print(f'Error: {e}')
"
            exit 0
            ;;
        "stats")
            python3 -c "
import sys
sys.path.append('$CONTEXT_DIR')
try:
    from usage_monitor.cli.commands import show_stats
    show_stats('${2:-today}')
except ImportError:
    print('Usage monitoring not yet installed. Run: ai setup-monitoring')
except Exception as e:
    print(f'Error: {e}')
"
            exit 0
            ;;
        "limits")
            python3 -c "
import sys
sys.path.append('$CONTEXT_DIR')
try:
    from usage_monitor.cli.commands import show_limits
    show_limits()
except ImportError:
    print('Usage monitoring not yet installed. Run: ai setup-monitoring')
except Exception as e:
    print(f'Error: {e}')
"
            exit 0
            ;;
        "setup-monitoring")
            echo -e "${BLUE}🔧 Setting up usage monitoring...${NC}"
            python3 -c "
import os, sys
sys.path.append('$CONTEXT_DIR')
try:
    from usage_monitor.setup import install_monitoring
    install_monitoring('$CONTEXT_DIR')
    print('✨ Usage monitoring installed successfully!')
except Exception as e:
    print(f'❌ Setup failed: {e}')
    print('Will create basic monitoring structure...')
    os.makedirs('$CONTEXT_DIR/usage_monitor', exist_ok=True)
"
            exit 0
            ;;
    esac
}

# Help function (updated)
show_help() {
    echo -e "${BLUE}🤖 AI CLI with Usage Monitoring${NC}"
    echo ""
    echo -e "${GREEN}Usage:${NC}"
    echo "  ai \"What is today's date?\""
    echo "  ai \"Explain quantum physics\""
    echo "  echo \"Hello\" | ai"
    echo "  ai < myfile.txt"
    echo ""
    echo -e "${GREEN}Monitoring Commands:${NC}"
    echo "  ai burn               Show current burn rate and usage"
    echo "  ai stats [period]     Show usage statistics (today, week, month)"
    echo "  ai limits             Show model limits and quotas"
    echo "  ai setup-monitoring   Install usage monitoring components"
    echo ""
    echo -e "${GREEN}Context Options:${NC}"
    echo "  ai --new \"Start a new conversation\""
    echo "  ai --context          Show current conversation context"
    echo "  ai --clear            Clear conversation history"
    echo ""
    echo -e "${GREEN}Environment Variables:${NC}"
    echo "  OPENROUTER_API_KEY    Your API key (required)"
    echo "  AI_MODEL              Model to use (default: anthropic/claude-3.5-sonnet)"
}

# [Previous functions remain the same: init_context, show_context, add_to_context, etc.]
# ... (keeping your existing functions for brevity)

# Main execution
check_dependencies

# Handle special commands first (before initializing context)
if [[ $# -gt 0 ]]; then
    case "$1" in
        "burn"|"stats"|"limits"|"setup-monitoring")
            # Initialize minimal setup for monitoring commands
            mkdir -p "$CONTEXT_DIR"
            handle_monitoring_commands "$1" "$2"
            exit 0
            ;;
        "--help"|"-h")
            show_help
            exit 0
            ;;
        "--context")
            mkdir -p "$CONTEXT_DIR"
            show_context
            exit 0
            ;;
        "--clear")
            rm -f "$CONTEXT_FILE"
            echo -e "${GREEN}✨ Conversation history cleared${NC}"
            exit 0
            ;;
        "--new")
            # Handle new conversation flag
            NEW_CONVERSATION=true
            shift
            ;;
    esac
fi

# Initialize context and usage tracking
if [[ "$NEW_CONVERSATION" == "true" ]]; then
    init_context "new"
else
    init_context
fi
init_usage_tracking

# Prepare user input for the API
if [ -t 0 ]; then
    # Input from command line argument
    USER_INPUT="$*"
else
    # Input from stdin
    USER_INPUT="$(cat)"
fi

# Check if we have any input
if [[ -z "$USER_INPUT" ]]; then
    echo -e "${YELLOW}No input provided. Use --help for usage information.${NC}"
    exit 1
fi

# Add user message to context
add_to_context "user" "$USER_INPUT"

# Prepare JSON payload from context
JSON_PAYLOAD=$(jq -n \
    --arg model "$MODEL" \
    --argjson messages "$(jq '.messages' "$CONTEXT_FILE")" \
    '{model: $model, messages: $messages}')

# Record start time for response time measurement
START_TIME=$(get_timestamp_ms)

# Generate request ID
REQUEST_ID=$(date +%s%N 2>/dev/null | md5sum 2>/dev/null | cut -c1-8 2>/dev/null || echo "req-$(date +%s)")

# Make API call
RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

# Calculate response time
END_TIME=$(get_timestamp_ms)
RESPONSE_TIME=$(safe_subtract "$END_TIME" "$START_TIME")

# Check for curl error
if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Failed to connect to API${NC}"
    exit 1
fi

# Extract response content and usage data
CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')
ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.error.message // empty')

# Handle errors
if [[ -n "$ERROR_MESSAGE" ]]; then
    echo -e "${RED}❌ API Error: $ERROR_MESSAGE${NC}"
    exit 1
fi

if [[ -z "$CONTENT" || "$CONTENT" == "null" ]]; then
    echo -e "${RED}❌ No response received${NC}"
    exit 1
fi

# Extract and log usage data
USAGE_DATA=$(extract_usage_data "$RESPONSE" "$MODEL")
IFS=':' read -r INPUT_TOKENS OUTPUT_TOKENS COST <<< "$USAGE_DATA"

# Log usage for monitoring
log_usage "$MODEL" "$INPUT_TOKENS" "$OUTPUT_TOKENS" "$COST" "$RESPONSE_TIME" "$REQUEST_ID"

# Add assistant response to context
add_to_context "assistant" "$CONTENT"

# Output the response
echo ""
echo -e "${GREEN}✨ Response:${NC}"
echo "$CONTENT"
echo ""

# Show brief usage info if available
if [[ "$INPUT_TOKENS" != "0" || "$OUTPUT_TOKENS" != "0" ]]; then
    echo -e "${BLUE}📊 Usage: ${INPUT_TOKENS} in + ${OUTPUT_TOKENS} out = $((INPUT_TOKENS + OUTPUT_TOKENS)) tokens (~\$${COST})${NC}"
fi

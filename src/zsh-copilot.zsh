# Forked from https://github.com/Gamma-Software/zsh-copilot

SCRIPT_PATH=${(%):-%x}
ZSH_COPILOT_PREFIX=${SCRIPT_PATH:A:h}
ZSH_COPILOT_PLUGIN_DIR=${ZSH_COPILOT_PREFIX}/../

# Source env
source "${ZSH_COPILOT_PLUGIN_DIR}/.env"

# Global variable to store the current suggestion
ZSH_COPILOT_SUGGESTION=""

# =============================================================================
# API VALIDATION
# =============================================================================

function _zsh_validate_ping_api() {
    local response_code=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $ZSH_COPILOT_API_KEY" -d '{"messages":[{"role":"user","content":"test"}],"model":"'$ZSH_COPILOT_MODEL'"}' $ZSH_COPILOT_API_URL -s -o /dev/null -w "%{http_code}")
    if [[ $response_code -eq 401 ]]; then
        echo "\033[0;31mError: Invalid API key\033[0m"
        return 1
    elif [[ $response_code -eq 429 ]]; then
        echo "\033[0;31mError: Rate limit exceeded\033[0m"
        return 1
    elif [[ $response_code -eq 000 ]]; then
        echo "\033[0;31mError: Could not connect to API. Please check your internet connection.\033[0m"
        return 1
    elif [[ $response_code -ne 200 ]]; then
        echo "\033[0;31mError: API returned status code $response_code\033[0m"
        return 1
    fi
    return 0
}

# Test the API connection
_zsh_validate_ping_api

# =============================================================================
# PREDICTION LOGIC
# =============================================================================

function predict() {
    local history_size=10
    local current_dir=$(pwd)

    # Gather recent command history
    local history_data=$(tail -n $history_size ~/.zsh_history) # TODO: can use histdb instead
    
    # Get the current command line content
    local current_input=$BUFFER

    # Construct the user content
    local user_content="Current directory: ${current_dir}
Recent commands:
${history_data}
Partial command: ${current_input}"

    # Construct the messages array using jq
    local messages=$(jq -n \
        --arg sys_role "You are a shell command suggestion tool. Based on the current context, suggest a single command that would be most useful. If there's a partial command, complete it appropriately. Provide ONLY the command, no explanations." \
        --arg user_content "$user_content" \
        '[
            {"role": "system", "content": $sys_role},
            {"role": "user", "content": $user_content}
        ]')

    # Set default values if environment variables are empty
    local model=${ZSH_COPILOT_MODEL:-"gpt-4o-mini"}
    local tokens=${ZSH_COPILOT_TOKENS:-"1024"}
    local api_url=${ZSH_COPILOT_API_URL:-"https://api.openai.com/v1/chat/completions"}

    local json_data=$(jq -n \
        --argjson messages "$messages" \
        --arg model "$model" \
        --argjson tokens "$tokens" \
        '{
            "messages": $messages,
            "model": $model,
            "max_tokens": $tokens
        }')

    # Make API call and extract response
    local response=$(curl -s -X POST "$api_url" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ZSH_COPILOT_API_KEY" \
        -d "$json_data")

    if echo -E "$response" | jq -e '.error' > /dev/null; then
        echo "API Error: $(echo -E "$response" | jq -r '.error.message // .error')" >&2
        return 1
    fi

    # Extract and return the suggestion
    echo -E "$response" | jq -r '.choices[0].message.content'
}

# =============================================================================
# ZLE WIDGETS
# =============================================================================

function predict-widget() {
    # Run prediction
    local result=$(predict)
    
    if [[ $? -eq 0 && -n "$result" ]]; then
        # Store the suggestion globally
        ZSH_COPILOT_SUGGESTION="$result"
        
        # Display colored suggestion using printf and cursor positioning
        printf "\n💡 \e[36mSuggestion:\e[0m \e[92m%s\e[0m \e[90m(Press Tab to accept, Esc to dismiss)\e[0m" "$result"
    else
        ZSH_COPILOT_SUGGESTION=""
        printf "\n❌ \e[31mNo suggestion available\e[0m"
    fi

    # Refresh the display
    zle -R
}

function accept-suggestion-widget() {
    if [[ -n "$ZSH_COPILOT_SUGGESTION" ]]; then
        # Clear the suggestion display
        printf "\033[2K\r"  # Clear entire line and return to beginning
        printf "\033[A\033[2K"  # Move up one line and clear it
        
        # Replace the current buffer with the suggestion
        BUFFER="$ZSH_COPILOT_SUGGESTION"
        # Move cursor to the end
        CURSOR=${#BUFFER}
        # Clear the suggestion
        ZSH_COPILOT_SUGGESTION=""
        
        # Force a complete redraw of the command line
        zle reset-prompt
        zle -R
    else
        # No suggestion available, fall back to default tab completion
        zle expand-or-complete
    fi
}

function dismiss-suggestion-widget() {
    # Clear the suggestion and message
    ZSH_COPILOT_SUGGESTION=""
    zle -M ""
}

# =============================================================================
# WIDGET REGISTRATION & KEYBINDINGS
# =============================================================================

# Register the widgets
zle -N predict-widget
zle -N accept-suggestion-widget
zle -N dismiss-suggestion-widget

# Bind the widgets
bindkey "^@" predict-widget           # Ctrl+Space to get suggestion
bindkey "^I" accept-suggestion-widget # Tab to accept suggestion
bindkey "^[" dismiss-suggestion-widget # Esc to dismiss suggestion

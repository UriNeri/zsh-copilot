# Command prediction script using ChatGPT
# This should be saved as a separate file

function predict-command() {
    local history_size=10  # Number of recent commands to analyze
    local current_dir=$(pwd)

    # Gather recent command history with exit codes
    local history_data=$(fc -l -n -$history_size |
        while IFS= read -r cmd; do
            # Skip the predict-command itself
            if [[ "$cmd" != "predict-command" && "$cmd" != "predict" ]]; then
                echo "Command: $cmd"
                # You might want to add error messages if available
            fi
        done)

    # Construct the prompt and escape it properly for JSON
    local prompt=$(echo "I am in directory: ${current_dir}

Recent command history:
${history_data}

Based on this history and context, what would be the most likely next command I want to run? Provide just the command without explanation." | jq -Rs .)

    # Remove the outer quotes that jq adds
    prompt=${prompt:1:-1}

    # Use the existing ask function with specific parameters
    ask -M "gpt-4" -t 150 "$prompt"
}

# Add an alias for easier access
alias predict='predict-command'

# Create a ZLE widget
function predict-widget() {
    # Run prediction
    local result=$(predict-command)

    # Put the result in the command line buffer
    BUFFER="$result"
    CURSOR=${#BUFFER}

    # Redisplay the command line with the prediction
    zle redisplay
}

# Register the widget
zle -N predict-widget

# Mac-friendly key bindings
# Option+p (most Mac terminals)
bindkey 'π' predict-widget
# Also add Ctrl+x p as an alternative
bindkey '^Xp' predict-widget
# Commands like fix-error, ask-command, etc.
function fix-error() {
    # Get the last command and its error message
    local last_command=$(fc -ln -1)
    local error_output=$(fc -ln -1 | sh 2>&1 >/dev/null)

    # Construct the prompt for error fixing
    local prompt=$(echo "I got this error when running: $last_command

Error message:
$error_output

Please provide just the corrected command without any explanation." | jq -Rs .)

    # Remove the outer quotes that jq adds
    prompt=${prompt:1:-1}

    # Get the command from copilot
    local result=$(zsh-copilot -o -M "$ZSH_COPILOT_MODEL" -t $ZSH_COPILOT_TOKENS "$prompt")

    # Add to next command buffer
    print -z "$result"
}


function fix-error-for-widget() {
    # Get the last command and its error message
    local last_command=$(fc -ln -1)
    local error_output=$(fc -ln -1 | sh 2>&1 >/dev/null)

    # Construct the prompt for command generation
    local prompt=$(echo "I got this error when running: $last_command

Error message:
$error_output

Please provide just the corrected command without any explanation." | jq -Rs .)

    # Remove the outer quotes that jq adds
    prompt=${prompt:1:-1}

    # Use the existing ask function with specific parameters
    zsh-copilot -o -M "$ZSH_COPILOT_MODEL" -t $ZSH_COPILOT_TOKENS "$prompt"
}


function ask_command() {
    local request="$1"

    # Construct the prompt for command generation
    local prompt=$(printf "I need a command to: %s\n\nPlease provide just the command without any explanation. Make it a single line that can be executed in a zsh terminal." "$request" | sed 's/"/\\"/g' | tr '\n' ' ')

    # Get the command from copilot
    local result=$(zsh-copilot -o -M "$ZSH_COPILOT_MODEL" -t $ZSH_COPILOT_TOKENS "$prompt")

    # Add to next command buffer
    print -z "$result"
}

function ask-command-for-widget() {
    local request="$1"

    # Construct the prompt for command generation
    local prompt=$(echo "I need a command to: $request

Please provide just the command without any explanation. Make absolutely sure it is a single line that can be directly executed in a zsh terminal." | jq -Rs .)

    # Remove the outer quotes that jq adds
    prompt=${prompt:1:-1}

    # Use the existing ask function with specific parameters
    zsh-copilot -o -M "$ZSH_COPILOT_MODEL" -t $ZSH_COPILOT_TOKENS "$prompt"
}

function predict() {
    local history_size=10  # Number of recent commands to analyze
    local current_dir=$(pwd)

    # Gather recent command history with exit codes
    local history_data=$(fc -l -n -$history_size |
        while IFS= read -r cmd; do
            # Skip the predict-command itself
            if [[ "$cmd" != "predict" ]]; then
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
    zsh-copilot -o -M "gpt-4" -t $ZSH_COPILOT_TOKENS "$prompt"
}
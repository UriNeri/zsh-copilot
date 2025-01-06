# https://github.com/Gamma-Software/zsh-copilot
# Copyright (c) 2024-2025 Gamma Software

# Get the path to the current script file
SCRIPT_PATH=${(%):-%x}

function _setup-zsh-copilot() {
    # Set the plugin directory as the prefix
    typeset -g ZSH_COPILOT_PREFIX=${SCRIPT_PATH:A:h}
    # Source .env file if it exists
    if [[ -f "$ZSH_COPILOT_PREFIX/.env" ]]; then
        source "$ZSH_COPILOT_PREFIX/.env"
    fi

    (( ! ${+ZSH_COPILOT_REPO} )) &&
    typeset -g ZSH_COPILOT_REPO="https://github.com/Gamma-Software/zsh-copilot"

    # Get the corresponding endpoint for your desired model.
    (( ! ${+ZSH_COPILOT_API_URL} )) &&
    typeset -g ZSH_COPILOT_API_URL="https://api.openai.com/v1/chat/completions"

    # Fill up your OpenAI api key here.
    if (( ! ${+ZSH_COPILOT_API_KEY} )); then
        echo "Error: ZSH_COPILOT_API_KEY is not set."
        echo "Please reinstall the plugin and follow the setup instructions at:"
        echo "https://github.com/Gamma-Software/zsh-copilot#installation"
        return 1
    fi

    # Default configurations
    (( ! ${+ZSH_COPILOT_MODEL} )) &&
    typeset -g ZSH_COPILOT_MODEL="gpt-3.5-turbo"
    (( ! ${+ZSH_COPILOT_TOKENS} )) &&
    typeset -g ZSH_COPILOT_TOKENS=800

    (( ! ${+ZSH_COPILOT_CONVERSATION} )) &&
    typeset -g ZSH_COPILOT_CONVERSATION=false
    (( ! ${+ZSH_COPILOT_INHERITS} )) &&
    typeset -g ZSH_COPILOT_INHERITS=false
    (( ! ${+ZSH_COPILOT_MARKDOWN} )) &&
    typeset -g ZSH_COPILOT_MARKDOWN=false
    (( ! ${+ZSH_COPILOT_STREAM} )) &&
    typeset -g ZSH_COPILOT_STREAM=false
    (( ! ${+ZSH_COPILOT_HISTORY} )) &&
    typeset -g ZSH_COPILOT_HISTORY=""
    (( ! ${+ZSH_COPILOT_INITIALROLE} )) &&
    typeset -g ZSH_COPILOT_INITIALROLE="system"
    (( ! ${+ZSH_COPILOT_INITIALPROMPT} )) &&
    typeset -g ZSH_COPILOT_INITIALPROMPT="You are a large language model trained by OpenAI. Answer as concisely as possible.\nKnowledge cutoff: {knowledge_cutoff} Current date: {current_date}"
}
_setup-zsh-copilot

function _zsh_copilot_show_help() {
  echo "Fix, predict, and ask commands using your command line Copilot powered by LLMs."
  echo "Usage: zsh-copilot [options...]"
  echo "       zsh-copilot [options...] '<your-question>'"
  echo "       zsh-copilot configure"
  echo "       zsh-copilot update"
  echo "       zsh-copilot uninstall"
  echo "Aliases: zsh-copilot <-> zc"
  echo "Options:"
  echo "  -h                Display this help message."
  echo "  -v                Display the version number."
  echo "  -M <openai_model> Set OpenAI model to <openai_model>, default sets to gpt-3.5-turbo."
  echo "                    Models can be found at https://platform.openai.com/docs/models."
  echo "  -t <max_tokens>   Set max tokens to <max_tokens>, default sets to 800."
  echo "  -r                Print raw output."
  echo "  -o                Print only the output."
  echo "  -d                Print debug information."
  echo "Commands:"
  echo "  configure         Configure plugin settings interactively."
  echo "  update           Update the plugin to the latest version."
  echo "  uninstall        Remove the plugin completely."
}

function _zsh_copilot_show_version() {
  cat "$ZSH_COPILOT_PREFIX/VERSION"
}

function _zsh_copilot_configure() {
    local env_file="$ZSH_COPILOT_PREFIX/.env"

    # Show current configuration
    function show_current_config() {
        echo "\033[0;34mCurrent Configuration:\033[0m"
        echo "\033[1;33m1.\033[0m Model: ${ZSH_COPILOT_MODEL}"
        echo "\033[1;33m2.\033[0m Max Tokens: ${ZSH_COPILOT_TOKENS}"
        echo "\033[1;33m3.\033[0m API Key: ${ZSH_COPILOT_API_KEY}"
        echo "\033[1;33m4.\033[0m Predict Shortcut: ${ZSH_COPILOT_SHORTCUT_PREDICT}"
        echo "\033[1;33m5.\033[0m Ask Shortcut: ${ZSH_COPILOT_SHORTCUT_ASK}"
        echo "\033[1;33m6.\033[0m Fix Shortcut: ${ZSH_COPILOT_SHORTCUT_FIX}"
        echo "\033[1;33m7.\033[0m Exit"
    }

    # Update configuration
    function update_config() {
        local param=$1
        local value=$2
        local param_name=$3

        # Create backup
        cp "$env_file" "$env_file.backup"

        # Update parameter
        sed -i.bak "s|$param=.*|$param=$value|" "$env_file"

        if [ $? -eq 0 ]; then
            echo "\033[0;32m$param_name updated successfully!\033[0m"
            source "$env_file"
        else
            echo "\033[0;31mFailed to update $param_name. Restoring backup...\033[0m"
            mv "$env_file.backup" "$env_file"
        fi

        # Clean up
        rm -f "$env_file.bak"
    }

    while true; do
        show_current_config
        echo "\n\033[0;34mWhat would you like to modify? (1-7):\033[0m"
        read choice

        case $choice in
            1)
                echo "\033[0;34mEnter new model (e.g., gpt-3.5-turbo, gpt-4):\033[0m"
                read new_model
                update_config "ZSH_COPILOT_MODEL" "$new_model" "Model"
                ;;
            2)
                echo "\033[0;34mEnter new max tokens (50-2000):\033[0m"
                read new_tokens
                if [[ "$new_tokens" =~ ^[0-9]+$ ]] && [ "$new_tokens" -ge 50 ] && [ "$new_tokens" -le 2000 ]; then
                    update_config "ZSH_COPILOT_TOKENS" "$new_tokens" "Max tokens"
                else
                    echo "\033[0;31mInvalid token value. Please enter a number between 50 and 2000.\033[0m"
                fi
                ;;
            3)
                echo "\033[0;34mEnter new OpenAI API key:\033[0m"
                read new_key
                if [ -n "$new_key" ]; then
                    update_config "ZSH_COPILOT_API_KEY" "$new_key" "API key"
                else
                    echo "\033[0;31mAPI key cannot be empty.\033[0m"
                fi
                ;;
            4)
                echo "\033[0;34mEnter new predict shortcut (e.g., π):\033[0m"
                read new_predict
                update_config "ZSH_COPILOT_SHORTCUT_PREDICT" "$new_predict" "Predict shortcut"
                ;;
            5)
                echo "\033[0;34mEnter new ask shortcut (e.g., æ):\033[0m"
                read new_ask
                update_config "ZSH_COPILOT_SHORTCUT_ASK" "$new_ask" "Ask shortcut"
                ;;
            6)
                echo "\033[0;34mEnter new fix shortcut (e.g., ƒ):\033[0m"
                read new_fix
                update_config "ZSH_COPILOT_SHORTCUT_FIX" "$new_fix" "Fix shortcut"
                ;;
            7)
                echo "\033[0;32mConfiguration complete!\033[0m"
                return 0
                ;;
            *)
                echo "\033[0;31mInvalid choice. Please select 1-7.\033[0m"
                ;;
        esac
        echo
    done
}

function _zsh_copilot_uninstall() {
    echo "\033[0;34mUninstalling zsh-copilot...\033[0m"

    # Ask for confirmation
    echo "\033[0;31mThis will remove zsh-copilot completely. Are you sure? (y/N)\033[0m"
    read confirm
    if [[ "$confirm" != "y" ]]; then
        echo "\033[0;32mUninstall cancelled.\033[0m"
        return 1
    fi

    # Plugin name
    PLUGIN_NAME="zsh-copilot"

    # Determine ZSH_CUSTOM path if not set
    if [ -z "$ZSH_CUSTOM" ]; then
        ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    fi

    PLUGIN_DIR="$ZSH_CUSTOM/plugins/$PLUGIN_NAME"

    # Remove plugin from .zshrc
    if grep -q "plugins=.*$PLUGIN_NAME" "$HOME/.zshrc"; then
        echo "\033[0;34mRemoving plugin from .zshrc...\033[0m"
        # Create backup of .zshrc
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
        # Remove plugin from plugins list
        sed -i.bak "s/$PLUGIN_NAME//" "$HOME/.zshrc"
        # Clean up empty spaces in plugins list
        sed -i.bak 's/plugins=(  *)/plugins=()/' "$HOME/.zshrc"
        sed -i.bak 's/  */ /g' "$HOME/.zshrc"
        echo "\033[0;32mPlugin removed from .zshrc\033[0m"
        echo "\033[0;34mBackup created at ~/.zshrc.backup\033[0m"
    fi

    # Remove plugin directory
    if [ -d "$PLUGIN_DIR" ]; then
        echo "\033[0;34mRemoving plugin directory...\033[0m"
        rm -rf "$PLUGIN_DIR"
        if [ $? -eq 0 ]; then
            echo "\033[0;32mPlugin directory removed successfully\033[0m"
        else
            echo "\033[0;31mFailed to remove plugin directory\033[0m"
            return 1
        fi
    fi

    # Clean up any temporary files
    rm -f "$HOME/.zshrc.bak"

    echo "\033[0;32mUninstallation complete!\033[0m"
    echo "\033[0;34mPlease restart your terminal or run: source ~/.zshrc\033[0m"

    # Exit the shell since we just removed the current script
    exit 0
}

function _zsh_copilot_update() {
    echo "\033[0;34mUpdating zsh-copilot...\033[0m"

    # Store current directory
    local current_dir=$(pwd)

    # Change to plugin directory
    cd "$ZSH_COPILOT_PREFIX"

    # Backup .env file if it exists
    if [[ -f ".env" ]]; then
        cp .env .env.backup
    fi

    # Pull latest changes
    if git pull origin main; then
        echo "\033[0;32mSuccessfully updated zsh-copilot!\033[0m"

        # Restore .env file if it existed
        if [[ -f ".env.backup" ]]; then
            mv .env.backup .env
        fi

        echo "\033[0;34mPlease restart your terminal or run: source ~/.zshrc\033[0m"
    else
        echo "\033[0;31mUpdate failed. Please try again or report the issue.\033[0m"

        # Restore .env backup if update failed
        if [[ -f ".env.backup" ]]; then
            mv .env.backup .env
        fi
    fi

    # Return to original directory
    cd "$current_dir"
}

function zsh-copilot() {
    local api_url=$ZSH_COPILOT_API_URL
    local api_key=$ZSH_COPILOT_API_KEY
    local conversation=$ZSH_COPILOT_CONVERSATION
    local markdown=$ZSH_COPILOT_MARKDOWN
    local stream=$ZSH_COPILOT_STREAM
    local tokens=$ZSH_COPILOT_TOKENS
    local inherits=$ZSH_COPILOT_INHERITS
    local model=$ZSH_COPILOT_MODEL
    local history=""

    local usefile=false
    local filepath=""
    local requirements=("curl" "jq")
    local debug=false
    local raw=false
    local output=false
    local satisfied=true
    local input=""
    local assistant="assistant"
    while getopts ":hvcdmsiroM:f:t:" opt; do
        case $opt in
            h)
                _zsh_copilot_show_help
                return 0
                ;;
            v)
                _zsh_copilot_show_version
                return 0
                ;;
            c)
                conversation=true
                ;;
            d)
                debug=true
                ;;
            i)
                inherits=true
                ;;
            t)
                if ! [[ $OPTARG =~ ^[0-9]+$ ]]; then
                    echo "Max tokens has to be an valid numbers."
                    return 1
                else
                    tokens=$OPTARG
                fi
                ;;
            f)
                usefile=true
                if ! [ -f $OPTARG ]; then
                    echo "$OPTARG does not exist."
                    return 1
                else
                    if ! which "xargs" > /dev/null; then
                        echo "xargs is required for file."
                        satisfied=false
                    fi
                    filepath=$OPTARG
                fi
                ;;
            M)
                model=$OPTARG
                ;;
            m)
                markdown=true
                if ! which "glow" > /dev/null; then
                    echo "glow is required for markdown rendering."
                    satisfied=false
                fi
                ;;
            s)
                stream=true
                ;;
            o)
                output=true
                ;;
            r)
                raw=true
                ;;
            :)
                echo "-$OPTARG needs a parameter"
                return 1
                ;;
        esac
    done

    for i in "${requirements[@]}"
    do
    if ! which $i > /dev/null; then
        echo "zsh-copilot \033[0;31merror:\033[0m $i is required."
        return 1
    fi
    done

    if $inherits; then
        history=$ZSH_COPILOT_HISTORY
    fi

    if [ "$history" = "" ]; then
        history='{"role":"'$ZSH_COPILOT_INITIALROLE'", "content":"'$ZSH_COPILOT_INITIALPROMPT'"}, '
    fi

    shift $((OPTIND-1))

    input=$*

    if $usefile; then
        input="$input$(cat "$filepath")"
    elif ! $raw && [ "$input" = "" ]; then
        echo -n "\033[32muser: \033[0m"
        read -r input
    fi

    # Add configure command handling
    if [[ "$input" == "configure" ]]; then
        _zsh_copilot_configure
        return $?
    fi

    # Add uninstall command handling
    if [[ "$input" == "uninstall" ]]; then
        _zsh_copilot_uninstall
        return $?
    fi

    # Add update command handling
    if [[ "$input" == "update" ]]; then
        _zsh_copilot_update
        return $?
    fi

    while true; do
        history=$history' {"role":"user", "content":"'"$input"'"}'
        if $debug; then
            echo -E "$history"
        fi
        local data='{"messages":['$history'], "model":"'$model'", "stream":'$stream', "max_tokens":'$tokens'}'
        local message=""
        local generated_text=""
        if $stream; then
            local begin=true
            local token=""

            curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" -d $data $api_url | while read -r token; do
                if [ "$token" = "" ]; then
                    continue
                fi
                if $debug || $raw; then
                    echo -E $token
                fi
                if ! $raw; then
                    token=${token:6}
                    if ! $raw && [[ $token =~ '"delta":.*"role":"([^"]*)"' ]]; then
                        assistant=$match[1]
                        if ! $output; then
                            echo -n "\033[0;36m$assistant: \033[0m"
                        fi
                    fi
                    if [[ $token =~ '"delta":.*"content":"([^"]*)"' ]]; then
                        begin=false
                        echo -E $match[1]
                        generated_text=$generated_text$match[1]
                    fi
                    if [[ $token =~ '"finish_reason"' ]]; then
                        echo ""
                        break
                    fi
                fi
            done
            message='{"role":"'"$assistant"'", "content":"'"$generated_text"'"}'
        else
            local response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $api_key" -d $data $api_url)
            if $debug || $raw; then
                echo -E "$response"
            fi
            if ! $raw; then
                if ! $output; then
                    echo -n "\033[0;36m$assistant: \033[0m"
                fi
                if [[ $response =~ '"error":\{[^}]*\}' ]]; then
                    echo "zsh-copilot \033[0;31merror:\033[0m"
                    [[ $response =~ '"message":"([^"]*)"' ]] && echo $match[1]
                    return 1
                fi
            fi
            [[ $response =~ '"role":"([^"]*)"' ]] && assistant=$match[1]
            [[ $response =~ '"content":"([^"]*)"' ]] && generated_text=$match[1]
            message='{"role":"'"$assistant"'", "content":"'"$generated_text"'"}'
            if ! $raw; then
                if $markdown; then
                    echo -E $generated_text | glow
                else
                    echo -E $generated_text
                fi
            fi
        fi
        history=$history', '$message', '
        ZSH_COPILOT_HISTORY=$history
        if ! $conversation; then
            break
        fi
        echo -n "\033[0;32muser: \033[0m"
        if ! read -r input; then
            break
        fi
    done
}


# Command prediction script using ChatGPT
# This should be saved as a separate file

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
    local prompt="${${${${(q)current_dir}//\\/\\\\}//\"/\\\"}//\$/\\\$}"
    prompt="I am in directory: ${prompt}

Recent command history:
${history_data}

Based on this history and context, what would be the most likely next command I want to run? Provide just the command without explanation."

    # Use the existing ask function with specific parameters
    zsh-copilot -o -M "gpt-4" -t $ZSH_COPILOT_TOKENS "$prompt"
}

# Create a ZLE widget
function predict-widget() {
    # Run prediction
    local result=$(predict)

    # Put the result in the command line buffer
    BUFFER="$result"
    CURSOR=${#BUFFER}

    # Redisplay the command line with the prediction
    zle redisplay
}

# Create a function to ask for a specific command
function ask-command() {
    local request="$1"

    # Construct the prompt for command generation
    local prompt="${${${${(q)request}//\\/\\\\}//\"/\\\"}//\$/\\\$}"
    prompt="I need a command to: ${prompt}

Please provide just the command without any explanation. Make it a single line that can be executed in a zsh terminal."

    # Use the existing ask function with specific parameters
    zsh-copilot -o -M "$ZSH_COPILOT_MODEL" -t $ZSH_COPILOT_TOKENS "$prompt"
}

# Create a ZLE widget for ask-command
function ask-command-widget() {
    # Get the current buffer content
    local current_text="$BUFFER"

    # Clear line
    zle kill-whole-line

    # Only proceed if there's text in the buffer
    if [[ -n "$current_text" ]]; then
        # Run ask-command with current text and store result
        local result=$(ask-command "$current_text")

        # Put the result in the command line buffer
        BUFFER="$result"
        CURSOR=${#BUFFER}
    fi

    # Redisplay the command line with the suggestion
    zle redisplay
}

function fix-error() {
    # Get the last command and its error message
    local last_command=$(fc -ln -1)
    local error_output=$(fc -ln -1 | sh 2>&1 >/dev/null)

    # Construct the prompt for error fixing
    local prompt="${${${${(q)last_command}//\\/\\\\}//\"/\\\"}//\$/\\\$}"
    local error_output="${${${${(q)error_output}//\\/\\\\}//\"/\\\"}//\$/\\\$}"
    prompt="I got this error when running: ${prompt}

Error message:
${error_output}

Please provide just the corrected command without any explanation."

    # Use the existing copilot function with specific parameters
    zsh-copilot -o -M "$ZSH_COPILOT_MODEL" -t $ZSH_COPILOT_TOKENS "$prompt"
}

# Create a ZLE widget for fix-error
function fix-error-widget() {
    # Run fix-error and store result
    local result=$(fix-error)

    # Put the result in the command line buffer
    BUFFER="$result"
    CURSOR=${#BUFFER}

    # Redisplay the command line with the suggestion
    zle redisplay
}

# Register the widget
zle -N fix-error-widget
zle -N predict-widget
zle -N ask-command-widget

# Bind the shortcut
bindkey $ZSH_COPILOT_SHORTCUT_PREDICT predict-widget
bindkey $ZSH_COPILOT_SHORTCUT_ASK ask-command-widget
bindkey $ZSH_COPILOT_SHORTCUT_FIX fix-error-widget

alias zc="zsh-copilot"
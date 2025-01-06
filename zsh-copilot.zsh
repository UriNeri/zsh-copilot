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

    # Default shortcuts
    (( ! ${+ZSH_COPILOT_SHORTCUT_PREDICT} )) &&
    typeset -g ZSH_COPILOT_SHORTCUT_PREDICT="cf80"
    (( ! ${+ZSH_COPILOT_SHORTCUT_ASK} )) &&
    typeset -g ZSH_COPILOT_SHORTCUT_ASK="e6"
    (( ! ${+ZSH_COPILOT_SHORTCUT_FIX} )) &&
    typeset -g ZSH_COPILOT_SHORTCUT_FIX="c692"
}

function _zsh_validate_ping_api() {
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $ZSH_COPILOT_API_KEY" https://api.openai.com/v1/models)
    if [[ $response_code -eq 401 ]]; then
        echo "\033[0;31mError: Invalid API key\033[0m"
        return 1
    elif [[ $response_code -eq 429 ]]; then
        echo "\033[0;31mError: Rate limit exceeded\033[0m"
        return 1
    elif [[ $response_code -eq 000 ]]; then
        echo "\033[0;31mError: Could not connect to OpenAI API. Please check your internet connection.\033[0m"
        return 1
    elif [[ $response_code -ne 200 ]]; then
        echo "\033[0;31mError: API returned status code $response_code\033[0m"
        return 1
    fi
    return 0
}

_setup-zsh-copilot
_zsh_validate_ping_api

function _zsh_copilot_show_help() {
    echo "Fix, predict, and ask commands using your command line Copilot powered by LLMs."
    echo "Usage: zsh-copilot [options...]"
    echo "       zsh-copilot [options...] '<your-question>'"
    echo "       zsh-copilot config"
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
    echo "  config         Configure plugin settings interactively."
    echo "  update           Update the plugin to the latest version."
    echo "  uninstall        Remove the plugin completely."
    echo "  fix             Fix the last failed command."
    echo "  ask <request>    Get a command suggestion for your request."
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

    # Create .env file if it doesn't exist
    if [[ ! -f "$env_file" ]]; then
        echo "\033[0;34mCreating new .env file...\033[0m"
        cat > "$env_file" << EOL
ZSH_COPILOT_MODEL=${ZSH_COPILOT_MODEL}
ZSH_COPILOT_TOKENS=${ZSH_COPILOT_TOKENS}
ZSH_COPILOT_API_KEY=${ZSH_COPILOT_API_KEY}
ZSH_COPILOT_SHORTCUT_PREDICT=${ZSH_COPILOT_SHORTCUT_PREDICT}
ZSH_COPILOT_SHORTCUT_ASK=${ZSH_COPILOT_SHORTCUT_ASK}
ZSH_COPILOT_SHORTCUT_FIX=${ZSH_COPILOT_SHORTCUT_FIX}
EOL
    fi

    # Update configuration
    function update_config() {
        local param=$1
        local value=$2
        local param_name=$3

        # Create backup only if file exists
        if [[ -f "$env_file" ]]; then
            cp "$env_file" "$env_file.backup"
        fi

        if grep -q "^$param=" "$env_file"; then
            # Update existing parameter
            sed -i.bak "s|^$param=.*|$param=$value|" "$env_file"
        else
            # Add new parameter
            echo "$param=$value" >> "$env_file"
        fi

        if [ $? -eq 0 ]; then
            echo "\033[0;32m$param_name updated successfully!\033[0m"
            source "$env_file"
        else
            echo "\033[0;31mFailed to update $param_name.\033[0m"
            if [[ -f "$env_file.backup" ]]; then
                mv "$env_file.backup" "$env_file"
                echo "\033[0;34mRestored from backup.\033[0m"
            fi
        fi

        # Clean up
        rm -f "$env_file.bak"
        rm -f "$env_file.backup"
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
                echo "\033[0;34mPress the desired shortcut for predict command:\033[0m"
                local sequence=$(_zsh_copilot_detect_shortcut)
                if [[ -n "$sequence" ]]; then
                    update_config "ZSH_COPILOT_SHORTCUT_PREDICT" "$sequence" "Predict shortcut"
                fi
                ;;
            5)
                echo "\033[0;34mPress the desired shortcut for ask command:\033[0m"
                local sequence=$(_zsh_copilot_detect_shortcut)
                if [[ -n "$sequence" ]]; then
                    update_config "ZSH_COPILOT_SHORTCUT_ASK" "$sequence" "Ask shortcut"
                fi
                ;;
            6)
                echo "\033[0;34mPress the desired shortcut for fix command:\033[0m"
                local sequence=$(_zsh_copilot_detect_shortcut)
                if [[ -n "$sequence" ]]; then
                    update_config "ZSH_COPILOT_SHORTCUT_FIX" "$sequence" "Fix shortcut"
                fi
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
    zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/install.sh)"
}

function _zsh_copilot_install_prerequisites() {
    local os_type=$(uname -s)
    local missing_deps=()

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi

    # Check for jq
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi

    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        return 0
    fi

    echo "\033[0;34mInstalling missing dependencies: ${missing_deps[*]}\033[0m"

    case "$os_type" in
        Linux*)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y ${missing_deps[@]}
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y ${missing_deps[@]}
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y ${missing_deps[@]}
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Sy --noconfirm ${missing_deps[@]}
            else
                echo "\033[0;31mUnable to detect package manager. Please install ${missing_deps[*]} manually.\033[0m"
                return 1
            fi
            ;;
        Darwin*)
            if ! command -v brew >/dev/null 2>&1; then
                echo "\033[0;34mInstalling Homebrew...\033[0m"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install ${missing_deps[@]}
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows handling
            if [[ " ${missing_deps[@]} " =~ " jq " ]]; then
                echo "\033[0;34mInstalling jq for Windows...\033[0m"
                mkdir -p /usr/bin
                curl -L -o /usr/bin/jq.exe https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe
                chmod +x /usr/bin/jq.exe
            fi
            if [[ " ${missing_deps[@]} " =~ " curl " ]]; then
                echo "\033[0;31mcurl is required but not installed. Please install Git for Windows which includes curl.\033[0m"
                return 1
            fi
            ;;
        *)
            echo "\033[0;31mUnsupported operating system: $os_type\033[0m"
            return 1
            ;;
    esac

    # Verify installation
    local failed=0
    for dep in ${missing_deps[@]}; do
        if ! command -v $dep >/dev/null 2>&1; then
            echo "\033[0;31mFailed to install $dep\033[0m"
            failed=1
        fi
    done

    if [[ $failed -eq 0 ]]; then
        echo "\033[0;32mAll dependencies installed successfully!\033[0m"
        return 0
    else
        return 1
    fi
}

function _zsh_copilot_detect_shortcut() {
    # Enable raw input mode
    stty raw -echo

    # Read key sequence
    local key=""
    local sequence=""

    # Read first character
    read -k1 key
    sequence+=$key

    # Handle escape sequences
    if [[ $key == $'\e' ]]; then
        # Read potential modifiers and key
        read -k1 -t 0.1 key
        sequence+=$key
        if [[ $key == "[" ]]; then
            read -k1 -t 0.1 key
            sequence+=$key
            # Read any additional characters
            while read -k1 -t 0.1 key; do
                sequence+=$key
            done
        fi
    fi

    # Restore terminal settings
    stty -raw echo

    # Convert to hex and store in variable
    local hex_sequence=$(echo -n "$sequence" | xxd -p)
    echo "$hex_sequence"
}

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
    local request="$1"

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

function zsh-copilot() {
    # Check and install prerequisites
    if ! _zsh_copilot_install_prerequisites; then
        echo "\033[0;31mFailed to install required dependencies. Please install them manually.\033[0m"
        return 1
    fi

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

    # Add config command handling
    if [[ "$input" == "config" ]]; then
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

    # Add fix command handling
    if [[ "$input" == "fix" ]]; then
        fix-error
        return $?
    fi

    # Add ask command handling
    if [[ "$input" =~ ^ask[[:space:]]+(.*) ]]; then
        ask-command "${match[1]}"
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
                    if ! $raw && delta_text=$(echo -E $token | jq -re '.choices[].delta.role'); then
                        assistant=$(echo -E $token | jq -je '.choices[].delta.role')
                        if ! $output; then
                            echo -n "\033[0;36m$assistant: \033[0m"
                        fi
                    fi
                    local delta_text=""
                    if delta_text=$(echo -E $token | jq -re '.choices[].delta.content'); then
                        begin=false
                        echo -E $token | jq -je '.choices[].delta.content'
                        generated_text=$generated_text$delta_text
                    fi
                    if (echo -E $token | jq -re '.choices[].finish_reason' > /dev/null); then
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
                if echo -E $response | jq -e '.error' > /dev/null; then
                    echo "zsh-copilot \033[0;31merror:\033[0m"
                    echo -E $response | jq -r '.error'
                    return 1
                fi
            fi
            assistant=$(echo -E $response | jq -r '.choices[].role')
            message=$(echo -E $response | jq -r '.choices[].message')
            generated_text=$(echo -E $message | jq -r '.content')
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
    local prompt=$(echo "I am in directory: ${current_dir}

Recent command history:
${history_data}

Based on this history and context, what would be the most likely next command I want to run? Provide just the command without explanation." | jq -Rs .)

    # Remove the outer quotes that jq adds
    prompt=${prompt:1:-1}

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


# Create a ZLE widget for ask-command
function ask-command-widget() {
    # Get the current buffer content
    local current_text="$BUFFER"

    # Clear line
    zle kill-whole-line

    # Only proceed if there's text in the buffer
    if [[ -n "$current_text" ]]; then
        # Run ask-command with current text and store result
        local result=$(ask-command-for-widget "$current_text")

        # Put the result in the command line buffer
        BUFFER="$result"
        CURSOR=${#BUFFER}
    fi

    # Redisplay the command line with the suggestion
    zle redisplay
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

# Alias
alias zc="zsh-copilot"
alias zcf="zsh-copilot fix"
alias zca="zsh-copilot ask"
alias zcp="predict"

# Convert hex back to characters for binding
function _hex_to_char() {
    echo -n "${(#)$(echo -n $1 | sed 's/\([0-9a-f]\{2\}\)/\\x\1/g')}"
}

# Bind the shortcuts
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_PREDICT)" predict-widget
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_ASK)" ask-command-widget
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_FIX)" fix-error-widget

# Define the trap function
function _zsh_copilot_error_reminder() {
    local exit_code=$?
    # Only show message for non-zero exit codes and ignore common status codes
    if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ] && [ $exit_code -ne 141 ]; then
        echo "\033[0;33mTip: Run 'zsh-copilot fix' or 'zcf' to get a suggested fix for this error.\033[0m"
    fi
    return $exit_code
}

# Add to precmd hook to catch errors from the last command
autoload -U add-zsh-hook
add-zsh-hook precmd _zsh_copilot_error_reminder

# https://github.com/Gamma-Software/zsh-copilot
# Copyright (c) 2024-2025 Gamma Software

SCRIPT_PATH=${(%):-%x}
ZSH_COPILOT_PREFIX=${SCRIPT_PATH:A:h}
ZSH_COPILOT_PLUGIN_DIR=${ZSH_COPILOT_PREFIX}/../

# Source all components
source "${ZSH_COPILOT_PREFIX}/utils.zsh"
source "${ZSH_COPILOT_PREFIX}/config.zsh"
source "${ZSH_COPILOT_PREFIX}/commands.zsh"
source "${ZSH_COPILOT_PREFIX}/widgets.zsh"
source "${ZSH_COPILOT_PREFIX}/aliases.zsh"

# Initialize the plugin
_setup-zsh-copilot
_zsh_validate_ping_api

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

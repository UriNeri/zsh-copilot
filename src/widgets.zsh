# ZLE widgets and their helpers
function predict-widget() {
    # Run prediction
    local result=$(predict)

    # Put the result in the command line buffer
    BUFFER="$result"
    CURSOR=${#BUFFER}

    # Redisplay the command line with the prediction
    zle redisplay
}

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

function fix-error-widget() {
    # Run fix-error and store result
    local result=$(fix-error-for-widget)

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

# Bind the shortcuts
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_PREDICT)" predict-widget
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_ASK)" ask-command-widget
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_FIX)" fix-error-widget
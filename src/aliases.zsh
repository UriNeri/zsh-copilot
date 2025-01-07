# Alias
alias zc="zsh-copilot"
alias zcf="zsh-copilot fix"
alias zca="zsh-copilot ask"
alias zcp="predict"

# Bind the shortcuts
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_PREDICT)" predict-widget
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_ASK)" ask-command-widget
bindkey "$(_hex_to_char $ZSH_COPILOT_SHORTCUT_FIX)" fix-error-widget
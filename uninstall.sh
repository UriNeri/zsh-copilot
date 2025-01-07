#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Plugin name
PLUGIN_NAME="zsh-copilot"

# Determine ZSH_CUSTOM path
if [ -z "$ZSH_CUSTOM" ]; then
    ZSH_CUSTOM="$HOME/.oh-my-zsh"
fi

PLUGIN_DIR="$ZSH_CUSTOM/plugins/$PLUGIN_NAME"

echo -e "${BLUE}Uninstalling $PLUGIN_NAME...${NC}"

# Remove plugin from .zshrc
if grep -q "plugins=.*$PLUGIN_NAME" "$HOME/.zshrc"; then
    echo -e "${BLUE}Removing plugin from .zshrc...${NC}"
    # Create backup of .zshrc
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
    # Remove plugin from plugins list
    sed -i.bak "s/$PLUGIN_NAME//" "$HOME/.zshrc"
    # Clean up empty spaces in plugins list
    sed -i.bak 's/plugins=(  *)/plugins=()/' "$HOME/.zshrc"
    sed -i.bak 's/  */ /g' "$HOME/.zshrc"
    echo -e "${GREEN}Plugin removed from .zshrc${NC}"
    echo -e "${BLUE}Backup created at ~/.zshrc.backup${NC}"
fi

# Remove plugin directory
if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${BLUE}Removing plugin directory...${NC}"
    rm -rf "$PLUGIN_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Plugin directory removed successfully${NC}"
    else
        echo -e "${RED}Failed to remove plugin directory${NC}"
        exit 1
    fi
fi

# Clean up any temporary files
rm -f "$HOME/.zshrc.bak"

echo -e "${GREEN}Uninstallation complete!${NC}"
echo -e "${BLUE}Please restart your terminal or run: source ~/.zshrc${NC}"

exit 0
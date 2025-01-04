#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Plugin name
PLUGIN_NAME="zsh-copilot"
REPO_URL="https://github.com/Gamma-Software/zsh-copilot"  # Update this with your actual repo URL

# Determine ZSH_CUSTOM path
if [ -z "$ZSH_CUSTOM" ]; then
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
fi

PLUGIN_DIR="$ZSH_CUSTOM/plugins/$PLUGIN_NAME"

echo -e "${BLUE}Installing/Updating $PLUGIN_NAME...${NC}"

# Create plugins directory if it doesn't exist
mkdir -p "$ZSH_CUSTOM/plugins"

# Check if plugin directory exists
if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${BLUE}Updating existing installation...${NC}"
    if git -C "$PLUGIN_DIR" pull origin main; then
        echo -e "${GREEN}Update successful!${NC}"
    else
        echo -e "${RED}Update failed. Please check your internet connection or repository access.${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}Performing fresh installation...${NC}"
    if git clone "$REPO_URL" "$PLUGIN_DIR"; then
        echo -e "${GREEN}Installation successful!${NC}"
    else
        echo -e "${RED}Installation failed. Please check your internet connection or repository access.${NC}"
        exit 1
    fi
fi

# Check if plugin is already in .zshrc
if ! grep -q "plugins=.*$PLUGIN_NAME" "$HOME/.zshrc"; then
    echo -e "${BLUE}Adding plugin to .zshrc...${NC}"
    # Check if plugins line exists
    if grep -q "^plugins=(" "$HOME/.zshrc"; then
        # Add plugin to existing plugins line
        sed -i.bak "s/plugins=(/plugins=($PLUGIN_NAME /" "$HOME/.zshrc"
    else
        # Create new plugins line
        echo "plugins=($PLUGIN_NAME)" >> "$HOME/.zshrc"
    fi
fi

# Create or update the plugin files
cat > "$PLUGIN_DIR/$PLUGIN_NAME.plugin.zsh" << 'EOL'
source ${0:A:h}/$PLUGIN_NAME.zsh
EOL

cat > "$PLUGIN_DIR/$PLUGIN_NAME.zsh" << 'EOL'
# Copy your $PLUGIN_NAME.zsh content here
source ${0:A:h}/$PLUGIN_NAME.zsh
EOL

echo -e "${GREEN}Installation/Update complete!${NC}"
echo -e "${BLUE}Please enter your OpenAI API key:${NC}"
read -r API_KEY
if [ -n "$API_KEY" ]; then
    # Update the API key in the plugin file
    sed -i.bak "s|ZSH_ASK_API_KEY=.*|ZSH_ASK_API_KEY=\"$API_KEY\"|" "$PLUGIN_DIR/$PLUGIN_NAME.zsh"
    echo -e "${GREEN}API key has been set successfully!${NC}"
else
    echo -e "${RED}No API key provided. Please manually add your OpenAI API key to $ZSH_CUSTOM/plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh${NC}"
fi
echo -e "${BLUE}Then restart your terminal or run: source ~/.zshrc${NC}"

# Set appropriate permissions
chmod 755 "$PLUGIN_DIR"/*.zsh

exit 0
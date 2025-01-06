# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if version is up to date from https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION
current_folder=${0:A:h}
new_version=$(curl -s https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION)
current_version=$(cat ${current_folder}/VERSION)
if [ "$current_version" != "$new_version" ]; then
    echo -e "${BLUE}A new version (${GREEN}$current_version${BLUE} -> ${GREEN}$new_version${BLUE}) of zsh-copilot is available. Would you like to update it? (Y/n)${NC}"
    read -r update || update="y"
    if [ "$update" = "y" ] || [ "$update" = "Y" ]; then
        echo -e "${BLUE}Updating zsh-copilot to the latest version...${NC}"
        zsh ${current_folder}/install.sh
    fi
fi

source ${0:A:h}/src/zsh-copilot.zsh
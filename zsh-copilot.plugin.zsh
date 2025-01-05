# Check if version is up to date from https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION
current_folder=${0:A:h}
if [ "$(cat ${current_folder}/VERSION)" != "$(curl -s https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION)" ]; then
    echo "A new version of zsh-copilot is available. Would you like to update it? (y/n)"
    read -r update
    if [ "$update" = "y" ]; then
        echo "Updating zsh-copilot to the latest version..."
        zsh ${current_folder}/install.sh
    fi
fi

source ${0:A:h}/zsh-copilot.zsh
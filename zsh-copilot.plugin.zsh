# Check if version is up to date from https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION
current_folder=${0:A:h}
new_version=$(curl -s https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION)
current_version=$(cat ${current_folder}/VERSION)
if [ "$current_version" != "$new_version" ]; then
    echo "A new version ($current_version -> $new_version) of zsh-copilot is available. Would you like to update it? (y/n)"
    read -r update
    if [ "$update" = "y" ]; then
        echo "Updating zsh-copilot to the latest version..."
        zsh ${current_folder}/install.sh
    fi
fi

source ${0:A:h}/zsh-copilot.zsh
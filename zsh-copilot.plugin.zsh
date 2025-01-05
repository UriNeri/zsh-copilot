# Check if version is up to date from https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION
current_folder=${0:A:h}
if [ "$(cat ${current_folder}/VERSION)" != "$(curl -s https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION)" ]; then
    echo "Updating zsh-copilot to the latest version..."
    zsh ${current_folder}/install.sh
fi

source ${0:A:h}/zsh-copilot.zsh
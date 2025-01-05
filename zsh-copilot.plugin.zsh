# Check if version is up to date from https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION
if [ "$(cat ${0:A:h}/VERSION)" != "$(curl -s https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/VERSION)" ]; then
    echo "Updating zsh-copilot to the latest version..."
    source ${0:A:h}/zsh-copilot.zsh
fi

source ${0:A:h}/zsh-copilot.zsh
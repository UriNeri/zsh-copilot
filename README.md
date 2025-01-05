# zsh-ask

A lightweight Zsh plugin serves as a ChatGPT API frontend, enabling you to interact with ChatGPT directly from the `Zsh` shell using only `cURL` and `jq`.

## Installation

Acquire your private api-key from [OpenAI](https://platform.openai.com/account/api-keys).

### Via installer

It's simple and easy to use. Just run the following command in your terminal:

```sh
zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/install.sh)"
```

### Manual (Git Clone)

1. Clone this repository into `$ZSH_CUSTOM/plugins` (by default `~/.oh-my-zsh/custom/plugins`)

```sh
git clone https://github.com/Gamma-Software/zsh-copilot ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-copilot
```

2. Add the plugin to the list of plugins for Oh My Zsh to load (inside `~/.zshrc`):

```sh
plugins=(
   # other plugins...
   zsh-copilot
)
```

3. Add the following to your `$ZSH_CUSTOM/plugins/zsh-copilot/.env` file:
```sh
ZSH_COPILOT_API_KEY="<Your API key here>"
```

4. Restart your terminal or run:
```sh
source ~/.zshrc
```

## Uninstallation

Run the command:
```sh
zsh-copilot uninstall
```

## Preliminaries

Make sure you have [`cURL`](https://curl.se/) and [`jq`](https://stedolan.github.io/jq/) installed.

If you would like to have markdown rendering with option `-m`, [`glow`](https://github.com/charmbracelet/glow) is required (Recommend).

## Features

### Direct ChatGPT Interaction

## Usage

Fill your OpenAI api key as `ZSH_ASK_API_KEY` (see [INSTALL.md](INSTALL.md) for detail information), then just run

```
zsh-copilot who are you
```

Use `-c` for dialogue format communication.

```
zsh-copilot -c chat with me
```

Use `-m` for markdown rendering (`glow` required)

```
zsh-copilot -m how to code quick sort in python
```

Use `-s` for streaming display (doesn't work with `-m` yet)

```
zsh-copilot -s write a poem for me
```

Use `-i` to inherits history from last chat (which is recorded in ZSH_COPILOT_HISTORY).

```
zsh-copilot -i tell me more about it
```

Use `-h` for more information.

```
zsh-copilot -h
```

### Command Prediction and Generation
This plugin provides two powerful command-line features:

1. **Command Prediction** (Option+p or Ctrl+x p)
   - Analyzes your recent command history
   - Suggests the next likely command based on your patterns
   - Press Option+p (Mac) or Ctrl+x p to see the prediction
   - The predicted command appears in your command line ready to execute

2. **Command Generation** (Option+a or Ctrl+x a)
   - Type what you want to do in plain English
   - Press Option+a (Mac) or Ctrl+x a to generate the command
   - Example: Type "find all PDF files modified today" and press Option+a
   - The generated command appears in your command line ready to execute

3. **Error Fixing** (Option+f or Ctrl+x f)
   - Automatically captures the last failed command and its error
   - Generates a corrected version of the command
   - Press Option+f (Mac) or Ctrl+x f to see the fixed command
   - The corrected command appears in your command line ready to execute

Both features:
- Place commands directly in your command line
- Allow you to edit before executing
- Can be cancelled with Ctrl+C
- Support full command-line editing

Have fun!

## License

This project is licensed under [MIT license](http://opensource.org/licenses/MIT). For the full text of the license, see the [LICENSE](LICENSE) file.
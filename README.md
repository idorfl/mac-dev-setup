# mac-dev-setup

Bootstrap a macOS development environment on Apple Silicon.

## Prerequisites

- Apple Silicon Mac (arm64)
- Internet connection

## Usage

Or clone and run locally:

```zsh
git clone https://github.com/idorfl/mac-dev-setup.git
cd mac-dev-setup
./mac_setup.sh
```

### Options

The script supports modular installation via group flags. Run `./mac_setup.sh --help` to see all options.

| Flag | Description |
|------|-------------|
| `--tools` | CLI tools (vim, wget, git, node, etc.) |
| `--languages` | Programming languages (Rust, Python) |
| `--vscode` | VS Code and extensions |
| `--ai-tools` | AI tools (Ollama, Codex, Claude Code, etc.) |
| `--all` | Install everything |
| `--help` | Show help and exit |

Without any flags, only `~/.vimrc`, Xcode CLI Tools, and Homebrew are installed.

## What gets installed

### CLI tools

vim, wget, ripgrep, git, gh (GitHub CLI), jq, lazygit, fzf, node, uv (Python package manager)

### Programming languages

- Rust (via rustup)
- Python 3.13 (via uv)

### Applications

Visual Studio Code with extensions:
- C/C++ Extension Pack
- CMake Tools
- Python
- Rust Analyzer

### AI tools

- Codex CLI
- Claude Code CLI
- OpenCode
- Ollama
- Omlx
- rtk
- apfel
- pi (pi-coding-agent)

## Post-install

Set up Git and GitHub:

```zsh
git config --global user.name "Your Name"
git config --global user.email YOUR_EMAIL
gh auth login
```

The script configures the following in `~/.zprofile`:
- Homebrew shellenv (`eval $(/opt/homebrew/bin/brew shellenv)`)
- Python local bin PATH (`export PATH="$HOME/.local/bin:$PATH"`)

Run `source ~/.zprofile` or restart your terminal to apply.

## Notes

- **Idempotent:** safe to re-run. Each item is installed only if missing.
- **Apple Silicon only:** exits early on non-arm64 architectures.
- **Xcode CLI Tools:** the script triggers a GUI prompt; rerun after installing.
- **Customizable:** edit `mac_setup.sh` to change packages, VS Code extensions, or the `.vimrc` config before running.

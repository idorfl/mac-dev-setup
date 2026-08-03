# mac-dev-setup

Bootstrap a macOS development environment on Apple Silicon.

## Prerequisites

- Apple Silicon Mac (arm64)
- Internet connection

## Usage

```zsh
curl -fsSL https://raw.githubusercontent.com/lukzs12/mac-dev-setup/main/install.sh | zsh
```

Or clone and run locally:

```zsh
git clone https://github.com/lukzs12/mac-dev-setup.git
cd mac-dev-setup
./mac_setup.sh
```

## What gets installed

### CLI tools

vim, wget, ripgrep, git, gh (GitHub CLI), jq, lazygit, fzf, node, uv (Python package manager), rtk, apfel

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
- oMLX

## Post-install

Set up Git and GitHub:

```zsh
git config --global user.name "Mona Lisa"
git config --global user.email "you@example.com"
gh auth login
```

Ensure `~/.local/bin` is on your PATH (the script adds it to `~/.zprofile`).

## Notes

- **Idempotent:** safe to re-run. Each item is installed only if missing.
- **Apple Silicon only:** exits early on non-arm64 architectures.
- **Xcode CLI Tools:** the script triggers a GUI prompt; rerun after installing.
- **Customizable:** edit `mac_setup.sh` to change packages, VS Code extensions, or the `.vimrc` config before running.

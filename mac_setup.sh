#!/bin/zsh

# Strict mode
set -euo pipefail

readonly TXT_INV="\033[7m"
readonly TXT_RESET="\033[0m"
readonly CHAR_DONE="\u2714"
readonly CHAR_FAIL="\u2716"
readonly LIGHT_BLUE="\033[38;5;33m"
readonly LIGHT_RED="\033[38;5;196m"

readonly ICON_DONE="$LIGHT_BLUE$CHAR_DONE$TXT_RESET"
readonly ICON_FAIL="$LIGHT_RED$CHAR_FAIL$TXT_RESET"

CHECK_ONLY=true

# -------------------------------------------------

print_installing() {
  echo "Installing $1..."
}

# -------------------------------------------------

print_installed() {
  printf '%b\n' "$ICON_DONE $1 installed"
}

# -------------------------------------------------

print_not_installed() {
  printf '%b\n' "$ICON_FAIL $1 not installed"
}

# -------------------------------------------------

print_installation_failed() {
  printf '%b\n' "$ICON_FAIL $1 installation failed"
}

# -------------------------------------------------

print_verification_failed() {
  printf '%b\n' "$ICON_FAIL $1 installation completed, but verification failed"
}

# -------------------------------------------------

print_installing_group() {
  echo
  echo ">>> Group $1 <<<"
}

# -------------------------------------------------

check_command() {
  command -v "$1" &>/dev/null;
}

install_command() {
  local command_name=$1
  local display_name=$2
  local test_cmd_fn=$3
  shift 3

  if ! "$test_cmd_fn" "$command_name"; then
    if [[ "$CHECK_ONLY" == true ]]; then
      print_not_installed "$display_name"
      return
    fi
    print_installing "$display_name"
    if ! "$@"; then
      print_installation_failed "$display_name"
      exit 1
    fi
    if "$test_cmd_fn" "$command_name"; then
      print_installed "$display_name"
    else
      print_verification_failed "$display_name"
      exit 1
    fi
  else
    print_installed "$display_name"
  fi
}

# -------------------------------------------------

install_group() {
  local last_check_only="$CHECK_ONLY"
  local group_name="$1"
  if [[ "$2" == true ]]; then
    CHECK_ONLY=false
  else
    CHECK_ONLY=true
  fi
  shift 2
  print_installing_group "$group_name"
  "$@"
  echo
  CHECK_ONLY="$last_check_only"
}

# -------------------------------------------------

write_vimrc() {
  cat >"$1"<<END_FILE
set nocompatible

" UI
set number
set ruler
set showcmd
set scrolloff=5

" History
set history=512

" Search
set hlsearch
set incsearch
set ignorecase
set smartcase

" Editing
set backspace=indent,eol,start
set hidden
set undofile
set list
set listchars=tab:▸\ ,trail:·

" Indentation
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set shiftround

" Windows
set splitbelow
set splitright

" Completion
set wildmenu
set wildmode=longest:full,full

" Clipboard
" set clipboard=unnamedplus

" Display
set nowrap

syntax on
filetype plugin indent on

END_FILE
}

# -------------------------------------------------

check_file() {
  [[ -f "$1" ]]
}

install_vimrc() {
  local vimrc="$1"
  install_command "$vimrc" "~/.vimrc" check_file write_vimrc "$vimrc"
}

# -------------------------------------------------

check_brew() {
  [[ -x "/opt/homebrew/bin/$1" ]]
}

brew_install() {
  local command_name=$1
  local package_name="${2:-$1}"
  install_command "$command_name" "$package_name"\
    check_brew brew install --no_ask "$package_name"
}

# -------------------------------------------------

check_extension() {
  code --list-extensions | grep -qx "$1"
}

install_vscode_extension() {
  local extension_name=$1
  local display_name="VS Code Extension: $extension_name"
  install_command "$extension_name" "$display_name"\
    check_extension code --install-extension "$extension_name"
}

# -------------------------------------------------

check_python() {
  local python_version=$1
  local escaped_version="${python_version//./\\.}"
  uv python list --only-installed | grep -q "^cpython-${escaped_version}\."
}

install_python() {
  local python_version=$1
  local display_name="Python $python_version"
  install_command "$python_version" "$display_name" check_python\
    uv python install "$python_version" --default --preview-features python-install-default
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    uv python update-shell
    export PATH="$HOME/.local/bin:$PATH"
  fi
  if ! grep -q '.local/bin' ~/.zprofile 2> /dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile
  fi
}

# -------------------------------------------------

usage() {
  cat <<'EOF'
Usage: mac_setup.sh [OPTIONS]

Bootstrap a macOS development environment on Apple Silicon.
The packages are installed from Homebrew where possible.
Python is installed via uv.

Options:
  --help, -h      Show this help message and exit
  --tools         Install tools like vim, wget, git, etc.
  --languages     Install Python and Rust
  --ai-tools      Install AI tools (omlx, ollama, codex, claude-code, opencode)
  --vscode        Install VS Code and extensions

Groups are additive. Without the options the following is installed by default:
  ~/.vimrc
  Xcode Command Line Tools
  Homebrew

Modify the script in accordance with your needs (the group_* functions).
EOF
}

# -------------------------------------------------

echo
echo "============================================================="
printf '%b\n' "$TXT_INV MacOS Development Environment Bootstrap (For Apple Silicon) $TXT_RESET"
echo "============================================================="
echo

# -------------------------------------------------
# Check Platform
# -------------------------------------------------

if [[ $(uname -m) != "arm64" ]]; then
  echo "This script supports only Apple Silicon"
  echo
  exit 1
fi

# -------------------------------------------------
# Parse Parameters
# -------------------------------------------------

OPT_TOOLS=false
OPT_LANGUAGES=false
OPT_VSCODE=false
OPT_AI_TOOLS=false
OPT_ALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tools)     OPT_TOOLS=true;     shift ;;
    --languages) OPT_LANGUAGES=true; shift ;;
    --vscode)    OPT_VSCODE=true;    shift ;;
    --ai-tools)  OPT_AI_TOOLS=true;  shift ;;
    --all)       OPT_ALL=true;       shift ;;
    --help|-h)   usage; exit 0 ;;
    *) echo "Unknown parameter: $1\nUse --help for list of supported parameters"; exit 1 ;;
  esac
done

if [[ "$OPT_ALL" == true ]]; then
  OPT_TOOLS=true
  OPT_VSCODE=true
  OPT_LANGUAGES=true
  OPT_AI_TOOLS=true
fi

# -------------------------------------------------
# ~/.vimrc
# -------------------------------------------------

install_vimrc "$HOME/.vimrc"

# -------------------------------------------------
# Xcode Command Line Tools
# -------------------------------------------------

xcode_cmd_tools="Xcode Command Line Tools"

if ! xcode-select -p &>/dev/null; then
    print_installing "$xcode_cmd_tools"
    echo "An Install Command Line Developer Tools application will launch..."
    xcode-select --install
    echo "Please rerun this script after installation completes."
    exit 1
else
    print_installed "$xcode_cmd_tools"
fi

# -------------------------------------------------
# Homebrew
# -------------------------------------------------

install_command "brew" "Homebrew" check_brew\
  bash -c 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'

if ! grep -q 'homebrew' ~/.zprofile 2> /dev/null; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
fi
if ! check_command brew; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# -------------------------------------------------
# Tools
# -------------------------------------------------

group_tools() {
  brew_install "vim"
  brew_install "wget"
  brew_install "rg" "ripgrep"
  brew_install "git"
  brew_install "gh"
  brew_install "jq"
  brew_install "lazygit"
  brew_install "fzf"
  brew_install "node"
  brew_install "uv"
}

install_group "Tools" "$OPT_TOOLS" group_tools

# -------------------------------------------------
# Programming Languages
# -------------------------------------------------

group_languages() {
  install_command "rustc" "Rust" check_command\
    bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  install_python "3.13"
}

install_group "Languages" "$OPT_LANGUAGES" group_languages

# -------------------------------------------------
# VS Code
# -------------------------------------------------

group_vscode() {
  install_command "code" "Visual Studio Code" check_command\
    brew install --cask visual-studio-code

  install_vscode_extension "ms-vscode.cpptools-extension-pack"
  install_vscode_extension "ms-vscode.cmake-tools"
  install_vscode_extension "ms-python.python"
  install_vscode_extension "rust-lang.rust-analyzer"
}

install_group "VS Code" "$OPT_VSCODE" group_vscode

# -------------------------------------------------
# AI Tools
# -------------------------------------------------

group_ai_tools() {
  brew_install "rtk"
  brew_install "apfel"

  if ! check_brew "omlx"; then
    brew tap jundot/omlx https://github.com/jundot/omlx
    brew trust jundot/omlx
  fi
  brew_install "omlx"

  brew_install "ollama"

  install_command "codex" "Codex CLI" check_command\
    brew install --cask codex

  install_command "claude" "Claude Code CLI" check_command\
    brew install --cask claude-code

  brew_install "opencode"

  brew_install "pi" "pi-coding-agent"
}

install_group "AI Tools" "$OPT_AI_TOOLS" group_ai_tools

# -------------------------------------------------

cat <<'EOF'

==================================
 Bootstrap completed successfully
==================================

Next steps:
  - Set a Git username and e-mail
      git config --global user.name "Mona Lisa"
      git config --global user.email YOUR_EMAIL
  - Login to GitHub: gh auth login
  - Setup rtk
      rtk init -g            # Claude Code / Copilot (default)
      rtk init -g --codex    # Codex (OpenAI)
      rtk init -g --agent pi # Pi
EOF

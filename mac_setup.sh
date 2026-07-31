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

# -------------------------------------------------

print_installing() {
  printf '%b\n' "Installing $1..."
}

# -------------------------------------------------

print_installed() {
  printf '%b\n' "$ICON_DONE $1 installed"
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

check_command() {
  command -v "$1" &>/dev/null;
}

install_command() {
  local command_name=$1
  local display_name=$2
  local test_cmd_fn=$3
  shift 3

  if ! "$test_cmd_fn" "$command_name"; then
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

brew_install() {
  local command_name=$1
  local package_name="${2:-$1}"
  install_command "/opt/homebrew/bin/$command_name" "$package_name"\
    check_command brew install --no_ask "$package_name"
}

# -------------------------------------------------

check_extension() {
  code --list-extensions | grep -q "$1"
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
  # This needs to be tested first perhaps
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    uv python update-shell
  fi
  if ! grep -q '.local/bin' ~/.zprofile 2> /dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile
  fi
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
# ~/.vimrc
# -------------------------------------------------

install_vimrc "$HOME/.vimrc"

# -------------------------------------------------
# Xcode Command Line Tools
# -------------------------------------------------

xcode_cmd_tools="Xcode Command Line Tool"

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

install_command "brew" "Homebrew" check_command\
  bash -c 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'

if ! grep -q 'homebrew' ~/.zprofile 2> /dev/null; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
fi
if [[ $HOMEBREW_PREFIX == :: ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# -------------------------------------------------
# Tools
# -------------------------------------------------

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
brew_install "rtk"

# -------------------------------------------------
# Programming Languages
# -------------------------------------------------

install_command "rustc" "Rust" check_command\
  bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
install_python "3.13"

# -------------------------------------------------
# Applications
# -------------------------------------------------

install_command "code" "Visual Studio Code" check_command\
  brew install --cask visual-studio-code

install_vscode_extension "ms-vscode.cpptools-extension-pack"
install_vscode_extension "ms-vscode.cmake-tools"
install_vscode_extension "ms-python.python"
install_vscode_extension "rust-lang.rust-analyzer"

echo
echo "=================================="
echo " Bootstrap completed successfully "
echo "=================================="
echo
echo "Next steps:"
echo "- Set a Git username and e-mail"
echo "  git config --global user.name \"Mona Lisa\""
echo "- git config --global user.email \"YOUR_EMAIL\""
echo "- Login to GitHub: gh auth login"


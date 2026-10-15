#!/usr/bin/env bash
# Links the dotfiles into $HOME using GNU stow.
# Usage: ./install.sh            -> all packages
#        ./install.sh nvim       -> selected packages
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU stow not found: sudo apt install stow" >&2
  exit 1
fi

packages=("$@")
if [ ${#packages[@]} -eq 0 ]; then
  packages=(zsh nvim)
fi

for pkg in "${packages[@]}"; do
  echo "==> stow $pkg"
  # nvim is linked as a whole directory (~/.config/nvim -> repo)
  stow -v -t "$HOME" "$pkg"
done

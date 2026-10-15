#!/usr/bin/env bash
# Linkuje dotfiles do $HOME przy pomocy GNU stow.
# Użycie: ./install.sh            -> wszystkie pakiety
#         ./install.sh nvim       -> wybrane pakiety
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if ! command -v stow >/dev/null 2>&1; then
  echo "Brak GNU stow: sudo apt install stow" >&2
  exit 1
fi

packages=("$@")
if [ ${#packages[@]} -eq 0 ]; then
  packages=(zsh nvim)
fi

for pkg in "${packages[@]}"; do
  echo "==> stow $pkg"
  # --no-folding nie jest używane: nvim linkuje się jako cały katalog ~/.config/nvim
  stow -v -t "$HOME" "$pkg"
done

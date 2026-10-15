# dotfiles

Konfiguracja zsh i Neovima (WSL2 / Ubuntu), linkowana do `$HOME` przez [GNU stow](https://www.gnu.org/software/stow/).

```
zsh/                    -> ~/.zshrc, ~/.aliases*.zsh, ~/.plugins.zsh, ~/.p10k.zsh, ~/.fzf.zsh
nvim/.config/nvim/      -> ~/.config/nvim   (opis configu: nvim/.config/nvim/README.md)
```

## Instalacja na nowej maszynie

```sh
sudo apt install stow git zsh fzf fd-find ripgrep build-essential unzip
git clone git@gitlab.czk.comarch:ossowskib/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh            # albo: ./install.sh nvim / ./install.sh zsh
chsh -s "$(which zsh)"
```

Jeśli w `$HOME` istnieją już zwykłe pliki (np. `~/.zshrc`, `~/.config/nvim`), stow odmówi
nadpisania - przenieś je najpierw na bok.

* **zsh:** przy pierwszym uruchomieniu `.plugins.zsh` sklonuje powerlevel10k i pluginy do `~/.zsh`.
* **nvim:** przy pierwszym uruchomieniu lazy.nvim zainstaluje wtyczki w wersjach z `lazy-lock.json`,
  a Mason serwery LSP. Potem `:checkhealth`.

## Codzienna praca

Pliki w `$HOME` to symlinki do tego repo, więc edytujesz normalnie, a potem:

```sh
cd ~/dotfiles && git add -A && git commit -m "..." && git push
```

Po `:Lazy update` w nvimie commituj też zmieniony `nvim/.config/nvim/lazy-lock.json`.

## Sekrety

Nie commituj tokenów ani haseł. Trzymaj je w plikach pasujących do `zsh/.*private*.zsh`
(np. `zsh/.aliases_private.zsh` - ładowany automatycznie przez pętlę w `.zshrc`, ignorowany przez git).
Repo ma włączone GitLab Secret Detection w CI.

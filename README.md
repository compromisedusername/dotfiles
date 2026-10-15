# dotfiles

zsh and Neovim configuration (WSL2 / Debian), linked into `$HOME` with [GNU stow](https://www.gnu.org/software/stow/).

```
zsh/                    -> ~/.zshrc, ~/.aliases*.zsh, ~/.plugins.zsh, ~/.p10k.zsh, ~/.fzf.zsh,
                           ~/.local/bin/kcfg-info
nvim/.config/nvim/      -> ~/.config/nvim   (see nvim/.config/nvim/README.md)
```

## Install on a new machine

```sh
sudo apt install stow git zsh fzf fd-find ripgrep build-essential unzip
git clone git@gitlab.czk.comarch:ossowskib/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh            # or: ./install.sh nvim / ./install.sh zsh
chsh -s "$(which zsh)"
```

If regular files already exist in `$HOME` (e.g. `~/.zshrc`, `~/.config/nvim`), stow refuses
to overwrite them - move them aside first.

* **zsh:** on first start `.plugins.zsh` clones powerlevel10k and the plugins into `~/.zsh`.
* **nvim:** on first start lazy.nvim installs the plugins at the versions pinned in
  `lazy-lock.json` and Mason installs the LSP servers. Then run `:checkhealth`.
* **CLI tools** (built from source, modules verified against sum.golang.org):
  ```sh
  go install github.com/jesseduffield/lazygit@latest
  go install github.com/derailed/k9s@latest
  go install github.com/stern/stern@latest
  go install github.com/yannh/kubeconform/cmd/kubeconform@latest
  go install golang.stackrox.io/kube-linter/cmd/kube-linter@latest
  ```

## Kubeconfigs

One file per cluster in `~/.kube/configs/<name>.yaml` (mode 600, never in this repo);
`~/.kube/config` is a symlink to the default one.

```sh
kcfg                     # pick a kubeconfig for this shell (fzf with server/identity preview)
kcfg -l                  # list: name, context, server, identity (SA / cert / exec)
kcfg -d <name>           # default for new shells
kcfg-add <file> [name]   # review + import a new kubeconfig
```

In Neovim: `<leader>kf`. Details in `nvim/.config/nvim/PORADNIK.md` (Polish).

## Day-to-day

Files in `$HOME` are symlinks into this repo, so edit them as usual, then:

```sh
cd ~/dotfiles && git add -A && git commit -m "..." && git push
```

After `:Lazy update` in nvim, commit the updated `nvim/.config/nvim/lazy-lock.json` too.

## Secrets

Never commit tokens or passwords. Keep them in files matching `zsh/.*private*.zsh`
(e.g. `zsh/.aliases_private.zsh` - sourced automatically by the loop in `.zshrc`, ignored by git).
GitLab Secret Detection runs in CI.

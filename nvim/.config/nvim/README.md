# Neovim config (DevOps)

**User guide (in Polish): [PORADNIK.md](PORADNIK.md)** (inside nvim: `<leader>H`).

Requires Neovim 0.12+, git, gcc/make, ripgrep, fd, node/npm, python3.

## Layout

```
init.lua                 # entry point
lua/config/options.lua   # options (clipboard, indentation, security)
lua/config/keymaps.lua   # global keymaps
lua/config/autocmds.lua  # autocommands + filetype detection (helm, ansible, compose, tf)
lua/config/lazy.lua      # plugin manager
lua/plugins/*.lua        # one file = one plugin group (loaded automatically)
lua/kube/init.lua        # local Kubernetes module (kubectl/helm), keymaps under <leader>k
PORADNIK.md              # user guide (<leader>H)
lazy-lock.json           # pinned commits of all plugins
```

## Adding things

* **Plugin:** create `lua/plugins/<name>.lua` returning a lazy.nvim spec, e.g.
  ```lua
  return { "author/plugin.nvim", event = "VeryLazy", opts = {} }
  ```
  Ready-made optional extras: `lua/plugins/extras.lua` (set `enabled = true`).
* **Language / LSP:** add the server to `servers` in `lua/plugins/lsp.lua`
  (names: `:help lspconfig-all`), the parser to `parsers` in `treesitter.lua`
  and the formatter to `formatters_by_ft` in `formatting.lua`.

## Security

* Only widely used plugins from their official repositories (folke, neovim, mason-org, ...).
* `lazy-lock.json` pins commits; no automatic updates
  (run `:Lazy update` deliberately, then review changes with `:Lazy log`).
* No luarocks, no prebuilt binaries for blink.cmp (Lua matcher),
  treesitter installs only the parsers from an explicit list.
* kubectl.nvim deliberately skipped (native binary with cluster access) - a local module
  `lua/kube` is used instead (kubectl/helm only, confirmations showing the context,
  typing the context name required on production).
* k9s, stern, kubeconform, kube-linter, lazygit are built from source with `go install`
  (modules verified against sum.golang.org), e.g. `go install github.com/derailed/k9s@latest`.
* `modeline` and `exrc` disabled (untrusted files/directories can't execute code).
* Mason downloads LSP servers from their official sources (GitHub releases / npm / PyPI).

## Key bindings (leader = space; which-key / `<leader>?` shows the rest)

| Keys | Action |
|---|---|
| `<leader>e` | side file explorer (neo-tree) |
| `Ctrl+h` / `Ctrl+l` (`j`/`k`) | move between windows (tree ↔ editor ↔ Claude) |
| `y` | yank to the system clipboard (`c`, `x` don't overwrite it) |
| `<leader><space>`, `<leader>ff`, `<leader>fg` | find files / grep |
| `gd`, `gr`, `K`, `<leader>ca`, `<leader>cr` | LSP: definition, references, hover, actions, rename |
| `<leader>cf`, `<leader>uf` | format / toggle format on save |
| `<leader>xx` | problem list (Trouble) |
| `]d` `[d`, `]h` `[h` | next/previous diagnostic, git hunk |
| `<leader>gg` | lazygit |
| `Ctrl+\` | terminal |
| `<leader>ac` | Claude Code (right panel) |
| `<leader>as` | send selection to Claude (in neo-tree: add file) |
| `<leader>ab` | add current file to Claude's context |
| `<leader>aa` / `<leader>ad` | accept / reject a diff proposed by Claude |
| `s` | flash - jump anywhere on screen |
| `gsa` / `gsd` / `gsr` | add / delete / replace surroundings |
| `<leader>qs` | restore session for the current directory |
| `<leader>k...` | Kubernetes: `kd` diff, `ka` apply, `kg` resources, `kl` logs, `kc`/`kn` context/ns, `k9` k9s |
| `<leader>H` | full user guide (Polish) |

# Config Neovim (DevOps)

Wymaga Neovim 0.11.3+ (zalecane 0.12.x), git, gcc/make, ripgrep, fd, node/npm, python3.

## Struktura

```
init.lua                 # punkt wejścia
lua/config/options.lua   # opcje (schowek, wcięcia, bezpieczeństwo)
lua/config/keymaps.lua   # globalne skróty
lua/config/autocmds.lua  # autokomendy + wykrywanie typów plików (helm, ansible, compose, tf)
lua/config/lazy.lua      # menedżer wtyczek
lua/plugins/*.lua        # jeden plik = jedna grupa wtyczek (ładowane automatycznie)
lazy-lock.json           # przypięte commity wszystkich wtyczek
```

## Jak dodać coś nowego

* **Wtyczka:** utwórz `lua/plugins/nazwa.lua` zwracający spec lazy.nvim, np.
  ```lua
  return { "autor/wtyczka.nvim", event = "VeryLazy", opts = {} }
  ```
  Gotowe przykłady do włączenia: `lua/plugins/extras.lua` (`enabled = true`).
* **Język / LSP:** dopisz serwer do tabeli `servers` w `lua/plugins/lsp.lua`
  (nazwy: `:help lspconfig-all`), parser do `ensure_installed` w `treesitter.lua`,
  formater do `formatters_by_ft` w `formatting.lua`.

## Bezpieczeństwo

* Tylko szeroko używane wtyczki z oficjalnych repozytoriów (folke, neovim, mason-org, ...).
* `lazy-lock.json` przypina commity; brak automatycznych aktualizacji
  (`:Lazy update` świadomie, potem przejrzyj zmiany w `:Lazy log`).
* Brak luarocks, brak pobierania binarek przez blink.cmp (matcher w Lua),
  treesitter bez `auto_install`.
* Wyłączone `modeline` i `exrc` (obce pliki/katalogi nie wykonują kodu).
* Mason pobiera serwery LSP z ich oficjalnych źródeł (GitHub releases / npm / PyPI).

## Najważniejsze skróty (leader = spacja, `<leader>?` / which-key pokazuje resztę)

| Skrót | Akcja |
|---|---|
| `<leader>e` | przeglądarka plików z boku (neo-tree) |
| `Ctrl+h` / `Ctrl+l` (`j`/`k`) | przejście między oknami (drzewo ↔ edytor ↔ Claude) |
| `y` | kopiuje do schowka systemowego (`c`, `x` nie nadpisują schowka) |
| `<leader><space>`, `<leader>ff`, `<leader>fg` | szukaj plików / grep |
| `gd`, `gr`, `K`, `<leader>ca`, `<leader>cr` | LSP: definicja, referencje, opis, akcje, zmiana nazwy |
| `<leader>cf`, `<leader>uf` | formatuj / przełącz format przy zapisie |
| `<leader>xx` | lista problemów (Trouble) |
| `]d` `[d`, `]h` `[h` | następny/poprzedni błąd, hunk gita |
| `<leader>gg` | lazygit (wymaga zainstalowanego lazygit) |
| `Ctrl+\` | terminal |
| `<leader>ac` | Claude Code (panel z prawej) |
| `<leader>as` | wyślij zaznaczenie do Claude (w neo-tree: dodaj plik) |
| `<leader>ab` | dodaj bieżący plik do kontekstu Claude |
| `<leader>aa` / `<leader>ad` | akceptuj / odrzuć diff zaproponowany przez Claude |
| `s` | flash - skok do dowolnego miejsca na ekranie |
| `gsa` / `gsd` / `gsr` | dodaj / usuń / zamień otoczenie (nawiasy, cudzysłowy) |
| `<leader>qs` | przywróć sesję dla katalogu |

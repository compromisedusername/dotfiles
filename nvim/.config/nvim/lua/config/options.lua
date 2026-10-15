-- Opcje edytora ---------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Wyłącz netrw - przeglądarką plików jest neo-tree.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt

-- Schowek: każde y/d/p działa na schowku systemowym (Ctrl+V w terminalu).
-- Na WSL2 z WSLg Neovim sam wybiera wl-copy, który synchronizuje się z Windows.
opt.clipboard = "unnamedplus"

opt.number = true
opt.relativenumber = false
opt.cursorline = true
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.termguicolors = true
opt.showmode = false -- tryb pokazuje lualine
opt.laststatus = 3 -- jedna globalna linia statusu
opt.showtabline = 2
opt.winborder = "rounded" -- ramki okien pływających (nvim 0.11+)
opt.fillchars = { eob = " " }
opt.mouse = "a"
opt.mousescroll = "ver:3,hor:0"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.splitright = true
opt.splitbelow = true
opt.virtualedit = "block"

-- Wcięcia (domyślnie 2 spacje; Python dostaje 4 w autocmds.lua)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true
opt.smartindent = true

-- Wyszukiwanie
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- podgląd :s/// na żywo
opt.grepprg = "rg --vimgrep --smart-case"

-- Pliki / historia
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.writebackup = false
opt.confirm = true -- pytaj zamiast odmawiać przy :q z niezapisanym buforem
opt.updatetime = 250
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 10
opt.diffopt:append({ "algorithm:histogram", "linematch:60" })
opt.shortmess:append({ I = true, c = true })

-- Zwijanie kodu przez treesitter (wszystko rozwinięte na start)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Bezpieczeństwo -------------------------------------------------------------
-- Modeline'y w obcych plikach były historycznie wektorem ataku - wyłączone.
opt.modeline = false
-- Nie wykonuj lokalnych .nvim.lua/.exrc z katalogów projektów.
opt.exrc = false

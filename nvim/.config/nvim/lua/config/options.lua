-- Editor options -------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Disable netrw - neo-tree is the file explorer.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt

-- Clipboard: every y/d/p uses the system clipboard (Ctrl+V in the terminal).
-- On WSL2 with WSLg Neovim picks wl-copy, which syncs with Windows.
opt.clipboard = "unnamedplus"

opt.number = true
opt.relativenumber = false
opt.cursorline = true
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.termguicolors = true
opt.showmode = false -- mode is shown by lualine
opt.laststatus = 3 -- single global statusline
opt.showtabline = 2
opt.winborder = "rounded" -- floating window borders (nvim 0.11+)
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

-- Indentation (2 spaces by default; Python gets 4 in autocmds.lua)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- live preview of :s///
opt.grepprg = "rg --vimgrep --smart-case"

-- Files / history
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.writebackup = false
opt.confirm = true -- ask instead of failing on :q with unsaved changes
opt.updatetime = 250
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 10
opt.diffopt:append({ "algorithm:histogram", "linematch:60" })
opt.shortmess:append({ I = true, c = true })

-- Treesitter folding (everything unfolded on open)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Security ---------------------------------------------------------------------------
-- Modelines in untrusted files have historically been an attack vector - disabled.
opt.modeline = false
-- Never execute project-local .nvim.lua/.exrc files.
opt.exrc = false

-- WSL: open URLs (gx, "open in GitLab") in the Windows browser
if vim.fn.has("wsl") == 1 and vim.fn.executable("/mnt/c/Windows/explorer.exe") == 1 then
  local default_open = vim.ui.open
  vim.ui.open = function(path, opt)
    if path:match("^%a[%w+.-]*://") then
      return vim.system({ "/mnt/c/Windows/explorer.exe", path }), nil
    end
    return default_open(path, opt)
  end
end

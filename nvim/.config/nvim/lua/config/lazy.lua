-- Menedżer wtyczek lazy.nvim ---------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Nie udało się sklonować lazy.nvim:\n" .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Każdy plik w lua/plugins/*.lua jest ładowany automatycznie.
  -- Nowa wtyczka = nowy plik zwracający spec (patrz README.md).
  spec = { { import = "plugins" } },
  defaults = { lazy = false },
  install = { colorscheme = { "tokyonight", "habamax" } },
  -- Bez automatycznego sprawdzania/aktualizacji: aktualizujesz świadomie
  -- przez :Lazy update, a lazy-lock.json przypina dokładne commity.
  checker = { enabled = false },
  change_detection = { notify = false },
  -- Bez luarocks/hererocks - żadna wtyczka tu tego nie potrzebuje.
  rocks = { enabled = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" },
    },
  },
})

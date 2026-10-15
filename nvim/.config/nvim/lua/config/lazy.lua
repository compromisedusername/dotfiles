-- lazy.nvim plugin manager ---------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n" .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Every file in lua/plugins/*.lua is loaded automatically.
  -- New plugin = new file returning a spec (see README.md).
  spec = { { import = "plugins" } },
  defaults = { lazy = false },
  install = { colorscheme = { "tokyonight", "habamax" } },
  -- No automatic update checks: update deliberately with :Lazy update;
  -- lazy-lock.json pins exact commits.
  checker = { enabled = false },
  change_detection = { notify = false },
  -- No luarocks/hererocks - no plugin here needs them.
  rocks = { enabled = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "zipPlugin", "netrwPlugin" },
    },
  },
})

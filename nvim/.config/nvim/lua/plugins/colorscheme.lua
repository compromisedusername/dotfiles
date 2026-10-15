-- Motyw. Żeby zmienić: podmień wtyczkę i nazwę w vim.cmd.colorscheme.
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = { style = "night" },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
  end,
}

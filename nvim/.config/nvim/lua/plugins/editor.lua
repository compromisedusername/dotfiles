return {
  -- Znaczniki zmian git przy numerach linii + operacje na hunkach
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local map = function(mode, l, r, desc) vim.keymap.set(mode, l, r, { buffer = buf, desc = desc }) end
        map("n", "]h", function() gs.nav_hunk("next") end, "Następny hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Poprzedni hunk")
        map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<cr>", "Stage hunk")
        map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<cr>", "Reset hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage bufor")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset bufor")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Podgląd hunka")
        map("n", "<leader>ghd", gs.diffthis, "Diff z indeksem")
      end,
    },
  },
  -- Lista problemów projektu
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostyka projektu" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostyka bufora" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "TODO w projekcie" },
    },
  },
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Następne TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Poprzednie TODO" },
      { "<leader>ft", function() Snacks.picker.todo_comments() end, desc = "Szukaj TODO" },
    },
  },
  -- Szybkie skoki po ekranie: s + 2 znaki
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = { modes = { search = { enabled = false } } },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
    },
  },
  -- Sesje per katalog
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Przywróć sesję (katalog)" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Przywróć ostatnią sesję" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Nie zapisuj sesji" },
    },
  },
  -- mini.nvim: lepsze text-objecty, surround, komentarze, auto-pary
  {
    "nvim-mini/mini.nvim",
    version = false,
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup({ n_lines = 500 }) -- np. vif, daa, ci"
      -- gsa (dodaj), gsd (usuń), gsr (zamień) otoczenie, np. gsaiw"
      require("mini.surround").setup({
        mappings = {
          add = "gsa", delete = "gsd", find = "gsf", find_left = "gsF",
          highlight = "gsh", replace = "gsr", update_n_lines = "gsn",
        },
      })
      require("mini.pairs").setup()
      require("mini.move").setup() -- Alt+hjkl przesuwa linie/zaznaczenie
    end,
  },
}

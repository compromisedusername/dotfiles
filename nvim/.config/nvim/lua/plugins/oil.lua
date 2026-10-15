-- oil.nvim: edit a directory like a regular text buffer. Rename, move,
-- create and delete many files = edit text + :w (with confirmation).
-- `-` opens the current file's directory. neo-tree stays the default explorer.
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Oil",
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Oil: current file's directory" },
    { "<leader>-", function() require("oil").toggle_float() end, desc = "Oil (floating)" },
  },
  opts = {
    default_file_explorer = false, -- `nvim .` still opens neo-tree
    delete_to_trash = true, -- deleted files go to the trash
    skip_confirm_for_simple_edits = false,
    view_options = { show_hidden = true },
    float = { padding = 4, max_width = 120 },
    keymaps = {
      -- keep Ctrl+h/l for window navigation
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
      ["<C-r>"] = "actions.refresh",
      ["q"] = "actions.close",
      ["gy"] = "actions.yank_entry", -- copy path
    },
  },
}

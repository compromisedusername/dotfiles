-- smart-splits: Ctrl+h/j/k/l moves between nvim windows and, at the edge,
-- continues into the adjacent tmux pane (when running inside tmux).
-- Ctrl+arrows resize windows.
-- The other direction (tmux -> nvim) needs a snippet in ~/.tmux.conf - see PORADNIK.md.
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  opts = { move = { at_edge = "stop" } },
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, mode = { "n", "t" }, desc = "Window left" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, mode = { "n", "t" }, desc = "Window down" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, mode = { "n", "t" }, desc = "Window up" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, mode = { "n", "t" }, desc = "Window right" },
    { "<C-Up>", function() require("smart-splits").resize_up() end, desc = "Resize up" },
    { "<C-Down>", function() require("smart-splits").resize_down() end, desc = "Resize down" },
    { "<C-Left>", function() require("smart-splits").resize_left() end, desc = "Resize left" },
    { "<C-Right>", function() require("smart-splits").resize_right() end, desc = "Resize right" },
  },
}

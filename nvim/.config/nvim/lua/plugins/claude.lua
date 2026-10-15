-- Claude Code integration (claudecode.nvim by Coder).
-- Works like the official VS Code extension: the Claude CLI in a side terminal
-- sees your active file/selection and shows proposed edits as a diff in Neovim
-- to accept (:w / <leader>aa) or reject (<leader>ad).
-- The WebSocket server listens on 127.0.0.1 only and requires a token
-- (lock file in ~/.claude/ide/).
-- Requires: `claude` command in PATH.
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSend", "ClaudeCodeAdd", "ClaudeCodeTreeAdd" },
  opts = {
    terminal = {
      split_side = "right",
      split_width_percentage = 0.38,
      provider = "snacks",
    },
    diff_opts = {
      layout = "vertical",
      open_in_new_tab = false,
    },
  },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude: toggle" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: focus" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude: resume conversation" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Claude: continue last" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Claude: select model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: add current file" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: send selection" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Claude: add file from tree",
      ft = { "neo-tree" },
    },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: reject diff" },
  },
}

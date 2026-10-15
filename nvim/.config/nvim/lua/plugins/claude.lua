-- Integracja z Claude Code (claudecode.nvim od Coder).
-- Działa jak oficjalne rozszerzenie VS Code: Claude CLI w terminalu z boku
-- widzi Twój aktywny plik/zaznaczenie, a proponowane zmiany pokazuje jako
-- diff w Neovimie do akceptacji (:w / <leader>aa) lub odrzucenia (<leader>ad).
-- Serwer WebSocket nasłuchuje tylko na 127.0.0.1 i wymaga tokenu
-- (plik lock w ~/.claude/ide/).
-- Wymaga: polecenia `claude` w PATH.
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
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude: przełącz" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: fokus" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude: wznów rozmowę" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Claude: kontynuuj ostatnią" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Claude: wybierz model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: dodaj bieżący plik" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: wyślij zaznaczenie" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Claude: dodaj plik z drzewa",
      ft = { "neo-tree" },
    },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: akceptuj diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: odrzuć diff" },
  },
}

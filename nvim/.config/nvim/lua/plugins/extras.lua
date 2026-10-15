-- Opcjonalne dodatki. Ustaw `enabled = true`, zapisz i zrestartuj nvim.
return {
  -- GitHub Copilot (był w poprzednim configu). Po włączeniu: :Copilot auth
  { "github/copilot.vim", enabled = false, event = "InsertEnter" },

  -- Podgląd markdown w buforze
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
    ft = { "markdown" },
    opts = {},
  },
}

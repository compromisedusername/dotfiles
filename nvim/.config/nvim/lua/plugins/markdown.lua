-- Render markdown (headings, tables, checkboxes, code blocks) directly in
-- the buffer. Raw text is shown in insert mode.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  ft = { "markdown" },
  keys = {
    { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering", ft = "markdown" },
  },
  opts = {
    completions = { blink = { enabled = true } },
    code = { sign = false, width = "block", right_pad = 1 },
    heading = { sign = false },
  },
}

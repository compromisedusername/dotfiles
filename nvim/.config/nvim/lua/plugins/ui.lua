return {
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        component_separators = "",
        section_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = { "snacks_dashboard" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = { { "filename", path = 1 }, "diagnostics" },
        lualine_x = {
          {
            function()
              local names = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))
              return #names > 0 and (" " .. table.concat(names, ",")) or ""
            end,
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      extensions = { "neo-tree", "lazy", "trouble", "mason" },
    },
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Przypnij bufor" },
      { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Zamknij bufory po lewej" },
      { "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Zamknij bufory po prawej" },
    },
    opts = {
      options = {
        close_command = function(n) Snacks.bufdelete(n) end,
        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
        offsets = {
          { filetype = "neo-tree", text = "Pliki", highlight = "Directory", text_align = "left" },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      spec = {
        { "<leader>a", group = "AI / Claude" },
        { "<leader>b", group = "Bufory" },
        { "<leader>c", group = "Kod" },
        { "<leader>f", group = "Szukaj" },
        { "<leader>g", group = "Git" },
        { "<leader>gh", group = "Hunki" },
        { "<leader>q", group = "Sesja/wyjście" },
        { "<leader>t", group = "Terminal" },
        { "<leader>u", group = "Przełączniki" },
        { "<leader>x", group = "Diagnostyka/listy" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Skróty bufora" },
    },
  },
}

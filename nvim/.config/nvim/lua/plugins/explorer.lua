-- Przeglądarka plików z boku (neo-tree). Ctrl+h / Ctrl+l przełącza fokus
-- między drzewem a edytorem (mapowania w config/keymaps.lua).
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = false, -- przejmuje `nvim .` zamiast netrw
  keys = {
    { "<leader>e", "<cmd>Neotree toggle left<cr>", desc = "Przeglądarka plików" },
    { "<leader>o", "<cmd>Neotree focus left<cr>", desc = "Fokus na przeglądarkę" },
    { "<leader>ge", "<cmd>Neotree float git_status<cr>", desc = "Git status (drzewo)" },
    { "<leader>be", "<cmd>Neotree toggle buffers left<cr>", desc = "Bufory (drzewo)" },
  },
  opts = {
    close_if_last_window = true,
    popup_border_style = "rounded",
    sources = { "filesystem", "buffers", "git_status" },
    source_selector = { winbar = true },
    window = {
      position = "left",
      width = 34,
      mappings = {
        ["<space>"] = "none", -- leader działa też w drzewie
        ["l"] = "open",
        ["h"] = "close_node",
        ["Y"] = {
          function(state)
            local path = state.tree:get_node():get_id()
            vim.fn.setreg("+", path)
            vim.notify("Skopiowano: " .. path)
          end,
          desc = "Kopiuj ścieżkę do schowka",
        },
        ["P"] = { "toggle_preview", config = { use_float = true } },
      },
    },
    filesystem = {
      bind_to_cwd = true,
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      hijack_netrw_behavior = "open_default",
      filtered_items = {
        visible = true, -- ukryte pliki widoczne (przyciemnione) - .github, .terraform itd.
        hide_dotfiles = false,
        hide_gitignored = false,
        never_show = { ".git", ".DS_Store" },
      },
    },
    default_component_configs = {
      indent = { with_expanders = true },
      git_status = {
        symbols = { unstaged = "󰄱", staged = "", untracked = "", ignored = "" },
      },
    },
  },
}

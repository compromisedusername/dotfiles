-- Side file explorer (neo-tree). Ctrl+h / Ctrl+l moves focus between the
-- tree and the editor (mappings in lua/plugins/smart-splits.lua).
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = false, -- handles `nvim .` instead of netrw
  keys = {
    { "<leader>e", "<cmd>Neotree toggle left<cr>", desc = "File explorer" },
    { "<leader>o", "<cmd>Neotree focus left<cr>", desc = "Focus file explorer" },
    { "<leader>ge", "<cmd>Neotree float git_status<cr>", desc = "Git status (tree)" },
    { "<leader>be", "<cmd>Neotree toggle buffers left<cr>", desc = "Buffers (tree)" },
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
        ["<space>"] = "none", -- keep <leader> working inside the tree
        ["l"] = "open",
        ["h"] = "close_node",
        ["Y"] = {
          function(state)
            local path = state.tree:get_node():get_id()
            vim.fn.setreg("+", path)
            vim.notify("Copied: " .. path)
          end,
          desc = "Copy path to clipboard",
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
        visible = true, -- hidden files shown dimmed - .github, .terraform etc.
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

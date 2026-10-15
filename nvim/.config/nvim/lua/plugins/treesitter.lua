-- Podświetlanie składni / wcięcia przez tree-sitter.
-- Gałąź "master" jest stabilna i działa z Neovim 0.11 bez dodatkowego
-- tree-sitter CLI (gałąź "main" to przepisana wersja wymagająca CLI).
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "TSInstall", "TSUpdate", "TSUpdateSync", "TSInstallInfo" },
  main = "nvim-treesitter.configs",
  opts = {
    -- Jawna lista parserów; auto_install wyłączone - nic nie ściąga się samo.
    ensure_installed = {
      "bash", "python", "terraform", "hcl", "lua", "luadoc", "vim", "vimdoc",
      "query", "yaml", "json", "jsonc", "toml", "dockerfile", "helm", "gotmpl",
      "go", "make", "ini", "sql", "markdown", "markdown_inline", "regex",
      "diff", "git_config", "gitcommit", "gitignore", "git_rebase", "groovy",
      "javascript", "html", "xml", "csv", "ssh_config", "jq", "nginx",
    },
    auto_install = false,
    highlight = {
      enable = true,
      disable = function(_, buf)
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        return ok and stats and stats.size > 2 * 1024 * 1024 -- >2MB: bez TS
      end,
    },
    indent = { enable = true, disable = { "yaml", "python" } },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        node_decremental = "<bs>",
        scope_incremental = false,
      },
    },
  },
}

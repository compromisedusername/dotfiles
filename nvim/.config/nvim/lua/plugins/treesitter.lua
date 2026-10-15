-- Syntax highlighting, indentation and folding via tree-sitter.
-- "main" branch (Neovim 0.12+). Parsers are compiled by the tree-sitter CLI
-- installed by Mason (`tools` list in lsp.lua).
-- gitcommit is skipped: Mason's tree-sitter CLI can't build it on glibc 2.36 (Debian 12);
-- commit messages use Vim's built-in syntax highlighting.
local parsers = {
  "bash", "python", "terraform", "hcl", "lua", "luadoc", "vim", "vimdoc",
  "query", "yaml", "json", "toml", "dockerfile", "helm", "gotmpl",
  "go", "make", "ini", "sql", "markdown", "markdown_inline", "regex",
  "diff", "git_config", "gitignore", "git_rebase", "groovy",
  "javascript", "html", "xml", "csv", "ssh_config", "jq", "nginx",
}

-- No treesitter indentation where the built-in one works better
local no_ts_indent = { yaml = true, python = true, markdown = true }

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- the main branch doesn't support lazy-loading
  build = ":TSUpdate",
  dependencies = { "mason-org/mason.nvim" }, -- tree-sitter CLI on PATH
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup()

    -- Install missing parsers in the background (explicit list only)
    local installed = ts.get_installed()
    local missing = vim.tbl_filter(function(p) return not vim.tbl_contains(installed, p) end, parsers)
    if #missing > 0 and vim.fn.executable("tree-sitter") == 1 then ts.install(missing) end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then return end
        if not no_ts_indent[lang] then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}

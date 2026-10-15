-- Formatowanie (conform) i lintowanie (nvim-lint).
-- Format przy zapisie: włączony; przełącz <leader>uf (globalnie) / <leader>uF (bufor).
return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, mode = { "n", "x" }, desc = "Formatuj" },
      {
        "<leader>uf",
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format przy zapisie: " .. (vim.g.disable_autoformat and "WYŁ" or "WŁ"))
        end,
        desc = "Przełącz format przy zapisie",
      },
      {
        "<leader>uF",
        function()
          vim.b.disable_autoformat = not vim.b.disable_autoformat
          vim.notify("Format przy zapisie (bufor): " .. (vim.b.disable_autoformat and "WYŁ" or "WŁ"))
        end,
        desc = "Przełącz format przy zapisie (bufor)",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        python = { "ruff_organize_imports", "ruff_format" },
        terraform = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
        hcl = { "terraform_fmt" },
        json = { "jq" },
      },
      formatters = {
        shfmt = { prepend_args = { "-i", "2", "-ci", "-bn" } },
      },
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(buf)
        if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
        -- Helm/ansible: formatowanie YAML potrafi zepsuć szablony - pomijamy.
        local ft = vim.bo[buf].filetype
        if ft == "helm" or ft == "yaml.ansible" then return end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      -- bash: shellcheck działa przez bashls; terraform: tflint przez LSP.
      lint.linters_by_ft = {
        dockerfile = { "hadolint" },
        zsh = { "zsh" },
      }
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
        callback = function()
          -- uruchom tylko lintery, które faktycznie są zainstalowane
          local names = vim.tbl_filter(function(name)
            local linter = lint.linters[name]
            local cmd = linter and (type(linter) == "function" and linter().cmd or linter.cmd)
            return cmd and vim.fn.executable(cmd) == 1
          end, lint.linters_by_ft[vim.bo.filetype] or {})
          if #names > 0 then lint.try_lint(names) end
        end,
      })
    end,
  },
}

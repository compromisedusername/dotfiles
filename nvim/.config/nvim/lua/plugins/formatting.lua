-- Formatting (conform) and linting (nvim-lint).
-- Format on save: enabled; toggle with <leader>uf (global) / <leader>uF (buffer).
return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true })
        end,
        mode = { "n", "x" },
        desc = "Format",
      },
      {
        "<leader>uf",
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format on save: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
        end,
        desc = "Toggle format on save",
      },
      {
        "<leader>uF",
        function()
          vim.b.disable_autoformat = not vim.b.disable_autoformat
          vim.notify("Format on save (buffer): " .. (vim.b.disable_autoformat and "OFF" or "ON"))
        end,
        desc = "Toggle format on save (buffer)",
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
        if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
          return
        end
        -- Helm/Ansible: YAML formatting can break templates - skip.
        local ft = vim.bo[buf].filetype
        if ft == "helm" or ft == "yaml.ansible" then
          return
        end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      -- bash: shellcheck runs via bashls; terraform: tflint runs as an LSP.
      require("kube").register_linters(lint)
      lint.linters_by_ft = {
        dockerfile = { "hadolint" },
        zsh = { "zsh" },
        yaml = { "kubeconform", "kube_linter" }, -- K8s manifests only (condition below)
      }
      local kube_linters = { kubeconform = true, kube_linter = true }
      local function run(ev)
        local is_manifest
        -- run only linters that are actually installed
        local names = vim.tbl_filter(function(name)
          if kube_linters[name] then
            -- kube-linter reads the file from disk - skip on InsertLeave
            if name == "kube_linter" and ev.event == "InsertLeave" then
              return false
            end
            if is_manifest == nil then
              is_manifest = require("kube").is_manifest(ev.buf)
            end
            if not is_manifest then
              return false
            end
          end
          local linter = lint.linters[name]
          local cmd = linter and (type(linter) == "function" and linter().cmd or linter.cmd)
          return cmd and vim.fn.executable(cmd) == 1
        end, lint.linters_by_ft[vim.bo.filetype] or {})
        if #names > 0 then
          lint.try_lint(names)
        end
      end
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
        callback = run,
      })
      -- the plugin loads while the first file is opened - lint it right away
      -- (once its filetype is set, hence vim.schedule)
      local first = vim.api.nvim_get_current_buf()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(first) and first == vim.api.nvim_get_current_buf() then
          run({ buf = first, event = "BufReadPost" })
        end
      end)
    end,
  },
}

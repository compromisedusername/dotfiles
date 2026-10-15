-- LSP: mason installs the servers, nvim-lspconfig provides their configs,
-- mason-lspconfig enables them automatically (vim.lsp.enable, Neovim 0.11+).
-- To add a language: add the server to `servers` (names: :help lspconfig-all).
local servers = {
  bashls = {}, -- bash/sh (+ shellcheck automatically)
  terraformls = {},
  tflint = {},
  pyright = {},
  ruff = {}, -- fast Python linter + formatter
  yamlls = {},
  jsonls = {},
  dockerls = {},
  docker_compose_language_service = {},
  helm_ls = {},
  ansiblels = {},
  lua_ls = {},
  marksman = {}, -- markdown
}

-- Non-LSP tools (formatters / linters / debuggers) installed by mason
local tools = { "shfmt", "shellcheck", "stylua", "hadolint", "debugpy", "tree-sitter-cli" }

return {
  {
    "mason-org/mason.nvim",
    lazy = false, -- puts Mason tools on PATH from startup
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    opts = { ui = { border = "rounded" } },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    opts = { ensure_installed = tools, run_on_start = true },
  },
  { "b0o/SchemaStore.nvim", lazy = true, version = false },
  {
    "folke/lazydev.nvim", -- Neovim API completion when editing this config
    ft = "lua",
    opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Per-server settings (override nvim-lspconfig defaults)
      servers.yamlls = {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" }, -- SchemaStore.nvim is used instead
            schemas = vim.tbl_extend("force", require("schemastore").yaml.schemas(), {
              kubernetes = { "k8s/**/*.yaml", "kubernetes/**/*.yaml", "manifests/**/*.yaml" },
            }),
            keyOrdering = false,
            format = { enable = true },
            validate = true,
          },
        },
      }
      servers.jsonls = {
        settings = {
          json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
        },
      }
      servers.lua_ls = {
        settings = {
          Lua = { completion = { callSnippet = "Replace" }, telemetry = { enable = false } },
        },
      }
      -- nvim-lspconfig uses a Neovim 0.12 API here; this variant also works on 0.11
      servers.terraformls = {
        on_attach = function(_, bufnr)
          if vim.lsp.codelens.enable then
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
          else
            vim.lsp.codelens.refresh({ bufnr = bufnr })
          end
        end,
      }
      servers.pyright = {
        -- use the project's .venv/venv if present
        before_init = function(_, config)
          if os.getenv("VIRTUAL_ENV") or not config.root_dir then return end
          for _, dir in ipairs({ ".venv", "venv" }) do
            local py = config.root_dir .. "/" .. dir .. "/bin/python"
            if vim.fn.executable(py) == 1 then
              config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, { pythonPath = py })
              return
            end
          end
        end,
        settings = {
          pyright = { disableOrganizeImports = true }, -- ruff does this
          python = { analysis = { typeCheckingMode = "basic" } },
        },
      }

      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
      for name, cfg in pairs(servers) do
        if next(cfg) then vim.lsp.config(name, cfg) end
      end

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_enable = true,
      })

      vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "󰌵 ",
          },
        },
      })

      -- Keymaps active only when an LSP client is attached to the buffer.
      -- Built-in defaults: K (hover), grn (rename), gra (actions), grr (references),
      -- gri (implementations), gO (symbols).
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          local map = function(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
          end
          map("gd", function() Snacks.picker.lsp_definitions() end, "Definition")
          map("gD", vim.lsp.buf.declaration, "Declaration")
          map("gr", function() Snacks.picker.lsp_references() end, "References")
          map("gI", function() Snacks.picker.lsp_implementations() end, "Implementations")
          map("gy", function() Snacks.picker.lsp_type_definitions() end, "Type definition")
          map("<leader>ca", vim.lsp.buf.code_action, "Code actions", { "n", "x" })
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>cs", function() Snacks.picker.lsp_symbols() end, "Document symbols")
          map("<leader>cS", function() Snacks.picker.lsp_workspace_symbols() end, "Workspace symbols")
          map("<leader>ci", "<cmd>checkhealth vim.lsp<cr>", "LSP info")
          map("<leader>uh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
          end, "Toggle inlay hints")
        end,
      })
    end,
  },
}

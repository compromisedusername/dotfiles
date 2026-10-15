-- LSP: mason instaluje serwery, nvim-lspconfig dostarcza ich konfigurację,
-- mason-lspconfig automatycznie je włącza (vim.lsp.enable, Neovim 0.11+).
-- Żeby dodać język: dopisz serwer do `servers` (nazwy: :help lspconfig-all).
local servers = {
  bashls = {}, -- bash/sh (+ shellcheck automatycznie)
  terraformls = {},
  tflint = {},
  pyright = {},
  ruff = {}, -- szybki linter + formatter Pythona
  yamlls = {},
  jsonls = {},
  dockerls = {},
  docker_compose_language_service = {},
  helm_ls = {},
  ansiblels = {},
  lua_ls = {},
  marksman = {}, -- markdown
}

-- Narzędzia spoza LSP (formatery / lintery) instalowane przez mason
local tools = { "shfmt", "shellcheck", "stylua", "hadolint" }

return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
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
    "folke/lazydev.nvim", -- podpowiedzi API Neovima przy edycji tego configu
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
      -- Ustawienia per-serwer (nadpisują domyślne z nvim-lspconfig)
      servers.yamlls = {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" }, -- używamy SchemaStore.nvim
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
      -- nvim-lspconfig używa tu API z Neovim 0.12; wersja zgodna też z 0.11
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
        settings = {
          pyright = { disableOrganizeImports = true }, -- robi to ruff
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

      -- Skróty aktywne tylko gdy LSP jest podpięty do bufora.
      -- Domyślne w 0.11: K (hover), grn (rename), gra (akcje), grr (referencje),
      -- gri (implementacje), gO (symbole), Ctrl+s w insert (sygnatura).
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          local map = function(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
          end
          map("gd", function() Snacks.picker.lsp_definitions() end, "Definicja")
          map("gD", vim.lsp.buf.declaration, "Deklaracja")
          map("gr", function() Snacks.picker.lsp_references() end, "Referencje")
          map("gI", function() Snacks.picker.lsp_implementations() end, "Implementacje")
          map("gy", function() Snacks.picker.lsp_type_definitions() end, "Definicja typu")
          map("<leader>ca", vim.lsp.buf.code_action, "Akcje kodu", { "n", "x" })
          map("<leader>cr", vim.lsp.buf.rename, "Zmień nazwę")
          map("<leader>cs", function() Snacks.picker.lsp_symbols() end, "Symbole w pliku")
          map("<leader>cS", function() Snacks.picker.lsp_workspace_symbols() end, "Symbole w projekcie")
          map("<leader>ci", "<cmd>checkhealth vim.lsp<cr>", "Info o LSP")
          map("<leader>uh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
          end, "Przełącz inlay hints")
        end,
      })
    end,
  },
}

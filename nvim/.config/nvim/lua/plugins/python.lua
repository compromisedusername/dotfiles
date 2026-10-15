-- Python: debugger (nvim-dap + debugpy) and tests (neotest + pytest).
-- debugpy is installed by Mason (`tools` list in lsp.lua).
-- A .venv/venv in the project root is detected automatically
-- (pyright in lsp.lua, debugger and tests below).

-- Python from the project's virtualenv, if present
local function project_python()
  local venv = os.getenv("VIRTUAL_ENV")
  if venv then return venv .. "/bin/python" end
  local root = vim.fs.root(0, { "pyproject.toml", "setup.py", "requirements.txt", ".git" }) or vim.fn.getcwd()
  for _, dir in ipairs({ ".venv", "venv" }) do
    local py = root .. "/" .. dir .. "/bin/python"
    if vim.fn.executable(py) == 1 then return py end
  end
  return vim.fn.exepath("python3")
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "igorlfs/nvim-dap-view", opts = { winbar = { controls = { enabled = true } } } },
      { "theHamsta/nvim-dap-virtual-text", opts = {} }, -- variable values inline
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: start/continue" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end,
        desc = "Conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Start/continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last session" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "REPL" },
      { "<leader>de", function() require("dap.ui.widgets").hover() end, desc = "Evaluate under cursor", mode = { "n", "x" } },
      { "<leader>dv", "<cmd>DapViewToggle<cr>", desc = "Debugger panel" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dm", function() require("dap-python").test_method() end, desc = "Debug test method", ft = "python" },
      { "<leader>dk", function() require("dap-python").test_class() end, desc = "Debug test class", ft = "python" },
    },
    config = function()
      local dap, dv = require("dap"), require("dap-view")
      -- debugpy from Mason as the adapter; code runs with the project's Python
      require("dap-python").setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")
      require("dap-python").test_runner = "pytest"
      for _, cfg in ipairs(dap.configurations.python or {}) do
        cfg.pythonPath = cfg.pythonPath or project_python
      end

      -- Open the panel when debugging starts, close it when it ends
      dap.listeners.before.attach["dap-view"] = function() dv.open() end
      dap.listeners.before.launch["dap-view"] = function() dv.open() end
      dap.listeners.before.event_terminated["dap-view"] = function() dv.close() end
      dap.listeners.before.event_exited["dap-view"] = function() dv.close() end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
    end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
    },
    keys = {
      { "<leader>Tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>Ta", function() require("neotest").run.run(vim.fn.getcwd()) end, desc = "Run all tests" },
      { "<leader>Tl", function() require("neotest").run.run_last() end, desc = "Run last" },
      { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
      { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
      { "<leader>To", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Test output" },
      { "<leader>TO", function() require("neotest").output_panel.toggle() end, desc = "Output panel" },
      { "<leader>TS", function() require("neotest").run.stop() end, desc = "Stop" },
      { "]T", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
      { "[T", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Previous failed test" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            runner = "pytest",
            python = project_python,
            dap = { justMyCode = false },
          }),
        },
        status = { virtual_text = true },
        output = { open_on_run = false },
      })
    end,
  },
}

-- snacks.nvim (folke): file/text picker, dashboard, notifications, terminal,
-- lazygit, indent guides, big file handling - one plugin instead of a dozen.
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      enabled = true,
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find file", action = ":lua Snacks.picker.files()" },
          { icon = " ", key = "g", desc = "Find text", action = ":lua Snacks.picker.grep()" },
          { icon = " ", key = "r", desc = "Recent files", action = ":lua Snacks.picker.recent()" },
          { icon = " ", key = "s", desc = "Restore session", action = ":lua require('persistence').load()" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
    explorer = { enabled = false }, -- neo-tree is used instead
    gitbrowse = {
      url_patterns = {
        -- self-hosted GitLab (e.g. gitlab.czk.comarch) - same URL layout as gitlab.com
        ["gitlab%."] = {
          branch = "/-/tree/{branch}",
          file = "/-/blob/{branch}/{file}#L{line_start}-{line_end}",
          permalink = "/-/blob/{commit}/{file}#L{line_start}-{line_end}",
          commit = "/-/commit/{commit}",
        },
      },
    },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    picker = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    terminal = { win = { style = "terminal" } },
  },
  keys = {
    -- Search
    { "<leader><space>", function() Snacks.picker.smart() end, desc = "Find files (smart)" },
    { "<leader>ff", function() Snacks.picker.files({ hidden = true }) end, desc = "Files" },
    { "<leader>fg", function() Snacks.picker.grep({ hidden = true }) end, desc = "Grep project" },
    { "<leader>fw", function() Snacks.picker.grep_word() end, desc = "Grep word/selection", mode = { "n", "x" } },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Help" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Config files" },
    { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>fn", function() Snacks.picker.notifications() end, desc = "Notification history" },
    { "<leader>fp", function() Snacks.picker.registers() end, desc = "Registers / clipboard" },
    { "<leader>fu", function() Snacks.picker.undo() end, desc = "Undo history" },
    { "<leader>f/", function() Snacks.picker.lines() end, desc = "Search buffer lines" },
    { "<leader>fR", function() Snacks.picker.resume() end, desc = "Resume last search" },
    -- Git
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git log" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git status" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git blame line" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Open in browser", mode = { "n", "x" } },
    -- Buffers / terminal / misc
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer" },
    { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Delete other buffers" },
    { "<C-\\>", function() Snacks.terminal() end, desc = "Terminal", mode = { "n", "t" } },
    { "<leader>tt", function() Snacks.terminal() end, desc = "Terminal (bottom)" },
    { "<leader>tf", function() Snacks.terminal(nil, { win = { position = "float" } }) end, desc = "Terminal (floating)" },
    {
      "<leader>tk",
      function()
        if vim.fn.executable("k9s") == 0 then return vim.notify("k9s not found in PATH", vim.log.levels.WARN) end
        Snacks.terminal("k9s", { win = { position = "float", width = 0.95, height = 0.95 } })
      end,
      desc = "k9s (Kubernetes)",
    },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss notifications" },
    { "<leader>z", function() Snacks.zen() end, desc = "Zen mode" },
    { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference" },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Previous reference" },
  },
}

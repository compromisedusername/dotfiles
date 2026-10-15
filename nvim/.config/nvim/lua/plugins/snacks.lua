-- snacks.nvim (folke): wyszukiwarka plików/tekstu, dashboard, powiadomienia,
-- terminal, lazygit, linie wcięć, obsługa dużych plików - jedna wtyczka
-- zamiast kilkunastu.
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
          { icon = " ", key = "f", desc = "Znajdź plik", action = ":lua Snacks.picker.files()" },
          { icon = " ", key = "g", desc = "Szukaj tekstu", action = ":lua Snacks.picker.grep()" },
          { icon = " ", key = "r", desc = "Ostatnie pliki", action = ":lua Snacks.picker.recent()" },
          { icon = " ", key = "s", desc = "Przywróć sesję", action = ":lua require('persistence').load()" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Wyjdź", action = ":qa" },
        },
      },
    },
    explorer = { enabled = false }, -- używamy neo-tree
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
    -- Wyszukiwanie
    { "<leader><space>", function() Snacks.picker.smart() end, desc = "Szukaj plików (smart)" },
    { "<leader>ff", function() Snacks.picker.files({ hidden = true }) end, desc = "Pliki" },
    { "<leader>fg", function() Snacks.picker.grep({ hidden = true }) end, desc = "Grep w projekcie" },
    { "<leader>fw", function() Snacks.picker.grep_word() end, desc = "Grep słowa/zaznaczenia", mode = { "n", "x" } },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Bufory" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Ostatnie pliki" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Pomoc" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Skróty klawiszowe" },
    { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Pliki configu" },
    { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostyka" },
    { "<leader>fn", function() Snacks.picker.notifications() end, desc = "Historia powiadomień" },
    { "<leader>fp", function() Snacks.picker.registers() end, desc = "Rejestry / schowek" },
    { "<leader>fu", function() Snacks.picker.undo() end, desc = "Historia undo" },
    { "<leader>f/", function() Snacks.picker.lines() end, desc = "Szukaj w buforze" },
    { "<leader>fR", function() Snacks.picker.resume() end, desc = "Wznów ostatnie szukanie" },
    -- Git
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git log" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git status" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git blame linii" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Otwórz w przeglądarce", mode = { "n", "x" } },
    -- Bufory / terminal / inne
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Zamknij bufor" },
    { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Zamknij pozostałe bufory" },
    { "<C-\\>", function() Snacks.terminal() end, desc = "Terminal", mode = { "n", "t" } },
    { "<leader>tt", function() Snacks.terminal() end, desc = "Terminal (dół)" },
    { "<leader>tf", function() Snacks.terminal(nil, { win = { position = "float" } }) end, desc = "Terminal (pływający)" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Ukryj powiadomienia" },
    { "<leader>z", function() Snacks.zen() end, desc = "Tryb zen" },
    { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Następne wystąpienie" },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Poprzednie wystąpienie" },
  },
}

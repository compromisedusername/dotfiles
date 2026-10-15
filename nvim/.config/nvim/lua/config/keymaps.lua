-- Global keymaps (plugin keymaps live in their files under lua/plugins/) ----------
local map = vim.keymap.set

-- Ctrl+h/j/k/l navigation and window resizing: lua/plugins/smart-splits.lua
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Clipboard: y copies to the system clipboard (clipboard=unnamedplus),
-- but c/x don't overwrite it - same as the previous config.
map({ "n", "x" }, "c", '"_c', { desc = "Change without yanking" })
map({ "n", "x" }, "C", '"_C', { desc = "Change without yanking" })
map({ "n", "x" }, "x", '"_x', { desc = "Delete char without yanking" })
-- Pasting over a selection keeps the clipboard intact
map("x", "p", '"_dP', { desc = "Paste without overwriting clipboard" })

-- General
map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>", { desc = "Clear search highlight" })
map({ "n", "i", "x" }, "<C-s>", "<cmd>write<cr><Esc>", { desc = "Save" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>qq", "<cmd>confirm qall<cr>", { desc = "Quit" })
map("n", "<leader>n", "<cmd>enew<cr>", { desc = "New file" })
map("n", "<leader>H", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/PORADNIK.md")
end, { desc = "User guide (PORADNIK.md)" })

-- Move selected lines; keep the selection when indenting
map("x", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down", silent = true })
map("x", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up", silent = true })
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Buffers
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- Diagnostics
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })

-- Toggles
map("n", "<leader>uw", function() vim.wo.wrap = not vim.wo.wrap end, { desc = "Toggle line wrap" })
map("n", "<leader>ur", function() vim.wo.relativenumber = not vim.wo.relativenumber end, { desc = "Toggle relative numbers" })
map("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

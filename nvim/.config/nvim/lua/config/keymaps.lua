-- Globalne skróty (skróty wtyczek są w ich plikach w lua/plugins/) -------------
local map = vim.keymap.set

-- Nawigacja między oknami: Ctrl+h/j/k/l (np. neo-tree <-> edytor)
map("n", "<C-h>", "<C-w>h", { desc = "Okno w lewo" })
map("n", "<C-j>", "<C-w>j", { desc = "Okno w dół" })
map("n", "<C-k>", "<C-w>k", { desc = "Okno w górę" })
map("n", "<C-l>", "<C-w>l", { desc = "Okno w prawo" })
-- To samo z terminala (np. z okna Claude Code wracasz Ctrl+h do kodu)
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Okno w lewo" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Okno w dół" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Okno w górę" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Okno w prawo" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Wyjdź z trybu terminala" })

-- Zmiana rozmiaru okien
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Wyższe okno" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Niższe okno" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Węższe okno" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Szersze okno" })

-- Schowek: y kopiuje do systemowego (clipboard=unnamedplus), ale c/x
-- nie nadpisują schowka - jak w poprzednim configu.
map({ "n", "x" }, "c", '"_c', { desc = "Zmień bez kopiowania" })
map({ "n", "x" }, "C", '"_C', { desc = "Zmień bez kopiowania" })
map({ "n", "x" }, "x", '"_x', { desc = "Usuń znak bez kopiowania" })
-- Wklejanie na zaznaczenie nie nadpisuje schowka
map("x", "p", '"_dP', { desc = "Wklej bez nadpisywania schowka" })

-- Ogólne
map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>", { desc = "Wyczyść podświetlenie" })
map({ "n", "i", "x" }, "<C-s>", "<cmd>write<cr><Esc>", { desc = "Zapisz" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Zapisz" })
map("n", "<leader>qq", "<cmd>confirm qall<cr>", { desc = "Wyjdź" })
map("n", "<leader>n", "<cmd>enew<cr>", { desc = "Nowy plik" })

-- Przesuwanie zaznaczonych linii i zachowanie zaznaczenia przy wcięciach
map("x", "J", ":m '>+1<cr>gv=gv", { desc = "Przesuń w dół", silent = true })
map("x", "K", ":m '<-2<cr>gv=gv", { desc = "Przesuń w górę", silent = true })
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Bufory
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Następny bufor" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Poprzedni bufor" })

-- Diagnostyka
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Diagnostyka linii" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Następny błąd/ostrzeżenie" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Poprzedni błąd/ostrzeżenie" })

-- Przełączniki
map("n", "<leader>uw", function() vim.wo.wrap = not vim.wo.wrap end, { desc = "Przełącz zawijanie" })
map("n", "<leader>ur", function() vim.wo.relativenumber = not vim.wo.relativenumber end, { desc = "Przełącz numerację względną" })
map("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Przełącz diagnostykę" })

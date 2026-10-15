-- Entry point. Order matters: leader must be set before lazy.nvim loads.
require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
require("kube").setup() -- Kubernetes: lua/kube/init.lua, keymaps under <leader>k

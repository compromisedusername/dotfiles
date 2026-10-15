local augroup = function(name) return vim.api.nvim_create_augroup("user_" .. name, { clear = true }) end
local autocmd = vim.api.nvim_create_autocmd

-- DevOps filetypes ---------------------------------------------------------------
local function in_helm_chart(path)
  return vim.fs.root(path, "Chart.yaml") ~= nil
end

vim.filetype.add({
  extension = {
    tf = "terraform",
    tfvars = "terraform-vars",
    hcl = "hcl",
    tfstate = "json",
    zsh = "zsh",
  },
  filename = {
    [".zshrc"] = "zsh",
    [".zshenv"] = "zsh",
    [".zprofile"] = "zsh",
    ["Jenkinsfile"] = "groovy",
    [".terraformrc"] = "hcl",
    ["terraform.rc"] = "hcl",
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
  },
  pattern = {
    -- Helm: templates inside a directory that contains Chart.yaml
    [".*/templates/.*%.ya?ml"] = function(path)
      if in_helm_chart(path) then return "helm" end
    end,
    [".*/templates/.*%.tpl"] = "helm",
    ["helmfile.*%.ya?ml"] = "helm",
    -- Ansible
    [".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/handlers/.*%.ya?ml"] = "yaml.ansible",
    [".*/group_vars/.*"] = "yaml.ansible",
    [".*/host_vars/.*"] = "yaml.ansible",
    ["Dockerfile%..*"] = "dockerfile",
    [".*%.Dockerfile"] = "dockerfile",
  },
})

-- Treesitter: zsh uses the bash parser, yaml variants use the yaml parser.
vim.treesitter.language.register("bash", "zsh")
vim.treesitter.language.register("yaml", { "yaml.ansible", "yaml.docker-compose" })
vim.treesitter.language.register("hcl", "terraform-vars")

-- Behaviour ----------------------------------------------------------------------
autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})

autocmd("FileType", {
  group = augroup("indent_python"),
  pattern = { "python" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.colorcolumn = "88"
  end,
})

-- Restore the last cursor position when opening a file
autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount and vim.bo[ev.buf].buftype == "" then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Equalize splits when the terminal is resized
autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- Close helper windows with q
autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "lspinfo", "checkhealth", "man", "notify", "startuptime" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- Create missing parent directories on save
autocmd("BufWritePre", {
  group = augroup("auto_mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = (vim.uv or vim.loop).fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Reload files changed on disk (e.g. edited by Claude)
autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end
  end,
})

-- Kubernetes in Neovim: a small local module built only on kubectl / helm.
-- No third-party plugins or binaries - it uses your kubeconfig.
--
-- Safety:
--  * every cluster-mutating operation asks for confirmation and shows the context
--    + namespace; on production you have to type the context name,
--  * commands run with an explicit --context (the one you confirmed),
--  * a resource edit buffer refuses to save if the context changed in the meantime,
--  * decoded Secrets never touch the disk (no file, swap or undo),
--  * switching kubeconfig (<leader>kf) changes $KUBECONFIG of this nvim instance only.
--
-- Kubeconfigs: one file per cluster in ~/.kube/configs/*.yaml, described by
-- `kcfg-info` (dotfiles: zsh/.local/bin) - the same data as `kcfg` in zsh.
local M = {}

-- A context / kubeconfig name is production when one of its words (split on
-- - _ . / @ :) is in this list - "acme-prod-eu" is, "nonprod", "non-prod" and
-- "preprod" are not. Keep in sync with kcfg-info and ~/.p10k.zsh (red prompt).
M.prod_words = { prod = true, prd = true, production = true }

M.state = { context = nil, namespace = nil, kubeconfig = nil, server = nil }

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "kube" })
end

local function have(bin)
  if vim.fn.executable(bin) == 1 then
    return true
  end
  notify("`" .. bin .. "` not found in PATH", vim.log.levels.ERROR)
  return false
end

-- Run a command synchronously (with a timeout)
local function run(cmd, opts)
  opts = opts or {}
  local ok, obj = pcall(vim.system, cmd, { text = true, stdin = opts.stdin, cwd = opts.cwd })
  if not ok then
    return { code = 127, stdout = "", stderr = tostring(obj) }
  end
  local res = obj:wait(opts.timeout or 20000)
  if res.signal == 15 or res.code == 124 then
    res.stderr = (res.stderr or "") .. "\n(timed out)"
  end
  return res
end

local function kubectl(args, opts)
  return run(vim.list_extend({ "kubectl" }, args), opts)
end

local function lines_of(text)
  text = (text or ""):gsub("\n$", "")
  return vim.split(text, "\n", { plain = true })
end

local function err_of(res)
  local e = vim.trim((res.stderr ~= "" and res.stderr) or res.stdout or "")
  return e ~= "" and e or ("exit code " .. tostring(res.code))
end

-- State: context / namespace -----------------------------------------------------

local function matches_prod(s)
  local words = {}
  for w in (s or ""):lower():gmatch("[%l%d]+") do
    table.insert(words, w)
  end
  for i, w in ipairs(words) do
    if M.prod_words[w] and words[i - 1] ~= "non" then
      return true
    end
  end
  return false
end

-- Production if the context name or (when no context is given) the active
-- kubeconfig file name matches M.prod_patterns.
function M.is_prod(ctx)
  if ctx ~= nil then
    return matches_prod(ctx)
  end
  return matches_prod(M.state.context) or matches_prod(M.kubeconfig_name())
end

-- Active kubeconfig file: $KUBECONFIG of this nvim, or ~/.kube/config (resolved)
function M.kubeconfig_path()
  local env = vim.env.KUBECONFIG
  if env and env ~= "" then
    return env
  end
  local default = vim.fn.expand("~/.kube/config")
  return vim.fn.resolve(default)
end

function M.kubeconfig_name()
  local p = M.state.kubeconfig or M.kubeconfig_path()
  return p and vim.fn.fnamemodify(p, ":t:r") or nil
end

-- Read from kubeconfig (local only, no cluster connection)
-- One `kubectl config view --minify` call (local, no cluster access, secrets redacted).
-- refresh_state()        - synchronous (~50 ms), used before actions
-- refresh_state(true)    - asynchronous, used for the statusline (never blocks the UI)
local function apply_state(res)
  M.state.kubeconfig = M.kubeconfig_path()
  local ok, cfg = pcall(vim.json.decode, res.code == 0 and res.stdout or "")
  if not ok or type(cfg) ~= "table" then
    M.state.context, M.state.namespace, M.state.server = nil, nil, nil
  else
    local ctx = (cfg.contexts or {})[1] or {}
    local cluster = (cfg.clusters or {})[1] or {}
    M.state.context = cfg["current-context"] ~= "" and cfg["current-context"] or nil
    M.state.namespace = (ctx.context or {}).namespace or "default"
    M.state.server = (cluster.cluster or {}).server
  end
  pcall(function()
    require("lualine").refresh()
  end)
end

function M.refresh_state(async)
  if vim.fn.executable("kubectl") == 0 then
    return
  end
  local cmd = { "kubectl", "config", "view", "--minify", "-o", "json" }
  if async then
    vim.system(cmd, { text = true, timeout = 5000 }, function(res)
      vim.schedule(function()
        apply_state(res)
      end)
    end)
  else
    apply_state(run(cmd, { timeout = 5000 }))
  end
end

-- lualine component: ⎈ context/namespace (red on production)
function M.statusline()
  if not M.state.context then
    return ""
  end
  local name = M.kubeconfig_name()
  local prefix = (name and name ~= M.state.context and name ~= "config") and (name .. " › ") or ""
  return "⎈ " .. prefix .. M.state.context .. "/" .. (M.state.namespace or "default")
end

function M.statusline_color()
  if M.is_prod() then
    return { fg = "#ffffff", bg = "#c0392b", gui = "bold" }
  end
  return nil
end

-- kcfg-info data for kubeconfig files (nil if the helper isn't installed)
local function kcfg_info(files)
  if vim.fn.executable("kcfg-info") == 0 then
    return nil
  end
  local res = run(vim.list_extend({ "kcfg-info", "--json" }, files or {}), { timeout = 15000 })
  if res.code ~= 0 then
    return nil
  end
  local ok, data = pcall(vim.json.decode, res.stdout)
  return ok and data or nil
end

-- Identity (SA / cert / exec) of the current context in the active kubeconfig
local function current_identity()
  local path = M.state.kubeconfig
  if not path or vim.fn.filereadable(path) == 0 then
    return nil
  end
  local data = kcfg_info({ path })
  for _, c in ipairs(data and data[1] and data[1].contexts or {}) do
    if c.context == M.state.context then
      return c.identity
    end
  end
end

-- Confirm a cluster-mutating operation. Returns the context to use, or nil.
local function confirm(action)
  M.refresh_state()
  local ctx, ns = M.state.context, M.state.namespace
  if not ctx then
    notify("No active kubectl context", vim.log.levels.ERROR)
    return nil
  end
  local details = string.format(
    "Kubeconfig: %s\nContext:    %s\nNamespace:  %s\nServer:     %s\nIdentity:   %s",
    vim.fn.fnamemodify(M.state.kubeconfig or "?", ":~"),
    ctx,
    ns,
    M.state.server or "?",
    current_identity() or "?"
  )
  if M.is_prod() then
    local ans =
      vim.fn.input(string.format("⚠ PRODUCTION\n%s\n\n%s\nType the context name to confirm: ", details, action))
    vim.cmd("redraw")
    if ans ~= ctx then
      notify("Cancelled")
      return nil
    end
    return ctx
  end
  local choice = vim.fn.confirm(string.format("%s\n\n%s", action, details), "&Yes\n&No", 2, "Question")
  return choice == 1 and ctx or nil
end

-- Helper buffers ------------------------------------------------------------------

local scratch_id = 0

-- Read-only buffer with command output
local function scratch(title, lines, ft, opts)
  opts = opts or {}
  vim.cmd(opts.split or "botright vnew")
  local buf = vim.api.nvim_get_current_buf()
  scratch_id = scratch_id + 1
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  if opts.secret then
    vim.bo[buf].undofile = false
  end
  pcall(vim.api.nvim_buf_set_name, buf, string.format("kube://%s [%d]", title, scratch_id))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = ft or "text"
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close" })
  return buf
end

local function show_result(title, res, ft)
  if res.code ~= 0 and (res.stdout or "") == "" then
    notify(title .. ":\n" .. err_of(res), vim.log.levels.ERROR)
    return
  end
  local out = lines_of(res.stdout)
  if res.stderr and vim.trim(res.stderr) ~= "" then
    vim.list_extend(out, { "", "# stderr:" })
    vim.list_extend(
      out,
      vim.tbl_map(function(l)
        return "# " .. l
      end, lines_of(res.stderr))
    )
  end
  scratch(title, out, ft)
end

local function terminal(cmd, opts)
  Snacks.terminal(cmd, vim.tbl_deep_extend("force", { win = { position = "bottom", height = 0.4 } }, opts or {}))
end

-- Text of the current buffer or selection (for kubectl ... -f -)
local function buffer_text(range)
  local s, e = 0, -1
  if range then
    s, e = range[1] - 1, range[2]
  end
  return table.concat(vim.api.nvim_buf_get_lines(0, s, e, false), "\n") .. "\n"
end

local function visual_range()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local a, b = vim.fn.line("v"), vim.fn.line(".")
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    return { math.min(a, b), math.max(a, b) }
  end
end

-- Manifests -----------------------------------------------------------------------

-- Does the buffer look like a K8s manifest (top-level apiVersion + kind)
function M.is_manifest(buf)
  buf = buf or 0
  local has_api, has_kind = false, false
  for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, math.min(vim.api.nvim_buf_line_count(buf), 3000), false)) do
    if l:match("^apiVersion:%s*%S") then
      has_api = true
    end
    if l:match("^kind:%s*%S") then
      has_kind = true
    end
    if has_api and has_kind then
      return true
    end
  end
  return false
end

-- apiVersion / kind of the YAML document under the cursor (handles `---`)
local function current_document(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local s, e = 1, #lines
  for i = row, 1, -1 do
    if lines[i]:match("^%-%-%-") then
      s = i + 1
      break
    end
  end
  for i = row + 1, #lines do
    if lines[i]:match("^%-%-%-") then
      e = i - 1
      break
    end
  end
  local doc = { start = s }
  for i = s, e do
    doc.apiVersion = doc.apiVersion or lines[i]:match("^apiVersion:%s*[\"']?([^%s\"']+)")
    doc.kind = doc.kind or lines[i]:match("^kind:%s*[\"']?([^%s\"']+)")
  end
  return doc
end

-- YAML key path under the cursor, e.g. { "spec", "template", "spec", "containers" }
local function yaml_path(buf)
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf })
  if not ok then
    return {}
  end
  local path = {}
  while node do
    if node:type() == "block_mapping_pair" or node:type() == "flow_pair" then
      local key = node:field("key")[1]
      if key then
        table.insert(path, 1, (vim.treesitter.get_node_text(key, buf):gsub("[\"']", "")))
      end
    end
    node = node:parent()
  end
  return path
end

-- K: `kubectl explain` for the field under the cursor (docs from your cluster,
-- works for CRDs too). Falls back to LSP hover.
function M.explain()
  local buf = vim.api.nvim_get_current_buf()
  local doc = current_document(buf)
  if not doc.kind or vim.fn.executable("kubectl") == 0 then
    return vim.lsp.buf.hover()
  end
  local path = yaml_path(buf)
  if path[1] == "apiVersion" or path[1] == "kind" then
    path = {}
  end
  local resource = table.concat(vim.list_extend({ doc.kind:lower() }, path), ".")
  local args = { "kubectl", "explain", resource }
  if doc.apiVersion then
    vim.list_extend(args, { "--api-version", doc.apiVersion })
  end
  vim.system(args, { text = true, timeout = 8000 }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return vim.lsp.buf.hover()
      end
      vim.lsp.util.open_floating_preview(lines_of(res.stdout), "yaml", {
        border = "rounded",
        max_width = 100,
        max_height = 30,
        focus_id = "kube_explain",
        title = " kubectl explain " .. resource .. " ",
      })
    end)
  end)
end

-- Diff / apply / delete the current file or selection ------------------------------

function M.diff()
  if not have("kubectl") then
    return
  end
  local range = visual_range()
  M.refresh_state()
  local res = kubectl({ "diff", "-f", "-" }, { stdin = buffer_text(range), timeout = 60000 })
  if res.code == 0 then
    return notify("No differences against the cluster (" .. (M.state.context or "?") .. ")")
  end
  if res.code > 1 then
    return notify("kubectl diff:\n" .. err_of(res), vim.log.levels.ERROR)
  end
  scratch("diff " .. vim.fn.expand("%:t"), lines_of(res.stdout), "diff")
end

function M.apply()
  if not have("kubectl") then
    return
  end
  local range = visual_range()
  local what = range and ("selection (lines " .. range[1] .. "-" .. range[2] .. ")") or vim.fn.expand("%:t")
  local ctx = confirm("kubectl apply: " .. what)
  if not ctx then
    return
  end
  local res = kubectl({ "--context", ctx, "apply", "-f", "-" }, { stdin = buffer_text(range), timeout = 60000 })
  notify(
    "apply [" .. ctx .. "]:\n" .. vim.trim(res.stdout .. "\n" .. res.stderr),
    res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
  )
end

function M.delete_file()
  if not have("kubectl") then
    return
  end
  local range = visual_range()
  local what = range and ("selection (lines " .. range[1] .. "-" .. range[2] .. ")") or vim.fn.expand("%:t")
  local ctx = confirm("⛔ kubectl DELETE resources from: " .. what)
  if not ctx then
    return
  end
  local res = kubectl({ "--context", ctx, "delete", "-f", "-" }, { stdin = buffer_text(range), timeout = 120000 })
  notify(
    "delete [" .. ctx .. "]:\n" .. vim.trim(res.stdout .. "\n" .. res.stderr),
    res.code == 0 and vim.log.levels.WARN or vim.log.levels.ERROR
  )
end

-- Context / namespace -------------------------------------------------------------

function M.select_context()
  if not have("kubectl") then
    return
  end
  local res = kubectl({ "config", "get-contexts", "-o", "name" })
  if res.code ~= 0 then
    return notify(err_of(res), vim.log.levels.ERROR)
  end
  M.refresh_state()
  vim.ui.select(lines_of(res.stdout), {
    prompt = "Context (current: " .. (M.state.context or "-") .. ")",
    format_item = function(c)
      return (M.is_prod(c) and "⚠ PROD  " or "        ") .. c
    end,
  }, function(choice)
    if not choice then
      return
    end
    local r = kubectl({ "config", "use-context", choice })
    M.refresh_state()
    notify(
      r.code == 0 and ("Context: " .. choice) or err_of(r),
      r.code == 0 and (M.is_prod(choice) and vim.log.levels.WARN or vim.log.levels.INFO) or vim.log.levels.ERROR
    )
  end)
end

-- Table picker: fixed column header (winbar), aligned rows, details pane below.
-- opts = { title, header, rows = { { text, value, hl } }, footer, cursor, preview(value) -> lines,
--          on_select(value), keys = { [lhs] = function(value) } }
local function table_picker(opts)
  local rows = opts.rows
  local width = vim.fn.strdisplaywidth(opts.header)
  for _, r in ipairs(rows) do
    width = math.max(width, vim.fn.strdisplaywidth(r.text))
  end
  local chrome = math.max(vim.fn.strdisplaywidth(opts.title or ""), vim.fn.strdisplaywidth(opts.footer or "")) + 4
  width = math.min(math.max(width + 1, chrome), vim.o.columns - 4)
  local preview_h = opts.preview and 9 or 0
  local list_h = math.max(1, math.min(#rows, vim.o.lines - preview_h - 10))
  local total_h = list_h + 1 + (preview_h > 0 and preview_h + 2 or 0)
  local row0 = math.max(1, math.floor((vim.o.lines - total_h) / 2) - 1)
  local col0 = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    vim.tbl_map(function(r)
      return r.text
    end, rows)
  )
  vim.bo[buf].modifiable = false
  local ns = vim.api.nvim_create_namespace("kube_table")
  for i, r in ipairs(rows) do
    if r.hl then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = #r.text, hl_group = r.hl })
    end
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row0,
    col = col0,
    width = width,
    height = list_h + 1,
    border = "rounded",
    style = "minimal",
    title = " " .. opts.title .. " ",
    title_pos = "center",
    footer = opts.footer and (" " .. opts.footer .. " ") or nil,
    footer_pos = "center",
  })
  vim.wo[win].winbar = "%#Title#" .. opts.header:gsub("%%", "%%%%")
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false

  local pbuf, pwin
  if preview_h > 0 then
    pbuf = vim.api.nvim_create_buf(false, true)
    vim.bo[pbuf].bufhidden = "wipe"
    pwin = vim.api.nvim_open_win(pbuf, false, {
      relative = "editor",
      row = row0 + list_h + 3,
      col = col0,
      width = width,
      height = preview_h,
      border = "rounded",
      style = "minimal",
      focusable = false,
      title = " details ",
      title_pos = "left",
    })
  end

  local cache = {}
  local function current()
    return rows[vim.api.nvim_win_get_cursor(win)[1]]
  end
  local function update_preview()
    if not pbuf then
      return
    end
    local r = current()
    if not r then
      return
    end
    cache[r.value] = cache[r.value] or opts.preview(r.value)
    vim.bo[pbuf].modifiable = true
    vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, cache[r.value])
    vim.bo[pbuf].modifiable = false
  end
  local function close()
    for _, w in ipairs({ win, pwin }) do
      if w and vim.api.nvim_win_is_valid(w) then
        vim.api.nvim_win_close(w, true)
      end
    end
  end

  if opts.cursor and opts.cursor >= 1 and opts.cursor <= #rows then
    vim.api.nvim_win_set_cursor(win, { opts.cursor, 0 })
  end
  update_preview()
  vim.api.nvim_create_autocmd("CursorMoved", { buffer = buf, callback = update_preview })
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = close })

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  map("<CR>", function()
    local r = current()
    close()
    if r then
      opts.on_select(r.value)
    end
  end)
  map("q", close)
  map("<Esc>", close)
  for lhs, fn in pairs(opts.keys or {}) do
    map(lhs, function()
      local r = current()
      close()
      fn(r and r.value)
    end)
  end
end

-- Switch kubeconfig for this nvim instance (terminals opened from nvim inherit it).
-- Rows come pre-aligned from `kcfg-info --list` - same table as `kcfg` in zsh.
function M.select_kubeconfig()
  if not have("kcfg-info") then
    return
  end
  -- one call: aligned table + details for every row (cached by kcfg-info, ~70 ms)
  local res = run({ "kcfg-info", "--picker" }, { timeout = 10000 })
  local ok, data = pcall(vim.json.decode, res.code == 0 and res.stdout or "")
  if not ok or type(data) ~= "table" or #(data.rows or {}) == 0 then
    return notify("No kubeconfigs in ~/.kube/configs (add one with kcfg-add in zsh)", vim.log.levels.WARN)
  end
  local rows, details, cursor = {}, {}, 1
  for _, r in ipairs(data.rows) do
    local flags = r.text:sub(1, 4)
    local hl = flags:find("P") and "DiagnosticError" or (flags:find("%*") and "DiagnosticOk") or nil
    table.insert(rows, { text = r.text, value = r.path, hl = hl })
    details[r.path] = r.details
    if flags:find("%*") then
      cursor = #rows
    end
  end
  table_picker({
    title = "Kubeconfig (this nvim only)   * active  D default  P prod  ! warnings",
    header = data.header,
    rows = rows,
    cursor = cursor,
    footer = "<CR> select   r reset to default   / search   q close",
    preview = function(path)
      return details[path] or {}
    end,
    on_select = function(path)
      vim.env.KUBECONFIG = path
      M.after_kubeconfig_switch()
    end,
    keys = {
      r = function()
        vim.env.KUBECONFIG = nil
        M.after_kubeconfig_switch()
      end,
    },
  })
end

function M.after_kubeconfig_switch()
  M.refresh_state()
  notify(
    string.format(
      "Kubeconfig: %s\nContext: %s/%s\nServer: %s",
      M.kubeconfig_name() or "?",
      M.state.context or "?",
      M.state.namespace or "?",
      M.state.server or "?"
    ),
    M.is_prod() and vim.log.levels.WARN or vim.log.levels.INFO
  )
end

function M.select_namespace()
  if not have("kubectl") then
    return
  end
  local res = kubectl({ "get", "namespaces", "-o", 'jsonpath={range .items[*]}{.metadata.name}{"\\n"}{end}' })
  if res.code ~= 0 then
    return notify(err_of(res), vim.log.levels.ERROR)
  end
  vim.ui.select(lines_of(res.stdout), { prompt = "Namespace" }, function(choice)
    if not choice then
      return
    end
    local r = kubectl({ "config", "set-context", "--current", "--namespace", choice })
    M.refresh_state()
    notify(r.code == 0 and ("Namespace: " .. choice) or err_of(r))
  end)
end

-- Resource lists ------------------------------------------------------------------

local function list_names(kind, cb)
  local res = kubectl({ "get", kind, "-o", "name" })
  if res.code ~= 0 then
    return notify(err_of(res), vim.log.levels.ERROR)
  end
  local items = vim.tbl_filter(function(l)
    return l ~= ""
  end, lines_of(res.stdout))
  if #items == 0 then
    return notify("No resources: " .. kind .. " (ns: " .. (M.state.namespace or "?") .. ")")
  end
  cb(items)
end

local function pick_pod(cb)
  M.refresh_state()
  local res = kubectl({ "get", "pods", "-o", "json" })
  if res.code ~= 0 then
    return notify(err_of(res), vim.log.levels.ERROR)
  end
  local ok, data = pcall(vim.json.decode, res.stdout)
  if not ok or #data.items == 0 then
    return notify("No pods in ns " .. (M.state.namespace or "?"))
  end
  vim.ui.select(data.items, {
    prompt = "Pod (" .. (M.state.namespace or "") .. ")",
    format_item = function(p)
      local restarts = 0
      for _, cs in ipairs(p.status.containerStatuses or {}) do
        restarts = restarts + (cs.restartCount or 0)
      end
      return string.format("%-55s %-10s restarts: %d", p.metadata.name, p.status.phase or "?", restarts)
    end,
  }, function(pod)
    if not pod then
      return
    end
    local containers = vim.tbl_map(function(c)
      return c.name
    end, pod.spec.containers)
    if #containers == 1 then
      return cb(pod.metadata.name, containers[1])
    end
    vim.ui.select(containers, { prompt = "Container" }, function(c)
      if c then
        cb(pod.metadata.name, c)
      end
    end)
  end)
end

function M.logs()
  if not have("kubectl") then
    return
  end
  pick_pod(function(pod, container)
    terminal({ "kubectl", "logs", "-f", "--tail", "500", pod, "-c", container })
  end)
end

function M.exec()
  if not have("kubectl") then
    return
  end
  pick_pod(function(pod, container)
    local ctx = confirm("kubectl exec into " .. pod .. " (" .. container .. ")")
    if not ctx then
      return
    end
    terminal({
      "kubectl",
      "--context",
      ctx,
      "exec",
      "-it",
      pod,
      "-c",
      container,
      "--",
      "sh",
      "-c",
      "command -v bash >/dev/null && exec bash || exec sh",
    }, { win = { position = "float" } })
  end)
end

function M.events()
  if not have("kubectl") then
    return
  end
  vim.ui.select({ "current namespace", "all namespaces" }, { prompt = "Events" }, function(c)
    if not c then
      return
    end
    local args = { "events" }
    if c:match("^all") then
      table.insert(args, "-A")
    end
    show_result("events", kubectl(args, { timeout = 30000 }), "text")
  end)
end

function M.top()
  if not have("kubectl") then
    return
  end
  local nodes = kubectl({ "top", "nodes" })
  local pods = kubectl({ "top", "pods", "--sort-by", "memory" })
  if nodes.code ~= 0 and pods.code ~= 0 then
    return notify("kubectl top (requires metrics-server):\n" .. err_of(nodes), vim.log.levels.ERROR)
  end
  local out = { "# Nodes" }
  vim.list_extend(out, lines_of(nodes.code == 0 and nodes.stdout or err_of(nodes)))
  vim.list_extend(out, { "", "# Pods (" .. (M.state.namespace or "") .. ", by memory)" })
  vim.list_extend(out, lines_of(pods.code == 0 and pods.stdout or err_of(pods)))
  scratch("top", out, "text")
end

-- Edit a resource in a buffer: :w = kubectl replace (with confirmation)
local function edit_resource(name)
  M.refresh_state()
  local ctx, ns, kcfg = M.state.context, M.state.namespace, M.state.kubeconfig
  local res = kubectl({ "--context", ctx, "get", name, "-o", "yaml" })
  if res.code ~= 0 then
    return notify(err_of(res), vim.log.levels.ERROR)
  end
  vim.cmd("botright vnew")
  local buf = vim.api.nvim_get_current_buf()
  scratch_id = scratch_id + 1
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  pcall(vim.api.nvim_buf_set_name, buf, string.format("kube://%s/%s/%s.yaml", ctx, ns, name))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines_of(res.stdout))
  vim.bo[buf].modified = false
  vim.bo[buf].filetype = "yaml"
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      M.refresh_state()
      if M.state.kubeconfig ~= kcfg then
        return notify(
          "Kubeconfig changed to "
            .. tostring(M.state.kubeconfig)
            .. " - save refused (this buffer belongs to "
            .. kcfg
            .. ")",
          vim.log.levels.ERROR
        )
      end
      if M.state.context ~= ctx then
        return notify(
          "Context changed to " .. tostring(M.state.context) .. " - save refused (this buffer belongs to " .. ctx .. ")",
          vim.log.levels.ERROR
        )
      end
      if not confirm("kubectl replace: " .. name) then
        return
      end
      local r = kubectl({ "--context", ctx, "replace", "-f", "-" }, { stdin = buffer_text() })
      if r.code ~= 0 then
        return notify("replace:\n" .. err_of(r), vim.log.levels.ERROR)
      end
      notify(vim.trim(r.stdout))
      local fresh = kubectl({ "--context", ctx, "get", name, "-o", "yaml" })
      if fresh.code == 0 then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines_of(fresh.stdout))
      end
      vim.bo[buf].modified = false
    end,
  })
  notify("Editing " .. name .. " [" .. ctx .. "] - :w writes to the cluster")
end

local resource_types = {
  "pods",
  "deployments",
  "statefulsets",
  "daemonsets",
  "services",
  "ingresses",
  "configmaps",
  "secrets",
  "jobs",
  "cronjobs",
  "persistentvolumeclaims",
  "horizontalpodautoscalers",
  "serviceaccounts",
  "roles",
  "rolebindings",
  "networkpolicies",
  "nodes",
  "namespaces",
  "persistentvolumes",
  "storageclasses",
  "customresourcedefinitions",
  "other (type it)...",
}

local function resource_actions(name)
  local actions = { "describe", "yaml", "edit (:w = replace)", "events" }
  if name:match("^pod/") then
    vim.list_extend(actions, { "logs", "exec" })
  end
  table.insert(actions, "⛔ delete")
  vim.ui.select(actions, { prompt = name }, function(a)
    if not a then
      return
    end
    if a == "describe" then
      show_result("describe " .. name, kubectl({ "describe", name }), "yaml")
    elseif a == "yaml" then
      show_result(name, kubectl({ "get", name, "-o", "yaml" }), "yaml")
    elseif a:match("^edit") then
      edit_resource(name)
    elseif a == "events" then
      show_result("events " .. name, kubectl({ "events", "--for", name }), "text")
    elseif a == "logs" then
      terminal({ "kubectl", "logs", "-f", "--tail", "500", "--all-containers", name })
    elseif a == "exec" then
      local ctx = confirm("kubectl exec into " .. name)
      if ctx then
        terminal({
          "kubectl",
          "--context",
          ctx,
          "exec",
          "-it",
          name,
          "--",
          "sh",
          "-c",
          "command -v bash >/dev/null && exec bash || exec sh",
        }, { win = { position = "float" } })
      end
    elseif a:match("delete") then
      local ctx = confirm("⛔ kubectl DELETE " .. name)
      if ctx then
        local r = kubectl({ "--context", ctx, "delete", name }, { timeout = 120000 })
        notify(
          r.code == 0 and vim.trim(r.stdout) or err_of(r),
          r.code == 0 and vim.log.levels.WARN or vim.log.levels.ERROR
        )
      end
    end
  end)
end

function M.browse()
  if not have("kubectl") then
    return
  end
  M.refresh_state()
  vim.ui.select(resource_types, { prompt = "Resources (ns: " .. (M.state.namespace or "?") .. ")" }, function(kind)
    if not kind then
      return
    end
    local function go(k)
      list_names(k, function(items)
        vim.ui.select(items, { prompt = k }, function(name)
          if name then
            resource_actions(name)
          end
        end)
      end)
    end
    if kind:match("^other") then
      vim.ui.input({ prompt = "Resource type (e.g. applications.argoproj.io): " }, function(k)
        if k and k ~= "" then
          go(k)
        end
      end)
    else
      go(kind)
    end
  end)
end

-- Rollout -----------------------------------------------------------------------

function M.rollout()
  if not have("kubectl") then
    return
  end
  M.refresh_state()
  list_names("deployments,statefulsets,daemonsets", function(items)
    vim.ui.select(items, { prompt = "Rollout" }, function(name)
      if not name then
        return
      end
      vim.ui.select({ "status (live)", "history", "restart", "undo" }, { prompt = name }, function(a)
        if not a then
          return
        end
        if a:match("^status") then
          terminal({ "kubectl", "rollout", "status", name })
        elseif a == "history" then
          show_result("history " .. name, kubectl({ "rollout", "history", name }), "text")
        else
          local sub = a == "restart" and "restart" or "undo"
          local ctx = confirm("kubectl rollout " .. sub .. " " .. name)
          if not ctx then
            return
          end
          local r = kubectl({ "--context", ctx, "rollout", sub, name })
          notify(
            r.code == 0 and vim.trim(r.stdout) or err_of(r),
            r.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
          )
        end
      end)
    end)
  end)
end

-- Secret (decoded, in memory only) ------------------------------------------------

function M.secret()
  if not have("kubectl") then
    return
  end
  M.refresh_state()
  list_names("secrets", function(items)
    vim.ui.select(items, { prompt = "Secret" }, function(name)
      if not name then
        return
      end
      local res = kubectl({ "get", name, "-o", "json" })
      if res.code ~= 0 then
        return notify(err_of(res), vim.log.levels.ERROR)
      end
      local ok, obj = pcall(vim.json.decode, res.stdout)
      if not ok then
        return notify("Failed to read the secret", vim.log.levels.ERROR)
      end
      local out = {
        "# "
          .. name
          .. "  ["
          .. (M.state.context or "?")
          .. "/"
          .. (M.state.namespace or "?")
          .. "]  type: "
          .. (obj.type or "?"),
        "# In-memory buffer only (no file/swap/undo). Don't select text while Claude is connected.",
        "",
      }
      local keys = vim.tbl_keys(obj.data or {})
      table.sort(keys)
      for _, k in ipairs(keys) do
        local okd, val = pcall(vim.base64.decode, obj.data[k])
        val = okd and val or "<cannot decode>"
        val = val:gsub("\n$", "")
        if val:find("\n") or not val:match("^[%g ]*$") then
          table.insert(out, k .. ": |")
          for _, l in ipairs(vim.split(val, "\n", { plain = true })) do
            table.insert(out, "  " .. l)
          end
        else
          table.insert(out, k .. ": " .. val)
        end
      end
      scratch("secret " .. name, out, "yaml", { secret = true })
    end)
  end)
end

-- Port-forward ------------------------------------------------------------------

M.forwards = {}

function M.port_forward()
  if not have("kubectl") then
    return
  end
  local items = {}
  for id, f in pairs(M.forwards) do
    table.insert(items, { id = id, label = "■ stop: " .. f.target .. " " .. f.ports .. " [" .. f.ctx .. "]" })
  end
  table.insert(items, { label = "+ new port-forward" })
  vim.ui.select(items, {
    prompt = "Port-forward",
    format_item = function(i)
      return i.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    if choice.id then
      vim.fn.jobstop(choice.id)
      return
    end
    M.refresh_state()
    list_names("services,pods", function(targets)
      vim.ui.select(targets, { prompt = "Target" }, function(target)
        if not target then
          return
        end
        vim.ui.input({ prompt = "Ports local:remote (e.g. 8080:80): " }, function(ports)
          if not ports or ports == "" then
            return
          end
          local ctx = M.state.context
          local id = vim.fn.jobstart({ "kubectl", "--context", ctx, "port-forward", target, ports }, {
            on_exit = function(jid, code)
              M.forwards[jid] = nil
              vim.schedule(function()
                notify("port-forward ended: " .. target .. " " .. ports .. " (code " .. code .. ")")
              end)
            end,
          })
          if id > 0 then
            M.forwards[id] = { target = target, ports = ports, ctx = ctx }
            notify("port-forward: localhost:" .. ports:match("^(%d+)") .. " → " .. target)
          end
        end)
      end)
    end)
  end)
end

-- Nodes ---------------------------------------------------------------------------

function M.nodes()
  if not have("kubectl") then
    return
  end
  list_names("nodes", function(items)
    vim.ui.select(items, { prompt = "Node" }, function(node)
      if not node then
        return
      end
      local n = node:gsub("^node/", "")
      vim.ui.select({ "describe", "top", "cordon", "uncordon", "drain" }, { prompt = n }, function(a)
        if not a then
          return
        end
        if a == "describe" then
          show_result("describe " .. node, kubectl({ "describe", node }), "yaml")
        elseif a == "top" then
          show_result("top " .. n, kubectl({ "top", "node", n }), "text")
        else
          local ctx = confirm("kubectl " .. a .. " " .. n)
          if not ctx then
            return
          end
          if a == "drain" then
            terminal({ "kubectl", "--context", ctx, "drain", n, "--ignore-daemonsets", "--delete-emptydir-data" })
          else
            local r = kubectl({ "--context", ctx, a, n })
            notify(
              r.code == 0 and vim.trim(r.stdout) or err_of(r),
              r.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
            )
          end
        end
      end)
    end)
  end)
end

-- Helm / kustomize --------------------------------------------------------------

local function chart_root()
  local root = vim.fs.root(0, "Chart.yaml")
  if not root then
    notify("Not inside a Helm chart (no Chart.yaml found)", vim.log.levels.WARN)
  end
  return root
end

local function helm_template_args(root)
  local args = { "helm", "template", "preview", root }
  local file = vim.api.nvim_buf_get_name(0)
  local fname = vim.fn.fnamemodify(file, ":t")
  if fname:match("^values.*%.ya?ml$") and file ~= root .. "/values.yaml" then
    vim.list_extend(args, { "-f", file })
  end
  return args
end

function M.helm_template()
  if not have("helm") then
    return
  end
  local root = chart_root()
  if not root then
    return
  end
  show_result(
    "helm template " .. vim.fn.fnamemodify(root, ":t"),
    run(helm_template_args(root), { timeout = 60000 }),
    "yaml"
  )
end

function M.helm_validate()
  if not have("helm") then
    return
  end
  local root = chart_root()
  if not root then
    return
  end
  local out = { "# helm lint " .. root }
  local lint = run({ "helm", "lint", root }, { timeout = 60000 })
  vim.list_extend(out, lines_of(lint.stdout .. lint.stderr))
  local tpl = run(helm_template_args(root), { timeout = 60000 })
  table.insert(out, "")
  if tpl.code ~= 0 then
    table.insert(out, "# helm template - error:")
    vim.list_extend(out, lines_of(tpl.stderr))
  elseif vim.fn.executable("kubeconform") == 1 then
    table.insert(out, "# kubeconform (K8s + CRD schemas)")
    local kc = run(M.kubeconform_cmd({ "-summary", "-output", "text" }), { stdin = tpl.stdout, timeout = 60000 })
    vim.list_extend(out, lines_of(kc.stdout .. kc.stderr))
  end
  if tpl.code == 0 and vim.fn.executable("kube-linter") == 1 then
    table.insert(out, "")
    table.insert(out, "# kube-linter (best practices)")
    local kl = run({ "kube-linter", "lint", root }, { timeout = 60000 })
    vim.list_extend(out, lines_of(kl.stdout .. kl.stderr))
  end
  scratch("helm validate", out, "text")
end

function M.kustomize()
  if not have("kubectl") then
    return
  end
  local root = vim.fs.root(0, { "kustomization.yaml", "kustomization.yml", "Kustomization" })
  if not root then
    return notify("No kustomization.yaml found above the current file", vim.log.levels.WARN)
  end
  show_result(
    "kustomize " .. vim.fn.fnamemodify(root, ":t"),
    kubectl({ "kustomize", root }, { timeout = 60000 }),
    "yaml"
  )
end

-- Schemas (yamlls) and validation (kubeconform) ------------------------------------

-- API groups built into Kubernetes (everything else is a CRD)
local builtin_groups = {
  [""] = true,
  apps = true,
  batch = true,
  autoscaling = true,
  policy = true,
  ["networking.k8s.io"] = true,
  ["rbac.authorization.k8s.io"] = true,
  ["storage.k8s.io"] = true,
  ["admissionregistration.k8s.io"] = true,
  ["apiextensions.k8s.io"] = true,
  ["scheduling.k8s.io"] = true,
  ["coordination.k8s.io"] = true,
  ["node.k8s.io"] = true,
  ["discovery.k8s.io"] = true,
  ["flowcontrol.apiserver.k8s.io"] = true,
  ["certificates.k8s.io"] = true,
  ["apiregistration.k8s.io"] = true,
  ["events.k8s.io"] = true,
  ["resource.k8s.io"] = true,
}

M.crd_catalog = "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main"
M.k8s_schemas = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict"

local function schema_url(api_version, kind)
  local group, version = api_version:match("^(.+)/(.+)$")
  if not group then
    group, version = "", api_version
  end
  if builtin_groups[group] then
    local g = group ~= "" and ("-" .. group:match("^[^.]+")) or ""
    return string.format("%s/%s%s-%s.json", M.k8s_schemas, kind:lower(), g, version)
  end
  return string.format("%s/%s/%s_%s.json", M.crd_catalog, group, kind:lower(), version)
end

-- Inserts `# yaml-language-server: $schema=...` for the document under the cursor:
-- yamlls completion and validation for CRDs too (ArgoCD, cert-manager, Istio...).
function M.set_schema()
  local doc = current_document(0)
  if not (doc.apiVersion and doc.kind) then
    return notify("No apiVersion/kind in the document under the cursor", vim.log.levels.WARN)
  end
  local line = "# yaml-language-server: $schema=" .. schema_url(doc.apiVersion, doc.kind)
  local first = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
  if first:match("^# yaml%-language%-server: %$schema=") then
    vim.api.nvim_buf_set_lines(0, 0, 1, false, { line })
  else
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { line })
  end
  notify("Schema: " .. doc.kind .. " (" .. doc.apiVersion .. ")")
end

-- kubeconform command: K8s schemas + CRD catalog, local cache
function M.kubeconform_cmd(extra)
  local cache = vim.fn.stdpath("cache") .. "/kubeconform"
  vim.fn.mkdir(cache, "p")
  local cmd = {
    "kubeconform",
    "-strict",
    "-ignore-missing-schemas",
    "-cache",
    cache,
    "-schema-location",
    "default",
    "-schema-location",
    M.crd_catalog .. "/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json",
  }
  vim.list_extend(cmd, extra or {})
  table.insert(cmd, "-")
  return cmd
end

-- First line with `key:` (also as a list item `- key:`)
local function find_key(lines, key, value)
  local pat = "^%s*%-?%s*" .. vim.pesc(key) .. ":"
  if value then
    pat = pat .. "%s*[\"']?" .. vim.pesc(value) .. "[\"']?%s*$"
  end
  for i, l in ipairs(lines) do
    if l:match(pat) then
      return i - 1
    end
  end
end

-- Buffer line for a kubeconform error (JSON path, e.g. /spec/replicas)
local function line_for_error(lines, path, msg)
  local extra = (msg or ""):match("additional propert[a-z]* '([^']+)'")
  if extra then
    local l = find_key(lines, extra)
    if l then
      return l
    end
  end
  local last
  for seg in (path or ""):gmatch("[^/]+") do
    if not seg:match("^%d+$") then
      last = seg
    end
  end
  return last and find_key(lines, last) or 0
end

-- Registers nvim-lint linters: kubeconform (schemas) and kube_linter (practices)
function M.register_linters(lint)
  lint.linters.kubeconform = function()
    local cmd = M.kubeconform_cmd({ "-output", "json" })
    return {
      cmd = cmd[1],
      args = vim.list_slice(cmd, 2),
      stdin = true,
      append_fname = false,
      ignore_exitcode = true,
      stream = "stdout",
      parser = function(output, bufnr)
        local ok, data = pcall(vim.json.decode, output)
        if not ok or type(data) ~= "table" then
          return {}
        end
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local diags = {}
        for _, r in ipairs(data.resources or {}) do
          if r.status == "statusInvalid" or r.status == "statusError" then
            local errs = r.validationErrors
            if type(errs) ~= "table" or #errs == 0 then
              errs = { { path = "", msg = r.msg } }
            end
            for _, e in ipairs(errs) do
              local lnum = line_for_error(lines, e.path, e.msg)
              table.insert(diags, {
                lnum = lnum,
                col = 0,
                severity = vim.diagnostic.severity.ERROR,
                source = "kubeconform",
                message = string.format(
                  "%s/%s: %s%s",
                  r.kind or "?",
                  r.name or "?",
                  e.path ~= "" and (e.path .. ": ") or "",
                  e.msg or ""
                ),
              })
            end
          end
        end
        return diags
      end,
    }
  end

  lint.linters.kube_linter = {
    cmd = "kube-linter",
    args = { "lint", "--format", "json" },
    stdin = false,
    append_fname = true,
    ignore_exitcode = true,
    stream = "stdout",
    parser = function(output, bufnr)
      local ok, data = pcall(vim.json.decode, output)
      if not ok or type(data) ~= "table" then
        return {}
      end
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local diags = {}
      for _, r in ipairs(data.Reports or {}) do
        local obj = r.Object and r.Object.K8sObject or {}
        local name = obj.Name or "?"
        local msg = (r.Diagnostic or {}).Message or ""
        local container = msg:match('container "([^"]+)"')
        local lnum = (container and find_key(lines, "name", container)) or find_key(lines, "name", name) or 0
        table.insert(diags, {
          lnum = lnum,
          col = 0,
          severity = vim.diagnostic.severity.WARN,
          source = "kube-linter",
          code = r.Check,
          message = string.format("%s: %s\n→ %s", name, msg, r.Remediation or ""),
        })
      end
      return diags
    end,
  }
end

-- On-demand validation: kubeconform + kube-linter for the current file
function M.validate()
  if not M.is_manifest(0) then
    return notify("This doesn't look like a K8s manifest", vim.log.levels.WARN)
  end
  local names = vim.tbl_filter(function(n)
    return vim.fn.executable(n == "kube_linter" and "kube-linter" or n) == 1
  end, { "kubeconform", "kube_linter" })
  require("lint").try_lint(names)
  notify("Validating: " .. table.concat(names, ", ") .. " - results in diagnostics (]d, <leader>xx)")
end

-- Setup -------------------------------------------------------------------------

function M.setup()
  M.refresh_state(true)
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("user_kube_state", { clear = true }),
    callback = function()
      M.refresh_state(true)
    end,
  })

  -- K in manifests = kubectl explain (fallback: LSP hover)
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("user_kube_explain", { clear = true }),
    pattern = { "yaml" },
    callback = function(ev)
      vim.keymap.set("n", "K", function()
        if M.is_manifest(ev.buf) then
          M.explain()
        else
          vim.lsp.buf.hover()
        end
      end, { buffer = ev.buf, desc = "Docs (kubectl explain / LSP)" })
    end,
  })

  local map = function(lhs, fn, desc, mode)
    vim.keymap.set(mode or "n", lhs, fn, { desc = desc })
  end
  map("<leader>kf", M.select_kubeconfig, "Switch kubeconfig (this nvim only)")
  map("<leader>kc", M.select_context, "Switch context")
  map("<leader>kn", M.select_namespace, "Switch namespace")
  map("<leader>kd", M.diff, "Diff file/selection against cluster", { "n", "x" })
  map("<leader>ka", M.apply, "Apply file/selection", { "n", "x" })
  map("<leader>kD", M.delete_file, "Delete resources in file/selection", { "n", "x" })
  map("<leader>kg", M.browse, "Browse resources (describe/yaml/edit/...)")
  map("<leader>kl", M.logs, "Pod logs")
  map("<leader>kx", M.exec, "Exec into pod")
  map("<leader>ke", M.events, "Events")
  map("<leader>kt", M.top, "Top (nodes/pods)")
  map("<leader>kr", M.rollout, "Rollout (status/history/restart/undo)")
  map("<leader>ks", M.secret, "Show Secret (decoded)")
  map("<leader>kp", M.port_forward, "Port-forward")
  map("<leader>kN", M.nodes, "Nodes (cordon/drain/...)")
  map("<leader>kh", M.helm_template, "Helm template")
  map("<leader>kH", M.helm_validate, "Helm lint + validate")
  map("<leader>kk", M.kustomize, "Kustomize build")
  map("<leader>kS", M.set_schema, "Set yamlls schema (CRDs too)")
  map("<leader>kv", M.validate, "Validate manifest (kubeconform + kube-linter)")
  map("<leader>kK", M.explain, "kubectl explain under cursor")
  map("<leader>k9", function()
    if have("k9s") then
      Snacks.terminal("k9s", { win = { position = "float", width = 0.95, height = 0.95 } })
    end
  end, "k9s")
end

return M

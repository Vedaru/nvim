--- Lightweight session manager.
--- Session files: stdpath("state")/sessions/%home%user%proj.vim
--- Uses only :mksession + :source + stdlib — no plugin dependencies.

local M = {}

-- ── Path utilities ───────────────────────────────────────────────────────────

function M.session_dir()
  return vim.fn.stdpath("state") .. "/sessions/"
end

--- "/home/user/proj" → "%home%user%proj"
function M.encode(dir)
  return (dir:gsub("[/\\]+", "%%")):gsub("^%%", "")
end

--- "%home%user%proj.vim" → "/home/user/proj"
function M.decode(name)
  name = vim.fn.fnamemodify(name, ":t"):gsub("%.vim$", "")
  local path = "/" .. name:gsub("%%", "/")
  if path:match("^/(%w)/") then
    path = path:gsub("^/(%w)/", "%1:/") -- Windows drive letter fix
  end
  return path
end

--- Session file path for a directory, optionally with git-branch suffix.
function M.file_for(dir, opts)
  opts = opts or {}
  local name = M.encode(dir)
  if opts.branch ~= false then
    local br = vim.fn.systemlist("git branch --show-current", dir)[1] or ""
    if br ~= "" and br ~= "main" and br ~= "master" then
      name = name .. "%%" .. br:gsub("[/\\]+", "%%")
    end
  end
  return M.session_dir() .. name .. ".vim"
end

--- Git root of buffer > buffer dir > git root of cwd > cwd > $HOME.
function M.project_root()
  local buf = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "" and buf ~= "" then
    local root = vim.fs.root(buf, { ".git" })
    return root or vim.fn.fnamemodify(buf, ":h")
  end
  local root = vim.fs.root(vim.fn.getcwd(), { ".git" })
  return root or vim.fn.getcwd() or vim.fn.expand("~")
end

--- All readable session files, newest first.
function M.list()
  local dir = M.session_dir()
  local files = vim.fn.glob(dir .. "*.vim", false, true)
  if type(files) ~= "table" then
    files = {}
  end
  table.sort(files, function(a, b)
    local ma = (vim.uv.fs_stat(a) or {}).mtime or 0
    local mb = (vim.uv.fs_stat(b) or {}).mtime or 0
    return ma > mb
  end)
  return files
end

function M.is_sessions_dir(path)
  if not path then
    return false
  end
  local a = path:gsub("\\", "/"):gsub("/+$", "")
  local b = M.session_dir():gsub("\\", "/"):gsub("/+$", "")
  return a == b
end

-- ── Buffer / window helpers ──────────────────────────────────────────────────

--- Wipe empty [No Name] buffers left behind by session restore.
function M.cleanup_empty_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_buf_get_name(buf) == ""
      and not vim.bo[buf].modified
      and vim.api.nvim_buf_get_option(buf, "buflisted")
    then
      if #vim.fn.win_findbuf(buf) == 0 then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

--- Close all floating windows so :only doesn't fail with E5601.
function M.close_floating_wins()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative and cfg.relative ~= "" then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

--- Show the best available file buffer. Returns true on success.
function M.show_best_buffer()
  local best, score = nil, -1
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
      and vim.bo[buf].buftype == ""
    then
      local name = vim.api.nvim_buf_get_name(buf)
      local s = 0
      if name ~= "" then
        s = vim.fn.filereadable(name) == 1 and 3
          or vim.fn.filereadable(vim.fn.fnamemodify(name, ":p")) == 1 and 2
          or 1
      end
      if s > score then
        best, score = buf, s
      end
    end
  end
  if best and score > 0 then
    local wins = vim.fn.win_findbuf(best)
    if wins and #wins > 0 then
      vim.api.nvim_set_current_win(wins[1])
    else
      vim.cmd("buffer " .. best)
    end
    return true
  end
  return false
end

--- Open a recognizable file in a project directory.
function M.open_project_fallback(dir)
  if not dir or vim.fn.isdirectory(dir) ~= 1 then
    return false
  end
  vim.cmd("lcd " .. vim.fn.fnameescape(dir))
  for _, pat in ipairs({ "README*", "readme*", "*.md", "*.txt", "package.json", "pyproject.toml", "init.lua" }) do
    local hits = vim.fn.glob(dir .. "/" .. pat, false, true)
    local hit = (type(hits) == "table" and hits[1]) or (type(hits) == "string" and hits ~= "" and hits)
    if hit then
      vim.cmd("edit " .. vim.fn.fnameescape(hit))
      return true
    end
  end
  return false
end

--- Reset line numbers / statuscolumn after session restore clobbers them.
function M.reset_line_numbers()
  vim.schedule(function()
    vim.o.number = true
    vim.o.relativenumber = true
    vim.o.signcolumn = "yes"
    if vim.fn.exists("*LazyVim.statuscolumn") == 1 then
      vim.o.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype ~= "terminal" then
        local o = { scope = "local", win = win }
        vim.api.nvim_set_option_value("number", true, o)
        vim.api.nvim_set_option_value("relativenumber", true, o)
        vim.api.nvim_set_option_value("signcolumn", "yes", o)
        if vim.fn.exists("*LazyVim.statuscolumn") == 1 then
          vim.api.nvim_set_option_value("statuscolumn", [[%!v:lua.LazyVim.statuscolumn()]], o)
        end
      end
    end
    pcall(require, "snacks.statuscolumn")
    vim.cmd("redraw!")
  end)
end

-- ── Event helpers ────────────────────────────────────────────────────────────

local function fire(event)
  vim.api.nvim_exec_autocmds("User", { pattern = "Session" .. event, modeline = false })
end

-- ── Core session operations ──────────────────────────────────────────────────

--- Save current session to disk.
function M.save(opts)
  opts = opts or {}
  local dir = opts.cwd or M.project_root()
  local file = M.file_for(dir)

  -- Refuse to save if no file buffers are open.
  local has_file = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= "" then
      has_file = true
      break
    end
  end
  if not has_file then
    vim.notify("Session not saved: no file buffers open", vim.log.levels.WARN)
    return
  end

  fire("SavePre")
  vim.cmd("mks! " .. vim.fn.fnameescape(file))

  -- Append active-buffer marker so restore_layout can focus it.
  local active = vim.api.nvim_buf_get_name(0)
  if active ~= "" then
    local f = io.open(file, "a")
    if f then
      f:write("let g:session_active_buffer = " .. vim.fn.string(active) .. "\n")
      f:close()
    end
  end
  fire("SavePost")
end

--- Restore layout after a session has been sourced.
local function restore_layout(dir)
  vim.o.winheight = 1
  vim.o.winwidth = 20
  vim.o.winminheight = 0
  vim.o.winminwidth = 0
  vim.o.laststatus = 3

  if #vim.api.nvim_list_wins() == 0 then
    vim.cmd("enew")
  end

  local cur = vim.api.nvim_buf_get_name(0)
  if cur == "" or vim.fn.filereadable(cur) == 0 then
    if not M.show_best_buffer() and dir then
      M.open_project_fallback(dir)
    end
  end

  -- Restore active buffer from save-time marker.
  local saved = vim.g.session_active_buffer
  if saved and vim.fn.filereadable(saved) == 1 then
    local bufnr = vim.fn.bufnr(saved)
    if bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
      local wins = vim.fn.win_findbuf(bufnr)
      if wins and #wins > 0 then
        vim.api.nvim_set_current_win(wins[1])
      else
        vim.cmd("buffer " .. vim.fn.fnameescape(saved))
      end
    end
  end

  M.cleanup_empty_buffers()

  if vim.bo.buftype == "terminal" then
    if dir then
      M.open_project_fallback(dir)
    else
      vim.cmd("enew")
    end
  end

  if vim.g.colors_name then
    vim.cmd.colorscheme(vim.g.colors_name)
  end

  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and vim.fn.filereadable(name) == 1 then
    pcall(vim.cmd, "doautocmd FileType")
  end

  pcall(function()
    require("mini.statusline").enable()
  end)

  vim.cmd("wincmd =")
  vim.cmd("redraw!")
  vim.cmd("redrawstatus!")
end

--- Prompt user about unsaved changes. Returns true if OK to proceed.
local function confirm_unsaved()
  local unsaved = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        unsaved[#unsaved + 1] = vim.fn.fnamemodify(name, ":~")
      end
    end
  end
  if #unsaved == 0 then
    return true
  end
  local msg = "Unsaved changes:\n  " .. table.concat(unsaved, "\n  ", 1, math.min(#unsaved, 5))
  if #unsaved > 5 then
    msg = msg .. "\n  ... and " .. (#unsaved - 5) .. " more"
  end
  local choice = vim.fn.confirm(msg .. "\n\nSave before switching?", "&Save\n&Discard\n&Cancel")
  if choice == 1 then
    vim.cmd("silent! wa")
    return true
  end
  return choice == 2
end

--- Switch to a session: wipe state, source file, restore layout.
function M.switch(file, opts)
  opts = opts or {}
  if not file or vim.fn.filereadable(file) == 0 then
    vim.notify("Session not found: " .. tostring(file), vim.log.levels.ERROR)
    return
  end
  if not opts.force and not confirm_unsaved() then
    return
  end

  local dir = M.decode(file)
  M.close_floating_wins()
  vim.cmd("silent! tabonly")
  vim.cmd("silent! only")
  vim.cmd("silent! %bdelete!")
  vim.g.session_active_buffer = nil

  fire("LoadPre")
  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(file))
  fire("LoadPost")

  if not ok then
    vim.notify("Session source failed: " .. tostring(err), vim.log.levels.ERROR)
  end
  restore_layout(dir)
end

--- Load session: current project, or last session if opts.last is true.
function M.load(opts)
  opts = opts or {}
  local file
  if opts.last then
    local files = M.list()
    file = files[1]
  else
    file = M.file_for(M.project_root())
    if vim.fn.filereadable(file) == 0 then
      file = M.file_for(M.project_root(), { branch = false })
    end
  end
  if not file or vim.fn.filereadable(file) == 0 then
    vim.notify("No session for this directory", vim.log.levels.WARN)
    return
  end
  M.switch(file)
end

--- Interactive session picker via vim.ui.select.
function M.select()
  local seen, items = {}, {}
  for _, file in ipairs(M.list()) do
    if vim.uv.fs_stat(file) then
      local dir = M.decode(file)
      if not seen[dir] then
        seen[dir] = true
        items[#items + 1] = {
          file = file,
          dir = dir,
          display = vim.fn.fnamemodify(dir, ":~"):gsub("\\", "/"),
        }
      end
    end
  end
  vim.ui.select(items, {
    prompt = "Select a session:",
    format_item = function(item)
      return item.display
    end,
  }, function(item)
    if item then
      M.switch(item.file)
    end
  end)
end

return M

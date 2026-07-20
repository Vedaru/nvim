local M = {}

--- Session dir > git root (from buffer/cwd) > cwd > $HOME
function M.project_root()
  local ok, P = pcall(require, "persistence")
  if ok and P._active_dir and vim.fn.isdirectory(P._active_dir) == 1 then
    return P._active_dir
  end

  local buf = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "" and buf ~= "" then
    local root = vim.fs.root(buf, { ".git" })
    if root then
      return root
    end
    return vim.fn.fnamemodify(buf, ":h")
  end

  local cwd = vim.fn.getcwd()
  if cwd ~= "" then
    local root = vim.fs.root(cwd, { ".git" })
    if root then
      return root
    end
    return cwd
  end

  return vim.fn.expand("~")
end

function M.session_dir()
  return vim.fn.stdpath("state") .. "/sessions/"
end

--- Decode `%home%lenovo%projects%foo` -> `/home/lenovo/projects/foo`
function M.decode_session_path(file)
  local name = vim.fn.fnamemodify(file, ":t"):gsub("%.vim$", "")
  local d = name:gsub("%%", "/")
  if d:match("^home/") then
    d = "/" .. d
  end
  if jit and jit.os:find("Windows") then
    d = d:gsub("^(%w)/", "%1:/")
  end
  return d
end

function M.is_sessions_dir(dir)
  if not dir then
    return false
  end
  local norm = dir:gsub("\\", "/"):gsub("/+$", "")
  local sessions = (vim.fn.stdpath("state") .. "/sessions"):gsub("\\", "/"):gsub("/+$", "")
  return norm == sessions
end

--- Show the best available file buffer (including badd'd buffers not yet in a window).
function M.show_best_buffer()
  local best_buf, best_score = nil, -1
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      local score = 0
      if name ~= "" then
        if vim.fn.filereadable(name) == 1 then
          score = 3
        elseif vim.fn.filereadable(vim.fn.fnamemodify(name, ":p")) == 1 then
          score = 2
        else
          score = 1
        end
      end
      if score > best_score then
        best_buf, best_score = buf, score
      end
    end
  end
  if best_buf and best_score > 0 then
    local wins = vim.fn.win_findbuf(best_buf)
    if wins and #wins > 0 then
      vim.api.nvim_set_current_win(wins[1])
    else
      vim.cmd("buffer " .. best_buf)
    end
    return true
  end
  return false
end

function M.open_project_fallback(dir)
  if not dir or vim.fn.isdirectory(dir) ~= 1 then
    return false
  end
  local e = vim.fn.fnameescape
  vim.cmd("lcd " .. e(dir))
  local patterns = { "README*", "readme*", "*.md", "*.txt", "package.json", "pyproject.toml", "init.lua" }
  for _, pat in ipairs(patterns) do
    local hit = vim.fn.glob(dir .. "/" .. pat, false, true)
    if type(hit) == "table" and hit[1] then
      vim.cmd("edit " .. e(hit[1]))
      return true
    elseif type(hit) == "string" and hit ~= "" then
      vim.cmd("edit " .. e(hit))
      return true
    end
  end
  return false
end

--- Reset line-number display after mks session restore.
function M.reset_line_numbers()
  vim.schedule(function()
    if not vim.fn.exists("*LazyVim.statuscolumn") then
      return
    end
    vim.o.number = true
    vim.o.relativenumber = true
    vim.o.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      vim.api.nvim_win_call(win, function()
        vim.cmd("setlocal statuscolumn&")
        vim.cmd("setlocal number&")
        vim.cmd("setlocal relativenumber&")
        vim.wo.number = true
        vim.wo.relativenumber = true
      end)
    end
    pcall(function()
      require("snacks.statuscolumn").setup()
    end)
    vim.cmd("redraw!")
  end)
end

return M

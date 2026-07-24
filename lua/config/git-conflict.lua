--- Git conflict scanner and navigator.
--- Used by plugins/git-conflict.lua — separated from the plugin spec.

local M = {}

M.all_conflicts = {}
M.qf_files = {}

-- ── File I/O helpers ─────────────────────────────────────────────────────────

local function get_lines(filepath)
  local abs = vim.fn.fnamemodify(filepath, ":p")
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local buf_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
      if buf_path == abs then
        return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      end
    end
  end
  local lines = {}
  local f = io.open(filepath, "r")
  if f then
    for line in f:lines() do
      lines[#lines + 1] = line
    end
    f:close()
  end
  return lines
end

local function has_conflict_markers(abs_path)
  local f = io.open(abs_path, "r")
  if not f then
    return false
  end
  for line in f:lines() do
    if line:match("^<<<<<<< ") then
      f:close()
      return true
    end
  end
  f:close()
  return false
end

-- ── Scanning ─────────────────────────────────────────────────────────────────

function M.build_conflict_list()
  local all_items, qf_items, qf_files = {}, {}, {}
  local seen = {}

  -- 1. git unmerged files
  local handle = io.popen("git diff --name-only --diff-filter=U 2>/dev/null")
  local conflict_files = {}
  if handle then
    for line in handle:lines() do
      if line ~= "" then
        conflict_files[#conflict_files + 1] = line
        seen[line] = true
      end
    end
    handle:close()
  end

  -- 2. fallback: scan tracked files for raw <<<<<<< markers
  if #conflict_files == 0 then
    local h = io.popen("git ls-files 2>/dev/null")
    if h then
      for file in h:lines() do
        if file ~= "" and not seen[file] then
          local abs = vim.fn.fnamemodify(file, ":p")
          if has_conflict_markers(abs) then
            conflict_files[#conflict_files + 1] = file
            seen[file] = true
          end
        end
      end
      h:close()
    end
  end

  table.sort(conflict_files)

  for _, file in ipairs(conflict_files) do
    local abs = vim.fn.fnamemodify(file, ":p")
    local lines = get_lines(abs)
    local file_conflicts, first_lnum = 0, nil

    for n, line in ipairs(lines) do
      if line:match("^<<<<<<< ") then
        file_conflicts = file_conflicts + 1
        if not first_lnum then
          first_lnum = n
        end
        all_items[#all_items + 1] = { filename = abs, lnum = n }
      end
    end

    if file_conflicts > 0 then
      qf_files[#qf_files + 1] = abs
      qf_items[#qf_items + 1] = {
        filename = abs,
        lnum = first_lnum,
        text = string.format("%d conflict(s)", file_conflicts),
        type = "E",
      }
    end
  end

  M.all_conflicts = all_items
  M.qf_files = qf_files
  return all_items, qf_items
end

-- ── Quickfix ─────────────────────────────────────────────────────────────────

local function get_qf_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "qf" then
      return win
    end
  end
end

function M.sync_qf_idx()
  if #M.qf_files == 0 then
    return
  end
  local cur = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":p")
  for i, file in ipairs(M.qf_files) do
    if file == cur then
      pcall(vim.fn.setqflist, {}, "a", { idx = i })
      return
    end
  end
end

function M.update_qf(qf_items, force_open)
  local cur_win = vim.api.nvim_get_current_win()
  vim.fn.setqflist(qf_items, "r")
  local qf_win = get_qf_win()

  if #qf_items > 0 then
    if force_open and not qf_win then
      vim.cmd("botright copen")
      if vim.api.nvim_win_is_valid(cur_win) then
        vim.api.nvim_set_current_win(cur_win)
      end
    end
    M.sync_qf_idx()
  elseif qf_win then
    vim.cmd("cclose")
  end
end

-- ── Refresh ──────────────────────────────────────────────────────────────────

local function refresh_plugin_ui()
  local ok, gc = pcall(require, "git-conflict")
  if not ok then
    return
  end
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      pcall(gc.refresh, bufnr)
    end
  end
end

function M.refresh(force_open)
  refresh_plugin_ui()
  local _, qf_items = M.build_conflict_list()
  M.update_qf(qf_items, force_open)
end

-- ── Navigation ───────────────────────────────────────────────────────────────

function M.navigate(direction)
  M.build_conflict_list()

  if #M.all_conflicts == 0 then
    vim.notify("All conflicts resolved", vim.log.levels.INFO)
    M.refresh(false)
    return
  end

  local cur_file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":p")
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local target_idx

  -- Find next/prev conflict in current file.
  for i, item in ipairs(M.all_conflicts) do
    if item.filename == cur_file then
      if direction == "next" and item.lnum > cur_line then
        target_idx = i
        break
      elseif direction == "prev" and item.lnum < cur_line then
        target_idx = i
      end
    end
  end

  -- Wrap to next/prev file.
  if not target_idx then
    if direction == "next" then
      for i, item in ipairs(M.all_conflicts) do
        if item.filename > cur_file then
          target_idx = i
          break
        end
      end
      target_idx = target_idx or 1
    else
      for i = #M.all_conflicts, 1, -1 do
        if M.all_conflicts[i].filename < cur_file then
          target_idx = i
          break
        end
      end
      target_idx = target_idx or #M.all_conflicts
    end
  end

  local target = M.all_conflicts[target_idx]
  if target.filename ~= cur_file then
    vim.cmd("edit " .. vim.fn.fnameescape(target.filename))
  end
  vim.api.nvim_win_set_cursor(0, { target.lnum, 0 })
  vim.cmd("normal! zz")
  M.refresh(false)
end

return M

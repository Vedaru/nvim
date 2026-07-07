-- ~/.config/nvim/lua/plugins/git-conflict.lua

local M = {}

-- 缓存所有冲突点的列表
M.all_conflicts = {}
-- 缓存当前 Quickfix 中的文件列表，用于快速查找索引
M.qf_files = {}

-- 获取文件内容（优先从 buffer 获取）
local function get_lines(filepath)
  local abs_path = vim.fn.fnamemodify(filepath, ":p")
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local buf_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
      if buf_path == abs_path then
        return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      end
    end
  end

  local lines = {}
  local f = io.open(filepath, "r")
  if f then
    for line in f:lines() do
      table.insert(lines, line)
    end
    f:close()
  end
  return lines
end

-- 核心：扫描所有冲突文件，构建全局冲突点列表
function M.build_conflict_list()
  local all_items = {}
  local qf_items = {}
  local qf_files = {}

  local handle = io.popen("git diff --name-only --diff-filter=U 2>/dev/null")
  if not handle then
    return all_items, qf_items, qf_files
  end

  local conflict_files = {}
  for line in handle:lines() do
    if line ~= "" then
      table.insert(conflict_files, line)
    end
  end
  handle:close()

  table.sort(conflict_files)

  for _, file in ipairs(conflict_files) do
    local abs_path = vim.fn.fnamemodify(file, ":p")
    local lines = get_lines(abs_path)
    local file_conflicts = 0
    local first_lnum = nil

    for n, line_content in ipairs(lines) do
      if line_content:match("^<<<<<<< ") then
        file_conflicts = file_conflicts + 1
        if not first_lnum then
          first_lnum = n
        end
        table.insert(all_items, {
          filename = abs_path,
          lnum = n,
        })
      end
    end

    if file_conflicts > 0 then
      table.insert(qf_files, abs_path)
      table.insert(qf_items, {
        filename = abs_path,
        lnum = first_lnum,
        text = string.format("%d conflict(s)", file_conflicts),
        type = "E",
      })
    end
  end

  M.all_conflicts = all_items
  M.qf_files = qf_files
  return all_items, qf_items
end

-- 调用插件官方刷新逻辑，确保高亮存在且行号正确
local function refresh_plugin_ui()
  local ok, gc = pcall(require, "git-conflict")
  if not ok then
    return
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      -- 使用插件内部方法刷新指定 buffer
      pcall(gc.refresh, bufnr)
    end
  end
end

-- 同步 Quickfix 的高亮行到当前文件
function M.sync_qf_idx()
  if #M.qf_files == 0 then
    return
  end

  local cur_file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":p")
  for i, file in ipairs(M.qf_files) do
    if file == cur_file then
      pcall(vim.fn.setqflist, {}, "a", { idx = i })
      return
    end
  end
end

-- 获取当前的 quickfix 窗口
local function get_qf_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "qf" then
      return win
    end
  end
  return nil
end

-- 更新 Quickfix 窗口
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
  else
    if qf_win then
      vim.cmd("cclose")
    end
  end
end

-- 刷新所有数据
function M.refresh(force_open)
  refresh_plugin_ui() -- 调用插件 API 刷新 UI
  local _, qf_items = M.build_conflict_list()
  M.update_qf(qf_items, force_open)
end

-- 智能跳转逻辑
function M.navigate(direction)
  M.build_conflict_list()

  if #M.all_conflicts == 0 then
    vim.notify("All Conflicts resolved", vim.log.levels.INFO)
    M.refresh(false)
    return
  end

  local cur_file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":p")
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local target_idx = nil

  for i, item in ipairs(M.all_conflicts) do
    if item.filename == cur_file then
      if direction == "next" then
        if item.lnum > cur_line then
          target_idx = i
          break
        end
      else
        if item.lnum < cur_line then
          target_idx = i
        end
      end
    end
  end

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

return {
  {
    "akinsho/git-conflict.nvim",
    keys = {
      {
        "<leader>gC",
        function()
          local qf_win = get_qf_win()
          if qf_win then
            vim.cmd("cclose")
          else
            M.refresh(true)
          end
        end,
        desc = "Git Conflicts (Toggle Quickfix)",
      },
      {
        "]x",
        function()
          M.navigate("next")
        end,
        desc = "Next Conflict (Global)",
      },
      {
        "[x",
        function()
          M.navigate("prev")
        end,
        desc = "Previous Conflict (Global)",
      },
      { ".o", "<Plug>(git-conflict-ours)", desc = "Choose Ours" },
      { ".t", "<Plug>(git-conflict-theirs)", desc = "Choose Theirs" },
      { ".b", "<Plug>(git-conflict-both)", desc = "Choose Both" },
      { ".0", "<Plug>(git-conflict-none)", desc = "Choose None" },
    },
    opts = {
      list_opener = nil,
      default_mappings = false,
    },
    config = function(_, opts)
      require("git-conflict").setup(opts)

      -- 1. 解决冲突后自动刷新
      vim.api.nvim_create_autocmd("User", {
        pattern = "GitConflictResolved",
        callback = function()
          vim.defer_fn(function()
            pcall(M.refresh, false)
          end, 100)
        end,
      })

      -- 2. 保存后刷新
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("GitConflictRefresh", { clear = true }),
        callback = function()
          pcall(M.refresh, false)
        end,
      })

      -- 3. 当进入新文件时同步索引
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("GitConflictSyncQf", { clear = true }),
        callback = function()
          if #M.qf_files > 0 then
            M.sync_qf_idx()
          end
        end,
      })

      -- 4. 修复 E925: 使用手动跳转
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function()
          vim.keymap.set("n", "<CR>", function()
            local line = vim.api.nvim_win_get_cursor(0)[1]
            local qf_list = vim.fn.getqflist()
            local item = qf_list[line]

            if item and item.valid == 1 then
              local filename = vim.api.nvim_buf_get_name(item.bufnr)
              local lnum = item.lnum
              vim.cmd("wincmd p")
              vim.cmd("edit " .. vim.fn.fnameescape(filename))
              vim.api.nvim_win_set_cursor(0, { lnum, 0 })
              vim.cmd("normal! zz")
              pcall(vim.fn.setqflist, {}, "a", { idx = line })
            else
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
            end
          end, { buffer = true, silent = true })
        end,
      })
    end,
  },
}

-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- 这里只放对 LazyVim 默认自动命令的补充

local augroup = function(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- 进入插入模式关闭当前行高亮，离开时恢复，减少视觉干扰
vim.api.nvim_create_autocmd("InsertEnter", {
  group = augroup("cursorline"),
  callback = function()
    vim.opt_local.cursorline = false
  end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  group = augroup("cursorline"),
  callback = function()
    vim.opt_local.cursorline = true
  end,
})

-- 某些大文件关闭重型功能，保持流畅
vim.api.nvim_create_autocmd("BufReadPre", {
  group = augroup("bigfile"),
  callback = function(event)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(event.buf))
    if ok and stats and stats.size > 1024 * 1024 then -- > 1MB
      vim.b[event.buf].large_file = true
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.spell = false
      -- 大文件禁用 treesitter 高亮和 LSP
      vim.b[event.buf].ts_highlight = false
      vim.defer_fn(function()
        local clients = vim.lsp.get_clients({ bufnr = event.buf })
        for _, client in ipairs(clients) do
          client:stop(true)
        end
      end, 10)
    end
  end,
})

-- Makefile / Go 必须用 real tab，不用空格缩进
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("real_tabs"),
  pattern = { "make", "gomod", "go" },
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

-- Tmux: fix rendering glitches when other panes are killed/resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("tmux_resize"),
  pattern = "*",
  command = "redraw!",
})

-- Markdown: 默认完全展开，不按标题折叠
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_unfold"),
  pattern = "markdown",
  callback = function()
    vim.opt_local.foldlevel = 99
  end,
})

vim.api.nvim_create_autocmd("SessionLoadPost", {
  group = augroup("session_line_numbers"),
  callback = function()
    require("config.session").reset_line_numbers()
  end,
})

-- mini.files / oil.nvim: detach LSP from file-browser buffers
-- to prevent "mingled text" warnings and treesitter errors
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("lsp_detach"),
  pattern = { "minifiles", "oil" },
  callback = function(event)
    vim.schedule(function()
      local clients = vim.lsp.get_clients({ bufnr = event.buf })
      for _, client in ipairs(clients) do
        client:stop(true)
      end
    end)
  end,
})

-- snacks_dashboard 光标吸附修复已下沉到 snacks 源码
-- (lua/snacks/dashboard.lua 的 D:init WinEnter autocmd)：
-- 从 Lazy 等浮窗返回 dashboard 时直接 self:update() 重新吸附，
-- 比在 config 里绕 Snacks.dashboard.update() 事件链更稳。
-- build.sh 会把改过的 snacks.nvim 一起打包，重装不丢。
--
-- dashboard 的快捷选项删除 + q -> :qa 也都已下沉到 snacks 源码
-- (defaults.sections 去掉 keys 段、preset.keys 清空、D:init q 改 :qa)，
-- 这里不再需要任何 config 层 workaround。

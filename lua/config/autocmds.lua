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
    end
  end,
})

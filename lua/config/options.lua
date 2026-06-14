-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- 命令行补全弹出菜单，支持方向键和 Ctrl+N/P
vim.opt.wildmenu = true
vim.opt.wildoptions = "pum"        -- 弹出菜单样式
vim.opt.wildmode = "longest:full,full"  -- 先补全最长公共部分，再显示菜单
vim.opt.pumblend = 10              -- 菜单半透明，好看

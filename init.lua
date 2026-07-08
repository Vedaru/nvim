-- mapleader 必须在 mini.clue 注册 trigger 之前就位（lazy 加载插件前设好）
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Use Go-based tsgo LSP instead of Node-based tsserver (10x lighter)
vim.g.lazyvim_ts_lsp = "tsgo"

-- Suppress LazyVim import-order check (we use explicit imports, not the monolithic "lazyvim.plugins")
vim.g.lazyvim_check_order = false
-- 关闭 LazyVim 启动欢迎 / news 弹窗
vim.g.lazyvim_news = false

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- keymaps 由 LazyVim 自动从 lua/config/keymaps.lua 加载，无需手动注册

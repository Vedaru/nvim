-- Use Go-based tsgo LSP instead of Node-based tsserver (10x lighter)
vim.g.lazyvim_ts_lsp = "tsgo"

-- Suppress LazyVim import-order check (we use explicit imports, not the monolithic "lazyvim.plugins")
vim.g.lazyvim_check_order = false
-- 关闭 LazyVim 启动欢迎 / news 弹窗
vim.g.lazyvim_news = false

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load keymaps on VeryLazy (Snacks global is available by then)
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    pcall(require, "config.keymaps")
  end,
})

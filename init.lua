-- mapleader must be set before lazy loads plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.lazyvim_check_order = false
vim.g.lazyvim_news = false

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

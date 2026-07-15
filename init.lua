-- mapleader must be set before lazy loads plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.lazyvim_check_order = false
vim.g.lazyvim_news = false

-- gutentags: add to rtp + set vars BEFORE plugin auto-loads
vim.opt.rtp:prepend(vim.fn.expand("~/.local/share/nvim/site/pack/plugins/start/vim-gutentags"))
vim.g.gutentags_ctags_executable = vim.fn.expand("~/.local/bin/ctags")
vim.g.gutentags_project_root = { ".git", ".hg", ".svn" }
vim.g.gutentags_ctags_tagfile = ".tags"
vim.g.gutentags_exclude_filetypes = {
  "gitcommit", "gitrebase", "help", "markdown",
  "text", "startify", "fugitive", "fugitiveblame",
}
vim.g.gutentags_generate_on_new = true
vim.g.gutentags_generate_on_missing = true
vim.g.gutentags_generate_on_write = true
vim.g.gutentags_generate_on_empty_buffer = false
vim.g.gutentags_cache_dir = vim.fn.expand("~/.cache/gutentags")
vim.g.gutentags_ctags_extra_args = {
  "--fields=+lnS",
  "--extras=+q",
  "--output-format=e-ctags",
}
vim.opt.tags:prepend(vim.fn.expand("~/.cache/gutentags/") .. "/*")

-- bootstrap lazy.nvim
require("config.lazy")

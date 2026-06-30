-- ⚡ Performance: enable Lua bytecode cache (Neovim 0.9+)
-- Cuts startup by caching compiled Lua modules to disk
vim.loader.enable()

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

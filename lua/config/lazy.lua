local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.api.nvim_echo({
    { "lazy.nvim not found at: " .. lazypath, "ErrorMsg" },
    { "\nRun install.sh first (zero-network restore from backup).", "WarningMsg" },
  }, true, {})
  os.exit(1)
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- Only the 6 LazyVim spec files we actually use (shadowed by lua/lazyvim/plugins/*)
    -- down from the original 50+. Formatting, linting, util, xtras, and 40 extras skipped.
    { "LazyVim/LazyVim", import = "lazyvim.plugins.init" },
    { "LazyVim/LazyVim", import = "lazyvim.plugins.ui" },
    { "LazyVim/LazyVim", import = "lazyvim.plugins.editor" },
    { "LazyVim/LazyVim", import = "lazyvim.plugins.colorscheme" },

    -- User plugin overrides
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },

  -- ZERO NETWORK: never check for updates, never auto-install, never auto-update lazy itself
  checker = { enabled = false },
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  change_detection = { enabled = false },
  pkg = { enabled = false },

  -- Git settings: use HTTP (not SSH), never auto-fetch
  git = {
    timeout = 5,
    log = { "-3" },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- 从代码层面删除 Lazy 面板中不需要的命令（零网络模式下无意义）
-- 配合 lazy.nvim 源码补丁（view/init.lua setup_patterns 的 nil 保护），
-- 重装时由 build.sh 把改过的 lazy.nvim 一起打包，所以无需在 Lua 层兜底。
local ViewConfig = require("lazy.view.config")
local removed = { "install", "update", "sync", "clean", "check", "log", "restore", "debug", "reload" }
for _, name in ipairs(removed) do
  ViewConfig.commands[name] = nil
end

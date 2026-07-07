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
    { "LazyVim/LazyVim", import = "lazyvim.plugins.lsp" },

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

-- Override LazyVim treesitter: empty ensure_installed to avoid GFW-blocked tarball downloads
-- Proxy configured in options.lua. Use :TSInstall <lang> manually when needed.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {},
      auto_install = true,
    },
  },
}

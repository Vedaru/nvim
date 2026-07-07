-- Standalone nvim-treesitter — no LazyVim dependency, no textobjects/autotag
-- Proxy for downloads configured in options.lua. Use :TSInstall <lang> manually when needed.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "LazyFile", "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts = {
      ensure_installed = {},
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      folds = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
    end,
  },
}

-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = false,
        virtual_text = false,
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = false,
      ensure_installed = {},
    },
  },
}

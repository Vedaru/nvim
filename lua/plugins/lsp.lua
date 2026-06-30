--~/.config/nvim/lua/plugins/lsp.lua
-- ⚡ LazyVim already lazy-loads LSP on LspAttach — just override opts
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- 去掉下划线，保留其他提示（sign/s虚浮窗）
        underline = false,
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = false,
    },
  },
}

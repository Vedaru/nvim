--~/.config/nvim/lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- 去掉下划线，保留其他提示（sign/s虚浮窗）
        underline = false,
        -- 或只去掉 Error 的下划线，保留 Warning 等
        -- underline = { severity = { min = vim.diagnostic.severity.WARN } },
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

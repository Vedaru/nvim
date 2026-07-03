--~/.config/nvim/lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- 去掉下划线，保留 sign 和 virtual_text
        underline = false,
        virtual_text = false,
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

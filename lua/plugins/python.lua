-- ~/.config/nvim/lua/plugins/python.lua
-- Fix: ruff LSP crashes on buffers without parent paths (oil://, term://, etc.)
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          on_attach = function(client, bufnr)
            local path = vim.api.nvim_buf_get_name(bufnr)
            -- Skip non-file buffers (oil://, term://, etc.) that crash ruff
            if path == "" or vim.startswith(path, "oil://") or vim.startswith(path, "term://") then
              client.stop()
              return
            end
          end,
        },
      },
    },
  },
}

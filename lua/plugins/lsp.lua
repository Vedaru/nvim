-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = false,
        virtual_text = false,
      },
      servers = {
        -- Go-based TS server — no Node.js, no memory caps needed
        tsgo = {
          settings = {
            typescript = {
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = false },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = false },
                propertyDeclarationTypes = { enabled = false },
                variableTypes = { enabled = false },
              },
            },
          },
        },
        -- Pyright: stripped down, only open files, no type-checking fluff
        pyright = {
          settings = {
            python = {
              analysis = {
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "basic",
                autoSearchPaths = false,
                useLibraryCodeForTypes = false,
                autoImportCompletions = false,
                reportMissingImports = false,
                reportMissingTypeStubs = false,
              },
            },
          },
        },
        -- Ruff: skip non-file buffers (oil://, term://) without killing the whole client
        ruff = {
          root_dir = function(fname)
            -- fname can be a string (filename) or a number (bufnr)
            if type(fname) ~= "string" then
              fname = vim.api.nvim_buf_get_name(fname)
            end
            if fname == "" or vim.startswith(fname, "oil://") or vim.startswith(fname, "term://") then
              return nil
            end
            return vim.fs.root(fname, { "pyproject.toml", "ruff.toml", ".git" })
          end,
          on_attach = function(client, bufnr)
            local path = vim.api.nvim_buf_get_name(bufnr)
            if path == "" or vim.startswith(path, "oil://") or vim.startswith(path, "term://") then
              vim.schedule(function()
                pcall(vim.lsp.buf_detach_client, bufnr, client.id)
              end)
            end
          end,
        },
        ts_ls = { enabled = false },
        vtsls = { enabled = false },
        marksman = { enabled = false },
        tailwindcss = { enabled = false },
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

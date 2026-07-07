-- Use Go-based tsgo LSP instead of Node-based tsserver (10x lighter)
vim.g.lazyvim_ts_lsp = "tsgo"

-- Suppress LazyVim import-order check (we use explicit imports, not the monolithic "lazyvim.plugins")
vim.g.lazyvim_check_order = false

-- Check if a session exists for current dir
local session_dir = vim.fn.stdpath("state") .. "/sessions"
local cwd = vim.fn.getcwd()
local session_name = cwd:gsub("[\\/:]+", "%%") .. ".vim"
local has_session = vim.fn.filereadable(session_dir .. "/" .. session_name) == 1

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Restore session or show dashboard
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("startup", { clear = true }),
  nested = true,
  callback = function()
    if vim.fn.argc() ~= 0 then
      return
    end
    vim.schedule(function()
      if has_session then
        local ok, P = pcall(require, "persistence")
        if ok then
          P.load()
        end
      else
        Snacks.dashboard.open()
      end
    end)
  end,
})

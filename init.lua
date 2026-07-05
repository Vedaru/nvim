-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Restore last session on startup (must be in init.lua — VimEnter fires before VeryLazy)
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
  nested = true,
  callback = function()
    if vim.fn.argc() ~= 0 then return end
    local dir = vim.fn.stdpath("state") .. "/sessions"
    local files = vim.fn.glob(dir .. "/*.vim", false, true)
    if #files == 0 then return end
    table.sort(files, function(a, b)
      return vim.fn.getftime(a) > vim.fn.getftime(b)
    end)
    local latest = files[1]
    if vim.fn.filereadable(latest) == 1 then
      vim.cmd("silent! source " .. vim.fn.fnameescape(latest))
    end
  end,
})

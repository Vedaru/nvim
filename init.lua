-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "tokyonight",
  callback = function()
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#a9b1d6", bold = true })
  end,
})

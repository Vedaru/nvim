-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 所有模式统一的窗口导航
for _, mode in ipairs({ "n", "i", "t", "x" }) do
  vim.keymap.set(mode, "<C-h>", "<cmd>wincmd h<cr>", { silent = true, desc = "󰍽 Go to left window" })
  vim.keymap.set(mode, "<C-j>", "<cmd>wincmd j<cr>", { silent = true, desc = "󰍻 Go to lower window" })
  vim.keymap.set(mode, "<C-k>", "<cmd>wincmd k<cr>", { silent = true, desc = "󰍼 Go to upper window" })
  vim.keymap.set(mode, "<C-l>", "<cmd>wincmd l<cr>", { silent = true, desc = "󰍾 Go to right window" })
end

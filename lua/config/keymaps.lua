-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- 这里只放对 LazyVim 默认键位的补充

local map = vim.keymap.set

-- ── 窗口导航：所有模式统一用 Ctrl-h/j/k/l ──────────────────────────
for _, mode in ipairs({ "n", "i", "t", "x" }) do
  map(mode, "<C-h>", "<cmd>wincmd h<cr>", { silent = true, desc = "切换到左窗口" })
  map(mode, "<C-j>", "<cmd>wincmd j<cr>", { silent = true, desc = "切换到下窗口" })
  map(mode, "<C-k>", "<cmd>wincmd k<cr>", { silent = true, desc = "切换到上窗口" })
  map(mode, "<C-l>", "<cmd>wincmd l<cr>", { silent = true, desc = "切换到右窗口" })
end

-- ── 保存 ──────────────────────────────────────────────────────────
map({ "n", "i", "x", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "保存文件" })

-- ── 可视模式缩进后保持选区 ────────────────────────────────────────
map("x", "<", "<gv", { desc = "向左缩进并保持选区" })
map("x", ">", ">gv", { desc = "向右缩进并保持选区" })

-- ── 粘贴时不污染寄存器（可视模式粘贴覆盖后仍可重复粘贴）──────────
map("x", "p", [["_dP]], { desc = "粘贴但不覆盖寄存器" })

-- ── 行内移动：按显示行而非物理行（折行更友好）────────────────────
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- ── 居中滚动 ──────────────────────────────────────────────────────
map("n", "<C-d>", "<C-d>zz", { desc = "下翻半页并居中" })
map("n", "<C-u>", "<C-u>zz", { desc = "上翻半页并居中" })
map("n", "n", "nzzzv", { desc = "下一个匹配并居中" })
map("n", "N", "Nzzzv", { desc = "上一个匹配并居中" })

-- Dashboard
map("n", "<leader>.", function() Snacks.dashboard.open() end, { desc = "Dashboard" })

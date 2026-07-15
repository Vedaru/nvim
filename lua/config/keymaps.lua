-- Keymaps loaded on VeryLazy (replaces LazyVim's lazyvim.config.keymaps dependency)
-- Uses plain vim.keymap.set — no LazyVim.safe_keymap_set, no Snacks.keymap.set indirection
-- mapleader is set by lazyvim.config.options (Space), loaded before this file

local map = vim.keymap.set

-- <leader> prefix: make the raw <Space> key itself a no-op.
-- By default, Normal-mode <Space> is equivalent to `l` (cursor right).
-- Since <Space> is also our <leader>, if Neovim ever falls through to the
-- "default" behavior (e.g. timeout expires with no matching longer mapping,
-- or you press <leader> then an undefined key), it would move the cursor
-- right instead of doing nothing. Mapping <Space> to <Nop> here prevents that.
-- This does NOT interfere with <leader>xx style mappings — Vim always tries
-- to resolve the longest matching mapping first.
map({ "n", "x" }, "<Space>", "<Nop>", { desc = "Leader key (no-op)", silent = true })

-- window navigation (normal + terminal mode)
map({ "n", "t" }, "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
map({ "n", "t" }, "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
map({ "n", "t" }, "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
map({ "n", "t" }, "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

-- better up/down (gj/gk for wrapped lines)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- window resize
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- move lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function()
  local ok = pcall(Snacks.bufdelete)
  if not ok then
    vim.cmd("bdelete!")
  end
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  local ok = pcall(Snacks.bufdelete.other)
  if not ok then
    vim.cmd("bdelete!")
  end
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bi", function()
  local ok = pcall(Snacks.bufdelete.invisible)
  if not ok then
    vim.cmd("bdelete!")
  end
end, { desc = "Delete Invisible Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- save / search / indent
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("x", "<", "<gv")
map("x", ">", ">gv")

-- diagnostics
local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- misc
map({ "n", "x" }, "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map({ "n", "x" }, "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("n", "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right" })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window" })

-- window move (leader + w + H/J/K/L)
map("n", "<leader>wH", "<C-W>H", { desc = "Move Window Left" })
map("n", "<leader>wJ", "<C-W>J", { desc = "Move Window Down" })
map("n", "<leader>wK", "<C-W>K", { desc = "Move Window Up" })
map("n", "<leader>wL", "<C-W>L", { desc = "Move Window Right" })

-- terminal
local function open_terminal(cwd)
  local ok, err = pcall(function()
    Snacks.terminal.toggle(nil, {
      cwd = cwd,
      interactive = false,
    })
  end)
  if not ok then
    vim.notify("Terminal: " .. tostring(err), vim.log.levels.ERROR)
  end
end

map("n", "<leader>ft", function()
  local ok, P = pcall(require, "persistence")
  local cwd = ok and P._active_dir or nil
  cwd = cwd or vim.fn.getcwd()
  if cwd == "" then
    cwd = vim.fn.expand("~")
  end
  open_terminal(cwd)
end, { desc = "Terminal (Root Dir)" })
map("n", "<leader>fT", function()
  open_terminal(vim.fn.getcwd())
end, { desc = "Terminal (cwd)" })
map({ "n", "t" }, "<c-/>", function()
  open_terminal(vim.fn.getcwd())
end, { desc = "Terminal (cwd)" })

-- terminal insert: use <C-\><C-n> to return to normal mode
map("t", "<C-\\><C-n>", "<C-\\><C-n>", { desc = "Terminal Normal Mode" })

-- undo break-points in insert mode
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- gx: open URL
local gx = vim.fn.maparg("gx", "n", 0, 1)
if gx and gx.callback then
  map("n", "gx", gx.callback, { desc = "Open url" })
end

-- Browse keymaps with Snacks picker
map("n", "<leader>?", function() Snacks.picker.keymaps() end, { desc = "Browse keymaps" })

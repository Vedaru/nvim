--- Core keymaps (no plugin dependencies).
--- Plugin-specific keymaps live in their respective plugins/*.lua files.
--- mapleader is set in init.lua before this loads.

local map = vim.keymap.set

-- ── Strip built-in LSP keymaps (no-op without LSP client) ────────────────────

do
  local del = vim.keymap.del
  local builtins = {
    { "n", "gra" }, { "n", "grr" }, { "n", "grn" }, { "n", "grt" }, { "n", "gri" },
    { "n", "grx" }, { "n", "gO" },
    { "v", "<C-S>" }, { "x", "<C-S>" }, { "i", "<C-S>" }, { "s", "<C-S>" },
    { "v", "gra" }, { "x", "gra" },
    { "n", "<C-W>d" }, { "n", "<C-W><C-D>" },
    { "n", "[D" }, { "n", "]D" },
  }
  for _, spec in ipairs(builtins) do
    pcall(del, spec[1], spec[2])
  end
end

-- ── Leader ───────────────────────────────────────────────────────────────────

map({ "n", "x" }, "<Space>", "<Nop>", { desc = "Leader key (no-op)", silent = true })

-- ── Window navigation ────────────────────────────────────────────────────────

map({ "n", "t" }, "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
map({ "n", "t" }, "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
map({ "n", "t" }, "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
map({ "n", "t" }, "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

map("n", "<C-Up>",    "<cmd>resize +2<cr>",          { desc = "Increase Window Height" })
map("n", "<C-Down>",  "<cmd>resize -2<cr>",          { desc = "Decrease Window Height" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

map("n", "<leader>-",  "<C-W>s", { desc = "Split Window Below" })
map("n", "<leader>|",  "<C-W>v", { desc = "Split Window Right" })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window" })
map("n", "<leader>wH", "<C-W>H", { desc = "Move Window Left" })
map("n", "<leader>wJ", "<C-W>J", { desc = "Move Window Down" })
map("n", "<leader>wK", "<C-W>K", { desc = "Move Window Up" })
map("n", "<leader>wL", "<C-W>L", { desc = "Move Window Right" })

-- ── Movement / editing ───────────────────────────────────────────────────────

-- gj/gk on wrapped lines, count-aware
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==",                   { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==",             { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi",                                   { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi",                                   { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv",       { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

map("x", "<", "<gv")
map("x", ">", ">gv")
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Undo break-points on punctuation in insert mode.
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- ── Buffers ──────────────────────────────────────────────────────────────────

map("n", "<S-h>",       "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>",       "<cmd>bnext<cr>",     { desc = "Next Buffer" })
map("n", "[b",          "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b",          "<cmd>bnext<cr>",     { desc = "Next Buffer" })
map("n", "<leader>bb",  "<cmd>e #<cr>",       { desc = "Switch to Other Buffer" })
map("n", "<leader>`",   "<cmd>e #<cr>",       { desc = "Switch to Other Buffer" })
map("n", "<leader>bD",  "<cmd>:bd<cr>",       { desc = "Delete Buffer and Window" })

-- Safe bufdelete: try Snacks, fall back to :bdelete!
local function bufdelete(fn)
  return function()
    local ok = pcall(fn)
    if not ok then
      vim.cmd("bdelete!")
    end
  end
end
map("n", "<leader>bd", bufdelete(Snacks.bufdelete),           { desc = "Delete Buffer" })
map("n", "<leader>bo", bufdelete(Snacks.bufdelete.other),      { desc = "Delete Other Buffers" })
map("n", "<leader>bi", bufdelete(Snacks.bufdelete.invisible),  { desc = "Delete Invisible Buffers" })

-- ── Search ───────────────────────────────────────────────────────────────────

map({ "n", "x" }, "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map({ "n", "x" }, "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("n", "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" })

-- ── Diagnostics (vim.diagnostic — no LSP required) ───────────────────────────

local function diag_jump(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float,      { desc = "Line Diagnostics" })
map("n", "]d", diag_jump(true),                         { desc = "Next Diagnostic" })
map("n", "[d", diag_jump(false),                        { desc = "Prev Diagnostic" })
map("n", "]e", diag_jump(true, "ERROR"),                { desc = "Next Error" })
map("n", "[e", diag_jump(false, "ERROR"),               { desc = "Prev Error" })
map("n", "]w", diag_jump(true, "WARN"),                 { desc = "Next Warning" })
map("n", "[w", diag_jump(false, "WARN"),                { desc = "Prev Warning" })

-- ── Misc ─────────────────────────────────────────────────────────────────────

map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
map("n", "<leader>qq", "<cmd>qa<cr>",   { desc = "Quit All" })

-- gx: preserve Snacks/LazyVim URL handler
local gx = vim.fn.maparg("gx", "n", 0, 1)
if gx and gx.callback then
  map("n", "gx", gx.callback, { desc = "Open url" })
end

-- Terminal: <C-/> toggles at cwd, <C-\><C-n> to escape
local S = require("config.session")
map("n", "<leader>ft", function()
  local ok, err = pcall(Snacks.terminal.toggle, nil, { cwd = S.project_root(), interactive = false })
  if not ok then
    vim.notify("Terminal: " .. tostring(err), vim.log.levels.ERROR)
  end
end, { desc = "Terminal (Root Dir)" })
map("n", "<leader>fT", function()
  vim.cmd.lcd(S.project_root())
  vim.cmd.terminal()
end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-/>", function()
  Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd(), interactive = false })
end, { desc = "Terminal (cwd)" })
map("t", "<C-\\><C-n>", "<C-\\><C-n>", { desc = "Terminal Normal Mode" })

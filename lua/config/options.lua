-- ~/.config/nvim/lua/config/options.lua — 完全覆盖，不追 LazyVim 更新

local opt = vim.opt

-- ── 命令行补全弹出菜单（方向键 / Ctrl-N/P 可用）────────────────────
opt.wildmenu = true
opt.wildoptions = "pum" -- 弹出菜单样式
opt.wildmode = "longest:full,full" -- 先补全最长公共前缀，再显示菜单
opt.pumblend = 10 -- 补全菜单半透明
opt.pumheight = 12 -- 补全菜单最多显示 12 行

-- ── 编辑体验 ──────────────────────────────────────────────────────
opt.scrolloff = 8 -- 光标上下保留 8 行可见
opt.sidescrolloff = 8 -- 光标左右保留 8 列可见
opt.cursorline = true -- 高亮当前行
opt.wrap = false -- 默认不折行
opt.linebreak = true -- 折行时按单词边界断行
opt.signcolumn = "yes" -- 始终显示左侧符号列，避免抖动
opt.number = true -- 当前行显示绝对行号
opt.relativenumber = true -- 其他行显示相对行号
opt.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
opt.virtualedit = "block" -- 块选择可超出行尾

-- ── 缩进 ──────────────────────────────────────────────────────────
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true -- Tab 转空格
opt.shiftround = true -- 缩进对齐到 shiftwidth 的整数倍
opt.smartindent = true

-- ── 搜索 ──────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true -- 含大写时区分大小写
opt.inccommand = "split" -- :s 实时预览替换效果

-- ── 窗口分割 ──────────────────────────────────────────────────────
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen" -- 分割时保持文本屏幕位置不跳动

-- ── 文件 / 性能 ───────────────────────────────────────────────────
opt.undofile = true -- 持久化撤销历史
opt.undolevels = 10000
opt.updatetime = 200 -- 更快的 CursorHold / 交换文件写入
opt.swapfile = false -- 避免 session 恢复时 W325（多实例/残留 swapfile）；撤销由 undofile 负责
opt.timeoutlen = 300 -- leader key timeout
opt.confirm = true -- 退出未保存时提示而非报错

-- ── 外观细节 ──────────────────────────────────────────────────────
opt.termguicolors = true
-- 仅追加 eob，保留 LazyVim 默认的 fold 图标（避免覆盖造成字符数错误）
opt.fillchars:append({ eob = " " }) -- 隐藏行尾的 ~
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- ── 剪贴板 ──────────────────────────────────────────────────────────
-- WSL 下 xclip 读 Windows 富文本剪贴板会报 "target STRING not available"
-- 用 Windows 原生工具替代，stable 且无格式转换问题
vim.g.clipboard = {
  name = "WSL-Clipboard",
  copy = {
    ["+"] = { "clip.exe" },
    ["*"] = { "clip.exe" },
  },
  paste = {
    ["+"] = { "sh", "-c", "powershell.exe -NoProfile -Command 'Get-Clipboard -Raw' | tr -d '\r'" },
    ["*"] = { "sh", "-c", "powershell.exe -NoProfile -Command 'Get-Clipboard -Raw' | tr -d '\r'" },
  },
  cache_enabled = 1,
}

-- ── 代理（GFW 环境下 treesitter / mason 下载用）─────────────────────
vim.env.https_proxy = "http://127.0.0.1:7897"
vim.env.http_proxy = "http://127.0.0.1:7897"

-- 默认 yank/delete/paste 使用系统剪贴板（"+ 寄存器）
vim.o.clipboard = "unnamedplus"

-- ── gx / vim.ui.open：WSL 下用 Windows 默认程序打开 ──────────────────────
-- 默认走 xdg-open，WSL 里不可用，会导致 gx 报错：
--   vim.ui.open: command failed (2): { "xdg-open", ... }
-- Neovim 0.10+ 的 gx handler 会对返回值调用 :wait()，所以必须用
-- vim.system 返回 SystemObj（vim.fn.jobstart 返回数字会触发
-- "attempt to index a number value"）
vim.ui.open = function(uri)
  local cmd
  if vim.fn.executable("wslview") == 1 then
    cmd = { "wslview", uri }
  else
    cmd = { "powershell.exe", "-NoProfile", "-Command", "Start-Process", uri }
  end
  return vim.system(cmd, { text = true })
end

-- ── Session ────────────────────────────────────────────────────────
-- 不保存 terminal buffer（恢复时是死的）
-- 不保存 global/local options — 避免 session 覆盖 colorscheme、行号、fold 等
vim.opt.sessionoptions:remove("terminal")
vim.opt.sessionoptions:remove("options")
vim.opt.sessionoptions:remove("localoptions")

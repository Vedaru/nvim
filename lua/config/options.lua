-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- 这里只放对 LazyVim 默认值的增强/覆盖

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
opt.timeoutlen = 400 -- which-key 等映射等待时间
opt.confirm = true -- 退出未保存时提示而非报错

-- ── 外观细节 ──────────────────────────────────────────────────────
opt.termguicolors = true
-- 仅追加 eob，保留 LazyVim 默认的 fold 图标（避免覆盖造成字符数错误）
opt.fillchars:append({ eob = " " }) -- 隐藏行尾的 ~
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- ── Session ────────────────────────────────────────────────────────
-- 不保存 terminal buffer（恢复时是死的），保留 local options
vim.opt.sessionoptions:remove("terminal")
vim.opt.sessionoptions:append("localoptions")

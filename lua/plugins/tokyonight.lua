-- ~/.config/nvim/lua/plugins/tokyonight.lua
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night", -- tokyonight 最暗的变体
    on_colors = function(c)
      -- 把所有背景都改成纯黑
      c.bg = "#000000"
      c.bg_dark = "#000000"
      c.bg_dark1 = "#000000"
      c.bg_float = "#000000"
      c.bg_sidebar = "#000000"
      c.bg_statusline = "#000000"
      c.bg_popup = "#000000"
      -- 当前行高亮也用纯黑，去掉“淡一点的黑”横条
      c.bg_highlight = "#000000"
    end,
    on_highlights = function(hl, c)
      -- 分割线：亮蓝色 + 粗体
      hl.WinSeparator = { fg = c.blue, bold = true }
      hl.VertSplit = { fg = c.blue, bold = true }
      -- 确保主要窗口/浮窗背景为纯黑
      hl.Normal = { bg = "#000000" }
      hl.NormalNC = { bg = "#000000" }
      hl.NormalFloat = { bg = "#000000" }
      hl.SignColumn = { bg = "#000000" }
      -- 当前行背景纯黑（仅靠行号高亮指示当前行，无横条色差）
      hl.CursorLine = { bg = "#000000" }
      -- dashboard 的 VEDARU banner：深色泛黄旧纸张色
      hl.SnacksDashboardHeader = { fg = "#c2a86b", bold = true }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd("colorscheme tokyonight")
  end,
}

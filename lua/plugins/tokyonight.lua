-- ~/.config/nvim/lua/plugins/tokyonight.lua
-- transparent=true 由 tokyonight 原生处理透明，不手动设 NONE 避免破坏内部混合
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night",
    transparent = true, -- tokyonight 原生透明，自动处理 Normal/SignColumn/Float 等
    on_highlights = function(hl, c)
      -- 分割线颜色
      hl.WinSeparator = { fg = "#c2a86b", bold = true }
      hl.VertSplit = { fg = "#c2a86b", bold = true }
      -- dashboard banner
      hl.SnacksDashboardHeader = { fg = "#c2a86b", bold = true }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd("colorscheme tokyonight")
  end,
}

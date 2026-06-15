-- ~/.config/nvim/lua/plugins/tokyonight.lua
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    on_highlights = function(hl, c)
      -- 分割线：亮蓝色 + 粗体
      hl.WinSeparator = { fg = c.blue, bold = true }
      hl.VertSplit = { fg = c.blue, bold = true }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd("colorscheme tokyonight")
  end,
}

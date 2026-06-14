-- 󰌌 which-key: 快捷键分组图标
return {
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      local wk = require("which-key")
      wk.add({
        { "<leader>f", group = "󰍉 Find / Telescope",  mode = "n" },
        { "<leader>g", group = "󰊢 Git",               mode = "n" },
        { "<leader>h", group = "󰃷 Hunks / GitSigns",   mode = "n" },
        { "<leader>c", group = " Code",               mode = "n" },
        { "<leader>d", group = "󰒡 Diagnostics",        mode = "n" },
        { "<leader>x", group = "󱗵 Trouble",            mode = "n" },
        { "<leader>w", group = "󰨞 Workspace",          mode = "n" },
        { "<leader>t", group = " Terminal",           mode = "n" },
        { "<leader>o", group = "󰈙 Oil",                mode = "n" },
        { "<leader>r", group = " Refactor",           mode = "n" },
        { "<leader>s", group = "󰒓 Search",             mode = "n" },
        { "<leader>b", group = "󰓩 Buffer",             mode = "n" },
      })
    end,
  },
}

-- ~/.config/nvim/lua/plugins/snacks.lua
local project_root = function()
  return require("config.session").project_root()
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        enabled = false,
      },
      picker = {
        hidden = true,
        ignored = true,
        follow = true,
        sources = {
          git_diff = {
            -- Suppress "Command failed" noise when outside a git repo.
            -- The picker shows "No results" anyway — no need for a red error.
            notify = false,
          },
        },
      },
      dashboard = {
        preset = {
          header = [[
██╗   ██╗███████╗██████╗  █████╗ ██████╗ ██╗   ██╗
██║   ██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██║   ██║
██║   ██║█████╗  ██║  ██║███████║██████╔╝██║   ██║
╚██╗ ██╔╝██╔══╝  ██║  ██║██╔══██║██╔══██╗██║   ██║
 ╚████╔╝ ███████╗██████╔╝██║  ██║██║  ██║╚██████╔╝
  ╚═══╝  ╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
          ]],
        },
        -- 不显示快捷选项、q 退出 nvim 等行为已在 snacks 源码里改好
        -- (defaults.sections 去掉 keys 段、preset.keys 清空、D:init q -> :qa)，
        -- build.sh 会把改过的 snacks.nvim 一起打包，重装不丢。
      },
      -- Disable auto_insert so terminal stays in normal mode after <Esc><Esc>,
      -- allowing which-key's <Space> trigger to work.
      -- Replace LazyVim's buggy term_nav() mappings with direct <cmd> variants.
      -- Must include expr=true because snacks wraps string RHS in a function
      -- whose return value is ignored without it.
      -- auto_close=false: suppress "Terminal exited" notification on session switch
      terminal = {
        enabled = true,
        auto_insert = false,
        auto_close = false,
        win = {
          keys = {
            nav_h = { "<C-h>", "<cmd>wincmd h<cr>", desc = "Go to Left Window", mode = "t", expr = true },
            nav_j = { "<C-j>", "<cmd>wincmd j<cr>", desc = "Go to Lower Window", mode = "t", expr = true },
            nav_k = { "<C-k>", "<cmd>wincmd k<cr>", desc = "Go to Upper Window", mode = "t", expr = true },
            nav_l = { "<C-l>", "<cmd>wincmd l<cr>", desc = "Go to Right Window", mode = "t", expr = true },
          },
        },
      },
    },
    keys = {
      -- 查找类：基于 snacks.picker，统一使用 project_root()
      {
        "<leader>gd",
        function()
          Snacks.picker.git_diff({ cwd = project_root() })
        end,
        desc = "Git Diff (hunks)",
      },
      {
        "<leader>gD",
        function()
          Snacks.picker.git_diff({ cwd = project_root(), base = "origin", group = true })
        end,
        desc = "Git Diff (origin)",
      },
      {
        "<leader>ff",
        function()
          require("snacks.picker").files({ cwd = project_root() })
        end,
        silent = true,
        desc = "Find files",
      },
      {
        "<leader>fg",
        function()
          require("snacks.picker").grep({ cwd = project_root() })
        end,
        silent = true,
        desc = "Live grep",
      },
      {
        "<leader>fb",
        function()
          require("snacks.picker").buffers()
        end,
        silent = true,
        desc = "Find buffers",
      },
      {
        "<leader>fr",
        function()
          require("snacks.picker").recent()
        end,
        silent = true,
        desc = "Recent files",
      },
    },
  },
}

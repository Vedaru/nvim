--- Snacks: picker, dashboard, terminal, statuscolumn, indent, scroll, etc.

local S = require("config.session")

return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = false },
      picker = {
        hidden = true,
        ignored = true,
        follow = true,
        jump = { reuse_win = true },
        sources = {
          git_diff = { notify = false },
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
      },
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
      -- Picker: search
      { "<leader>ff", function() Snacks.picker.files({ cwd = S.project_root() }) end,    desc = "Find Files" },
      { "<leader>fg", function() Snacks.picker.grep({ cwd = S.project_root() }) end,     desc = "Live Grep" },
      { "<leader>fb", function() Snacks.picker.buffers() end,                            desc = "Find Buffers" },
      { "<leader>fr", function() Snacks.picker.recent() end,                             desc = "Recent Files" },
      { "<leader>gd", function() Snacks.picker.git_diff({ cwd = S.project_root() }) end, desc = "Git Diff (hunks)" },
      {
        "<leader>gD",
        function()
          Snacks.picker.git_diff({ cwd = S.project_root(), base = "origin", group = true })
        end,
        desc = "Git Diff (origin)",
      },
      -- Picker: keymaps
      {
        "<leader>?",
        function()
          Snacks.picker.keymaps({
            transform = function(item)
              local info = item.info
              if info and info.what == "Lua" and info.source:sub(2):find("^vim/_core/") then
                return false
              end
              if item.file then
                local stat = vim.uv.fs_stat(item.file)
                if not stat then
                  local with_ext = item.file .. ".lua"
                  if vim.uv.fs_stat(with_ext) then
                    item.file = with_ext
                  end
                end
              end
              return true
            end,
          })
        end,
        desc = "Browse Keymaps",
      },
    },
  },
}

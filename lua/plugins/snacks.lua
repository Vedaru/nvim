-- ~/.config/nvim/lua/plugins/snacks.lua
return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        hidden = true,
        ignored = true,
        follow = true,
      },
      picker = {
        hidden = true,
        ignored = true,
        follow = true,
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
    },
    keys = {
      -- <leader>e: open at current file's directory
      {
        "<leader>e",
        function()
          Snacks.explorer.open({
            cwd = vim.fn.expand("%:p:h"),
          })
        end,
        desc = "Explorer (file dir)",
      },
      -- <leader>E: open at CWD (project root)
      {
        "<leader>E",
        function()
          Snacks.explorer.open({
            cwd = vim.fn.getcwd(),
          })
        end,
        desc = "Explorer (cwd)",
      },
      -- 查找类：基于 snacks.picker
      { "<leader>ff", function() require("snacks.picker").files({ cwd = vim.fn.expand("%:p:h") }) end, silent = true, desc = "Find files (current dir)" },
      { "<leader>fg", function() require("snacks.picker").grep() end, silent = true, desc = "Live grep" },
      { "<leader>fb", function() require("snacks.picker").buffers() end, silent = true, desc = "Find buffers" },
      { "<leader>fr", function() require("snacks.picker").recent() end, silent = true, desc = "Recent files" },
    },
  },
}

-- Session management keymaps for persistence.nvim
-- Encoding is the original % (Vim convention, handles all special chars)
return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  keys = {
    { "<leader>qS", function()
        local dir = vim.fn.stdpath("state") .. "/sessions"
        vim.cmd("Oil " .. vim.fn.fnameescape(dir))
      end, desc = "Manage Sessions (Oil)" },
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qw", function() require("persistence").save(); vim.notify("Session saved", vim.log.levels.INFO) end, desc = "Save Current Session" },
    { "<leader>qd", function() require("persistence").stop(); vim.cmd("qa") end, desc = "Quit Without Saving Session" },
  },
  opts = {
    dir = vim.fn.stdpath("state") .. "/sessions/",
    need = 1,
    branch = true,
  },
}

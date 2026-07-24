--- Session manager plugin: keymaps + autocmds.
--- All logic lives in config/session.lua (no plugin dependency).

local S = require("config.session")

return {
  dir = vim.fn.stdpath("config") .. "/lua/plugins",
  name = "session-manager",
  lazy = false,

  keys = {
    { "<leader>qs", S.load,                                  desc = "Restore Session" },
    { "<leader>ql", function() S.load({ last = true }) end,  desc = "Restore Last Session" },
    {
      "<leader>qw",
      function()
        S.save()
        vim.notify("Session saved", vim.log.levels.INFO)
      end,
      desc = "Save Current Session",
    },
    { "<leader>qd", function() vim.cmd("qa") end,            desc = "Quit Without Saving Session" },
    {
      "<leader>qS",
      function()
        vim.cmd("Oil " .. vim.fn.fnameescape(S.session_dir()))
      end,
      desc = "Manage Sessions (Oil)",
    },
  },

  config = function()
    -- Auto-save on first BufWritePre per project (debounced by existence check).
    local saved = {}
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("session_auto_save", { clear = true }),
      callback = function()
        local dir = S.project_root()
        local file = S.file_for(dir)
        if vim.fn.filereadable(file) == 0 and not saved[dir] then
          saved[dir] = true
          S.save({ cwd = dir })
        end
      end,
    })

    -- Auto-restore session when nvim is opened with no args.
    if vim.fn.argc() == 0 then
      vim.schedule(function()
        local file = S.file_for(S.project_root())
        if vim.fn.filereadable(file) == 1 then
          S.load()
        end
      end)
    end
  end,
}

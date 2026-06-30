-- Override persistence.nvim encoding: use + instead of % for path separators
-- D:/Personal_Files/Projects/Github/krita-master
--   -> D+Personal_Files+Projects+Github+krita-master.vim  (flat, valid on Windows)
--
-- Displays as proper paths via oil.lua decoding: + -> /
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
  config = function(_, opts)
    require("persistence").setup(opts)
    local P = require("persistence")
    local Config = require("persistence.config")
    local SEP = "+"

    -- Override: encode path with + instead of %
    P.current = function(opts_arg)
      opts_arg = opts_arg or {}
      local name = vim.fn.getcwd():gsub("[\\/:]+", SEP)
      if Config.options.branch and opts_arg.branch ~= false then
        local branch = P.branch()
        if branch and branch ~= "main" and branch ~= "master" then
          name = name .. SEP .. branch:gsub("[\\/:]+", SEP)
        end
      end
      return Config.options.dir .. name .. ".vim"
    end

    -- Override select(): decode + back to / for display
    P.select = function()
      local items = {}
      local have = {}
      for _, session in ipairs(P.list()) do
        if vim.uv.fs_stat(session) then
          local file = session:sub(#Config.options.dir + 1, -5)
          local dir, branch = unpack(vim.split(file, SEP, { plain = true }))
          dir = dir:gsub(SEP, "/")
          if jit and jit.os:find("Windows") then
            dir = dir:gsub("^(%w)/", "%1:/")
          end
          if not have[dir] then
            have[dir] = true
            local display = vim.fn.fnamemodify(dir, ":~"):gsub("\\", "/")
            if branch then
              display = display .. "  [" .. branch .. "]"
            end
            items[#items + 1] = { session = session, dir = dir, branch = branch, display = display }
          end
        end
      end
      vim.ui.select(items, {
        prompt = "Select a session:",
        format_item = function(item)
          return item.display
        end,
      }, function(item)
        if item then
          P.fire("LoadPre")
          vim.cmd("silent! source " .. vim.fn.fnameescape(item.session))
          P.fire("LoadPost")
        end
      end)
    end
  end,
}

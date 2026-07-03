-- Override persistence.nvim: project-aware sessions with isolation.
-- Each session owns its buffers/windows. Switching sessions closes old buffers
-- (after asking about unsaved changes) and restores the new session's state.
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
    branch = false,
  },
  config = function(_, opts)
    require("persistence").setup(opts)
    local P = require("persistence")
    local Config = require("persistence.config")
    local e = vim.fn.fnameescape
    P._active_dir = nil

    local function dirname(file)
      local d = vim.split(file:sub(#Config.options.dir + 1, -5), "%%", { plain = true })[1]
      d = d:gsub("%%", "/")
      if jit and jit.os:find("Windows") then d = d:gsub("^(%w)/", "%1:/") end
      return d
    end

    function P.switch(file)
      if not file or vim.fn.filereadable(file) == 0 then return end
      local unsaved = {}
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].modified and vim.bo[b].buftype == "" then
          local n = vim.api.nvim_buf_get_name(b)
          if n ~= "" then unsaved[#unsaved + 1] = vim.fn.fnamemodify(n, ":~") end
        end
      end
      if #unsaved > 0 then
        local msg = "Unsaved changes:\n" .. table.concat(unsaved, "\n  ", 1, math.min(#unsaved, 5))
        if #unsaved > 5 then msg = msg .. "\n  ... and " .. (#unsaved - 5) .. " more" end
        local c = vim.fn.confirm(msg .. "\n\nSave before switching?", "&Save\n&Discard\n&Cancel")
        if c == 1 then vim.cmd("silent! wa") elseif c ~= 2 then return end
      end
      vim.cmd("silent! %bdelete!")
      vim.api.nvim_echo({}, false, {}) -- clear terminal exit messages
      P._active_dir = dirname(file)
      P.fire("LoadPre")
      vim.cmd("silent! source " .. e(file))
      P.fire("LoadPost")
    end

    P.current = function(opts_arg)
      opts_arg = opts_arg or {}
      local dir = opts_arg.cwd or P._active_dir
      if not dir then
        local b = vim.api.nvim_buf_get_name(0)
        dir = b ~= "" and (vim.fs.root(b, { ".git" }) or vim.fn.fnamemodify(b, ":p:h")) or vim.fn.getcwd()
      end
      local name = dir:gsub("[\\/:]+", "%%")
      if Config.options.branch and opts_arg.branch ~= false then
        local br = P.branch()
        if br and br ~= "main" and br ~= "master" then name = name .. "%%" .. br:gsub("[\\/:]+", "%%") end
      end
      return Config.options.dir .. name .. ".vim"
    end

    P.save = function(save_opts)
      save_opts = save_opts or {}
      if save_opts.cwd then P._active_dir = save_opts.cwd
      elseif not P._active_dir then
        local b = vim.api.nvim_buf_get_name(0)
        P._active_dir = b ~= "" and (vim.fs.root(b, { ".git" }) or vim.fn.fnamemodify(b, ":p:h")) or vim.fn.getcwd()
      end
      vim.cmd("mks! " .. e(P.current(save_opts)))
    end

    P.load = function(load_opts)
      load_opts = load_opts or {}
      local file = load_opts.last and P.last() or P.current()
      if vim.fn.filereadable(file) == 0 then file = P.current({ branch = false }) end
      P.switch(file)
    end

    P.select = function()
      local items, have = {}, {}
      for _, s in ipairs(P.list()) do
        if vim.uv.fs_stat(s) then
          local d = dirname(s)
          if not have[d] then
            have[d] = true
            items[#items + 1] = { session = s, dir = d, display = vim.fn.fnamemodify(d, ":~"):gsub("\\", "/") }
          end
        end
      end
      vim.ui.select(items, {
        prompt = "Select a session:",
        format_item = function(i) return i.display end,
      }, function(item)
        if item then P.switch(item.session) end
      end)
    end
  end,
}

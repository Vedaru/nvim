-- Override persistence.nvim: project-aware sessions with isolation.
-- Session files live in stdpath("state")/sessions/.
return {
  "folke/persistence.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>qS",
      function()
        local dir = require("persistence").session_dir()
        vim.cmd("Oil " .. vim.fn.fnameescape(dir))
      end,
      desc = "Manage Sessions (Oil)",
    },
    {
      "<leader>qs",
      function()
        require("persistence").load()
      end,
      desc = "Restore Session",
    },
    {
      "<leader>ql",
      function()
        require("persistence").load({ last = true })
      end,
      desc = "Restore Last Session",
    },
    {
      "<leader>qw",
      function()
local P = require("persistence")
        P._explicit_save = true
        P.save()
        vim.notify("Session saved", vim.log.levels.INFO)
      end,
      desc = "Save Current Session",
    },
    {
      "<leader>qd",
      function()
        require("persistence").stop()
        vim.cmd("qa")
      end,
      desc = "Quit Without Saving Session",
    },
  },
  opts = function()
    return {
      dir = require("config.session").session_dir(),
      need = 1,
      branch = false,
    }
  end,
  config = function(_, opts)
    local util = require("config.session")
    require("persistence").setup(opts)
    local P = require("persistence")
    local Config = require("persistence.config")
    local e = vim.fn.fnameescape
    P._active_dir = nil
    P.session_dir = util.session_dir

    local function dirname(file)
      return util.decode_session_path(file)
    end

    local function ensure_layout()
      vim.o.winheight = 1
      vim.o.winwidth = 20
      vim.o.winminheight = 0
      vim.o.winminwidth = 0
      vim.o.laststatus = 3

      if #vim.api.nvim_list_wins() == 0 then
        vim.cmd("enew")
      end

      local cur_name = vim.api.nvim_buf_get_name(0)
      if cur_name == "" or vim.fn.filereadable(cur_name) == 0 then
        if not util.show_best_buffer() and P._active_dir then
          util.open_project_fallback(P._active_dir)
        end
      end

      -- Wipe leftover empty [No Name] buffers that session restore leaves
      -- behind (saved via badd, never cleaned by the session's built-in
      -- wipebuf guard because they still have a visible window).
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and buf ~= vim.api.nvim_get_current_buf() then
          if vim.api.nvim_buf_get_name(buf) == "" and not vim.bo[buf].modified then
            local wins = vim.fn.win_findbuf(buf)
            if #wins == 0 then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
          end
        end
      end

      if vim.bo.buftype == "terminal" then
        if P._active_dir then
          util.open_project_fallback(P._active_dir)
        else
          vim.cmd("enew")
        end
      end

      local name = vim.api.nvim_buf_get_name(0)
      if name ~= "" and vim.fn.filereadable(name) == 1 then
        pcall(vim.cmd, "doautocmd FileType")
      end

      pcall(function()
        require("mini.statusline").enable()
      end)

      -- reset_line_numbers 由 SessionLoadPost autocmd 处理，这里不重复调用

      if vim.g.colors_name then
        vim.cmd.colorscheme(vim.g.colors_name)
      end

      vim.cmd("wincmd =")
      vim.cmd("redraw!")
      vim.cmd("redrawstatus!")
    end

    function P.switch(file)
      if not file or vim.fn.filereadable(file) == 0 then
        vim.notify("Session not found: " .. tostring(file), vim.log.levels.ERROR)
        return
      end
      local unsaved = {}
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].modified and vim.bo[b].buftype == "" then
          local n = vim.api.nvim_buf_get_name(b)
          if n ~= "" then
            unsaved[#unsaved + 1] = vim.fn.fnamemodify(n, ":~")
          end
        end
      end
      if #unsaved > 0 then
        local msg = "Unsaved changes:\n" .. table.concat(unsaved, "\n  ", 1, math.min(#unsaved, 5))
        if #unsaved > 5 then
          msg = msg .. "\n  ... and " .. (#unsaved - 5) .. " more"
        end
        local c = vim.fn.confirm(msg .. "\n\nSave before switching?", "&Save\n&Discard\n&Cancel")
        if c == 1 then
          vim.cmd("silent! wa")
        elseif c ~= 2 then
          return
        end
      end

      P._active_dir = dirname(file)

      -- Close all floating windows (oil, snacks, etc.) so session's `silent only`
      -- doesn't fail with E5601 "Cannot close window, only floating window would remain".
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local cfg = vim.api.nvim_win_get_config(win)
          if cfg and cfg.relative and cfg.relative ~= "" then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end

      vim.cmd("silent! tabonly")
      vim.cmd("silent! %bdelete!")
      P.fire("LoadPre")
      local ok, err = pcall(vim.cmd, "source " .. e(file))
      P.fire("LoadPost")
      if not ok then
        vim.notify("Session source failed: " .. tostring(err), vim.log.levels.ERROR)
      end
      ensure_layout()
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
        if br and br ~= "main" and br ~= "master" then
          name = name .. "%%" .. br:gsub("[\\/:]+", "%%")
        end
      end
      return Config.options.dir .. name .. ".vim"
    end

    P.save = function(save_opts)
      save_opts = save_opts or {}
      if save_opts.cwd then
        P._active_dir = save_opts.cwd
      end
      if not P._active_dir then
        return
      end
local session_file = P.current(save_opts)
      if not P._explicit_save and vim.fn.filereadable(session_file) == 0 then return end
      P._explicit_save = false
      local has_file = false
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= "" then
          has_file = true
          break
        end
      end
      if not has_file then
        vim.notify("Session not saved: no file buffers open", vim.log.levels.WARN)
        return
      end
      vim.cmd("mks! " .. e(session_file))
    end

    P.load = function(load_opts)
      load_opts = load_opts or {}
      local file = load_opts.last and P.last() or P.current()
      if vim.fn.filereadable(file) == 0 then
        file = P.current({ branch = false })
      end
      if vim.fn.filereadable(file) == 0 then
        vim.notify("No session file for this directory", vim.log.levels.WARN)
        return
      end
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
        format_item = function(i)
          return i.display
        end,
      }, function(item)
        if item then
          P.switch(item.session)
        end
      end)
    end

    if vim.fn.argc() == 0 then
      vim.schedule(function()
        local file = P.current()
        if vim.fn.filereadable(file) == 1 then
          P.load()
        end
        -- 无 session 时不再调用 Snacks.dashboard.open()：
        -- snacks 自己的 M.setup 已在 UIEnter 时开过 dashboard（普通窗口），
        -- 这里再 open 会创建第二个浮窗 dashboard，导致 :q 需要按两次
        -- （第一次只关浮窗，普通窗口的 dashboard 还在）。
      end)
    end
  end,
}

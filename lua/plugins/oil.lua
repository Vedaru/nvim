-- Oil: terminal-style file manager
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    win_options = {
      signcolumn = "yes",
    },
    view_options = {
      show_hidden = true,
    },
    keymaps = {
      ["q"] = "actions.close",
      ["-"] = { "actions.parent", mode = "n" },
      ["ga"] = {
        mode = "n",
        desc = "Create blank session for highlighted directory",
        callback = function()
          local oil = require("oil")
          local entry = oil.get_cursor_entry()
          local dir = oil.get_current_dir()
          if not dir then
            return
          end
          if entry and entry.type == "directory" then
            dir = dir .. entry.name
          end
          dir = dir:gsub("\\", "/"):gsub("/+$", "")

          local S = require("config.session")
          local file = S.file_for(dir)

          -- Blank session: cd + empty buffer so restore never leaves a black screen.
          vim.fn.writefile({ "cd " .. vim.fn.fnameescape(dir), "enew" }, file)
          oil.close()
          -- Source the blank session directly (same effect as switch but we know it's tiny).
          vim.cmd("silent! %bdelete!")
          vim.cmd("source " .. vim.fn.fnameescape(file))
          require("config.session").reset_line_numbers()
        end,
      },
      ["<CR>"] = function()
        local oil = require("oil")
        local util = require("config.session")
        local entry = oil.get_cursor_entry()

        if not entry or not entry.name or entry.type == "directory" then
          -- directories: navigate in (normal behavior)
          require("oil").select()
          return
        end

        local dir = oil.get_current_dir()
        if util.is_sessions_dir(dir) and entry.name:match("%.vim$") then
          local full_path = dir .. entry.name
          oil.close()
          -- Defer: Oil needs a tick to fully close before we wipe its buffers.
          vim.schedule(function()
            require("config.session").switch(full_path)
          end)
        else
          require("oil").select()
        end
      end,
      ["<C-r>"] = "actions.refresh",
      ["g?"] = "actions.show_help",
      ["gy"] = function()
        local oil = require("oil")
        local entry = oil.get_cursor_entry()
        if not entry then
          return
        end
        local dir = oil.get_current_dir()
        local abs_path = dir .. entry.name
        -- Normalize backslashes to forward slashes
        local display_path = abs_path:gsub("\\", "/")
        -- Restore drive letter colon (D/... -> D:/...)
        display_path = display_path:gsub("^([A-Za-z])/", "%1:/")
        vim.fn.setreg("+", display_path)
        vim.notify("Yanked: " .. display_path, vim.log.levels.INFO)
      end,
    },
    cleanup_delay_ms = 200,
  },
  config = function(_, opts)
    require("oil").setup(opts)

    -- <leader>o — toggle: current file dir → project root (stops there)
    local at_root = false
    vim.api.nvim_create_autocmd("User", {
      pattern = "OilClose",
      callback = function()
        at_root = false
      end,
    })

    vim.keymap.set("n", "<leader>o", function()
      local oil = require("oil")
      local oil_open = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "oil" then
          oil_open = true
          break
        end
      end

      if not oil_open then
        at_root = false
      elseif not at_root then
        at_root = true
      end

      local dir
      if at_root then
        dir = require("config.session").project_root()
      else
        dir = vim.fn.expand("%:p:h")
        if dir == "" or vim.fn.isdirectory(dir) ~= 1 then
          dir = vim.fn.getcwd()
        end
      end

      require("oil").open(dir)
    end, { desc = "Oil (cycle: file dir → root → /)" })
  end,
}

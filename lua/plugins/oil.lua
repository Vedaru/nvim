-- Oil: terminal-style file manager
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
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

          local P = require("persistence")
          local Config = require("persistence.config")
          local name = dir:gsub("[\\/:]+", "%%")
          local file = Config.options.dir .. name .. ".vim"

          -- Always overwrite: blank session is just a cd command.
          vim.fn.writefile({ "cd " .. dir }, file)
          oil.close()
          P.switch(file)
        end,
      },
      ["<CR>"] = function()
        local oil = require("oil")
        local entry = oil.get_cursor_entry()

        if not entry or not entry.name or entry.type == "directory" then
          -- directories: navigate in (normal behavior)
          require("oil").select()
          return
        end

        local dir = oil.get_current_dir()
        -- Check if we're in the sessions directory
        local sessions_dir = vim.fn.stdpath("state") .. "/sessions"
        local norm_dir = dir:gsub("\\", "/")
        local norm_sessions = sessions_dir:gsub("\\", "/")
        if vim.startswith(norm_dir, norm_sessions) and entry.name:match("%.vim$") then
          local full_path = dir .. entry.name
          oil.close()
          require("persistence").switch(full_path)
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

    -- <leader>o — oil sidebar at current file's directory
    vim.keymap.set("n", "<leader>o", function()
      local dir = vim.fn.expand("%:p:h")
      if dir == "" or vim.fn.isdirectory(dir) ~= 1 then
        dir = vim.fn.getcwd()
      end
      require("oil").open(dir)
    end, { desc = "Oil (current file dir)" })
  end,
}

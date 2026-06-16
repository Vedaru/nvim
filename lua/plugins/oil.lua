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
      ["-"] = "actions.parent",
      ["<CR>"] = "actions.select",
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
        vim.fn.setreg("+", abs_path)
        vim.notify("Yanked: " .. abs_path, vim.log.levels.INFO)
      end,
    },
    cleanup_delay_ms = 200,
  },
  config = function(_, opts)
    require("oil").setup(opts)

    -- <leader>e — oil sidebar at current file's directory
    vim.keymap.set("n", "<leader>o", function()
      local dir = vim.fn.expand("%:p:h")
      if dir == "" or vim.fn.isdirectory(dir) ~= 1 then
        dir = vim.fn.getcwd()
      end
      require("oil").open(dir)
    end, { desc = "Oil (current file dir)" })
  end,
}

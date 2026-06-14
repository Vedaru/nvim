-- 󰈙 Oil: 终端风格文件管理器
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        -- 复制绝对路径到系统剪贴板
        gy = function()
          local oil = require("oil")
          local entry = oil.get_cursor_entry()
          if not entry then
            return
          end
          local abs_path = oil.get_current_dir() .. entry.name
          vim.fn.setreg("+", abs_path)
          vim.notify("󰆓 Yanked: " .. abs_path, vim.log.levels.INFO)
        end,
      },
    })

    vim.keymap.set("n", "<leader>o", function()
      require("oil").open_float()
    end, { desc = "󰈙 Open oil (float)" })
  end,
}

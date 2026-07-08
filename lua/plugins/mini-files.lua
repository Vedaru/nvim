-- mini.files: lightweight file explorer replacement for snacks.explorer
-- Loads eagerly (not lazy) so keymaps beat LazyVim's default <leader>e
return {
  "nvim-mini/mini.files",
  version = false,
  lazy = false,
  keys = {
    { "<leader>e", desc = "Toggle file browser (project root)" },
    { "<leader>E", desc = "File browser (cwd)" },
  },
  opts = {
    windows = {
      preview = false,
      width_focus = 35,
      width_nofocus = 15,
    },
    options = {
      use_as_default_explorer = false,
    },
  },
  config = function(_, opts)
    local MiniFiles = require("mini.files")
    MiniFiles.setup(opts)

    vim.keymap.set("n", "<leader>e", function()
      if MiniFiles.close() then
        return
      end
      local root = require("config.session").project_root()
      MiniFiles.open(root)
    end, { desc = "Toggle file browser (project root)" })

    vim.keymap.set("n", "<leader>E", function()
      local cwd = vim.fn.getcwd()
      if cwd == "" then cwd = vim.fn.expand("~") end
      MiniFiles.open(cwd)
    end, { desc = "File browser (cwd)" })
  end,
}

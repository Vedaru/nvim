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
      local root = vim.fn.getcwd()
      local ok, P = pcall(require, "persistence")
      if ok and P._active_dir then
        root = P._active_dir
      end
      MiniFiles.open(root)
    end, { desc = "Toggle file browser (project root)" })

    vim.keymap.set("n", "<leader>E", function()
      MiniFiles.open(vim.fn.getcwd())
    end, { desc = "File browser (cwd)" })
  end,
}

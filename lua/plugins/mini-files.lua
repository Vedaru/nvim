-- mini.files: lightweight file explorer replacement for snacks.explorer
return {
  "nvim-mini/mini.files",
  version = false,
  keys = {
    {
      "<leader>e",
      function()
        local MiniFiles = require("mini.files")
        if MiniFiles.close() then
          return
        end
        local root = vim.fn.getcwd()
        local ok, P = pcall(require, "persistence")
        if ok and P._active_dir then
          root = P._active_dir
        end
        MiniFiles.open(root)
      end,
      desc = "Toggle file browser (project root)",
    },
    {
      "<leader>E",
      function()
        require("mini.files").open(vim.fn.getcwd())
      end,
      desc = "File browser (cwd)",
    },
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
}

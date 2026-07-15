return {
  {
    "ludovicchabant/vim-gutentags",
    dir = vim.fn.stdpath("data") .. "/site/pack/plugins/start/vim-gutentags",
    lazy = false,
    priority = 500,
    init = function()
      local data = vim.fn.stdpath("data")
      local cache = vim.fn.stdpath("cache") .. "/gutentags"
      local home = vim.fn.expand("~")

      vim.g.gutentags_ctags_executable = home .. "/.local/bin/ctags"
      vim.g.gutentags_project_root = { ".git", ".hg", ".svn" }
      vim.g.gutentags_ctags_tagfile = ".tags"
      vim.g.gutentags_cache_dir = cache

      vim.g.gutentags_generate_on_new = true
      vim.g.gutentags_generate_on_missing = true
      vim.g.gutentags_generate_on_write = true
      vim.g.gutentags_generate_on_empty_buffer = false

      -- Exclude giant dirs
      vim.g.gutentags_ctags_exclude = {
        "node_modules", ".git", "dist", "build", "target",
        ".next", ".nuxt", "coverage", "__pycache__",
        "*.min.js", "*.min.css", "*.lock", "*.lockb",
      }

      -- Use rg for file listing (respects .gitignore, fast)
      vim.g.gutentags_file_list_command = "rg --files"

      vim.g.gutentags_exclude_filetypes = {
        "gitcommit", "gitrebase", "help", "markdown",
        "text", "startify", "fugitive", "fugitiveblame",
      }

      vim.g.gutentags_ctags_extra_args = {
        "--fields=+lnS",
        "--extras=+q",
        "--output-format=e-ctags",
      }

      vim.opt.tags:prepend(cache .. "/*")
    end,
    config = function()
      local path = vim.fn.stdpath("data")
        .. "/site/pack/plugins/start/vim-gutentags/plugin/gutentags.vim"
      vim.cmd("source " .. path)
    end,
  },
}

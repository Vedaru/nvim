return {
  {
    "ludovicchabant/vim-gutentags",
    dir = vim.fn.stdpath("data") .. "/site/pack/plugins/start/vim-gutentags",
    lazy = false,
    priority = 500,
    init = function()
      local cache = vim.fn.stdpath("cache") .. "/gutentags"
      vim.fn.mkdir(cache, "p")

      vim.g.gutentags_ctags_executable = vim.fn.expand("~/.local/bin/ctags")
      vim.g.gutentags_cache_dir = cache
      vim.g.gutentags_ctags_tagfile = ".tags"

      -- Custom root finder: .git OR existing session file
      vim.g.gutentags_project_root_finder = function(path)
        local sessions = vim.fn.stdpath("state") .. "/sessions/"
        local cur = vim.fn.fnamemodify(path, ":p:h")
        local prev = ""
        while cur ~= prev and cur ~= "/" do
          if vim.fn.isdirectory(cur .. "/.git") == 1 then
            return cur
          end
          local encoded = cur:gsub("/", "%%") .. ".vim"
          if vim.fn.filereadable(sessions .. encoded) == 1 then
            return cur
          end
          prev = cur
          cur = vim.fn.fnamemodify(cur, ":h")
        end
        return nil
      end

      vim.g.gutentags_generate_on_new = true
      vim.g.gutentags_generate_on_missing = true
      vim.g.gutentags_generate_on_write = true
      vim.g.gutentags_generate_on_empty_buffer = false

      vim.g.gutentags_file_list_command = "rg --files"
      vim.g.gutentags_ctags_exclude = {
        "node_modules", ".git", "dist", "build", "target",
        ".next", ".nuxt", "coverage", "__pycache__",
        "*.min.js", "*.min.css", "*.lock", "*.lockb",
      }

      vim.g.gutentags_exclude_filetypes = {
        "gitcommit", "gitrebase", "help", "markdown",
        "text", "startify", "fugitive", "fugitiveblame",
      }

      vim.g.gutentags_ctags_extra_args = {
        "--fields=+lnS",
        "--extras=+q",
        "--output-format=e-ctags",
        "--languages=-CSS,-JSON,-Markdown,-YAML,-HTML,-XML",
      }

      vim.g.gutentags_project_root_blacklist = { vim.fn.expand("~") }

      vim.opt.tags:prepend(cache .. "/*")
    end,
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("data")
        .. "/site/pack/plugins/start/vim-gutentags/plugin/gutentags.vim")
    end,
  },
}

return {
  {
    "ludovicchabant/vim-gutentags",
    dir = vim.fn.stdpath("data") .. "/site/pack/plugins/start/vim-gutentags",
    lazy = false,
    priority = 500,
    init = function()
      local cache = vim.fn.stdpath("cache") .. "/gutentags"
      vim.fn.mkdir(cache, "p")
      
      -- Ensure ctags is executable; default to 'ctags' if the specific path doesn't exist
      local ctags_path = vim.fn.expand("~/.local/bin/ctags")
      if vim.fn.executable(ctags_path) == 1 then
        vim.g.gutentags_ctags_executable = ctags_path
      else
        vim.g.gutentags_ctags_executable = "ctags"
      end

      vim.g.gutentags_cache_dir = cache
      vim.g.gutentags_ctags_tagfile = ".tags"

      -- Root finder: .git repos + session dirs
      _G._gutentags_find_root = function(path)
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
        return ""
      end

      -- Define the Vimscript wrapper for the Lua root finder
      vim.cmd([[
        function! GutentagsRootFinder(path)
          return luaeval('_G._gutentags_find_root(_A)', a:path)
        endfunction
      ]])
      
      vim.g.gutentags_project_root_finder = "GutentagsRootFinder"
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
      
      -- FIX: Use a specific glob to only match .tags files
      -- Using '/*' was causing Neovim to try reading .lock and .files as tags, failing the jump.
      vim.opt.tags:prepend(cache .. "/*.tags")
    end,
    config = function()
      -- Source the plugin if it's not automatically handled by your packpath
      local plugin_path = vim.fn.stdpath("data") .. "/site/pack/plugins/start/vim-gutentags/plugin/gutentags.vim"
      if vim.fn.filereadable(plugin_path) == 1 then
        vim.cmd("source " .. plugin_path)
      end
    end,
  },
}



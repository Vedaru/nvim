return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    priority = 1000,
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      -- Parsers to auto-install on first run.  After install-nvim.sh runs,
      -- these .so files live in parser/ and Neovim works fully offline.
      ensure_installed = {
        "bash",
        "c",
        "comment",
        "css",
        "diff",
        "dockerfile",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "gosum",
        "html",
        "ini",
        "javascript",
        "json",
        "lua",
        "make",
        "markdown",
        "markdown_inline",
        "python",
        "regex",
        "rust",
        "sql",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
    },
    config = function(_, opts)
      -- nvim-treesitter stores queries under runtime/queries/ but lazy.nvim
      -- only adds the plugin root to rtp.  Add runtime/ manually so Neovim
      -- can find highlights.scm for languages that lack built-in queries.
      local runtime_dir = (_.dir or vim.fn.stdpath('data') .. '/lazy/nvim-treesitter') .. '/runtime'
      if vim.uv.fs_stat(runtime_dir) then
        vim.opt.rtp:prepend(runtime_dir)
      end

      require('nvim-treesitter').setup(opts)

      local group = vim.api.nvim_create_augroup('nvim_treesitter_start', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = '*',
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
          if lang and pcall(vim.treesitter.language.require_language, lang) then
            pcall(vim.treesitter.start, buf, lang)
          end
        end,
      })
    end,
  },
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    priority = 1000,
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
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

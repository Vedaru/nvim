return {
  {
    "ludovicchabant/vim-gutentags",
    -- Point to pre-installed local copy; skip clone
    dir = "~/.local/share/nvim/site/pack/plugins/start/vim-gutentags",
    lazy = false,
    priority = 500,
    config = function()
      -- Config vars are set in init.lua before lazy loads.
      -- Now source the vimscript plugin.
      local path = vim.fn.expand("~/.local/share/nvim/site/pack/plugins/start/vim-gutentags/plugin/gutentags.vim")
      vim.cmd("source " .. path)
    end,
  },
}

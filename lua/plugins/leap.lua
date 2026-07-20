-- ~/.config/nvim/lua/plugins/leap.lua
-- Real leap.nvim (ggandor/leap.nvim, installed locally, zero-network)
-- s/S/gs 2-char jump; f/F/t/T enhanced with labels.
return {
  {
    "leap.nvim",
    dir = vim.fn.stdpath("data") .. "/lazy/leap.nvim",
    enabled = true,
    keys = function()
      local ret = {}
      for _, key in ipairs({ "f", "F", "t", "T" }) do
        ret[#ret + 1] = { key, mode = { "n", "x", "o" } }
      end
      return ret
    end,
    opts = { labeled_modes = "nx" },
  },
  {
    "leap.nvim",
    dir = vim.fn.stdpath("data") .. "/lazy/leap.nvim",
    enabled = true,
    keys = {
      { "s",  mode = { "n", "x", "o" }, desc = "Leap Forward" },
      { "S",  mode = { "n", "x", "o" }, desc = "Leap Backward" },
      { "gs", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      leap.add_default_mappings(true)
      -- Real leap sets x/X in visual/op-pending mode; remove so they don't
      -- shadow vim's native x (delete char) in those modes.
      pcall(vim.keymap.del, { "x", "o" }, "x")
      pcall(vim.keymap.del, { "x", "o" }, "X")
    end,
  },
}

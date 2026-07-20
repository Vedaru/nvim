-- ~/.config/nvim/lua/plugins/leap.lua
-- Minimal 2-char jump (zero-network), s/S/gs mappings.
-- f/F/t/T stay at Vim defaults; flash.nvim is not used.
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
      { "s",  mode = { "n", "x", "o" }, desc = "Leap Forward to" },
      { "S",  mode = { "n", "x", "o" }, desc = "Leap Backward to" },
      { "gs", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      leap.add_default_mappings(true)
      -- Best-effort: real leap.nvim sets x/X in visual/op-pending; ours doesn't.
      pcall(vim.keymap.del, { "x", "o" }, "x")
      pcall(vim.keymap.del, { "x", "o" }, "X")
      -- Wire s/S/gs to leap functions (lazy.nvim keys table only handles lazy-load trigger)
      vim.keymap.set({ "n", "x", "o" }, "s",  function() leap.leap()              end, { desc = "Leap Forward" })
      vim.keymap.set({ "n", "x", "o" }, "S",  function() leap.leap_backward()     end, { desc = "Leap Backward" })
      vim.keymap.set({ "n", "x", "o" }, "gs", function() leap.leap_from_windows() end, { desc = "Leap from Windows" })
    end,
  },
}

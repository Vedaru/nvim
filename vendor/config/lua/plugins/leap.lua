-- ~/.config/nvim/lua/plugins/leap.lua
-- Real leap.nvim (ggandor/leap.nvim), zero-network, Sneak-style mappings.
-- s/S forward/backward 2-char jump; gs from other windows.
return {
  {
    "leap.nvim",
    url = "https://codeberg.org/andyg/leap.nvim",
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
    url = "https://codeberg.org/andyg/leap.nvim",
    dir = vim.fn.stdpath("data") .. "/lazy/leap.nvim",
    enabled = true,
    keys = {
      { "s",  mode = { "n", "x", "o" }, desc = "Leap Forward" },
      { "S",  mode = { "n", "x", "o" }, desc = "Leap Backward" },
      { "gs", mode = "n",              desc = "Leap from Windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      -- Sneak-style: s forward, S backward, gs from other windows
      -- (add_default_mappings() is deprecated; use <Plug> keys instead)
      vim.keymap.set({ "n", "x", "o" }, "s",  "<Plug>(leap-forward)",      { desc = "Leap Forward" })
      vim.keymap.set({ "n", "x", "o" }, "S",  "<Plug>(leap-backward)",     { desc = "Leap Backward" })
      vim.keymap.set("n",              "gs", "<Plug>(leap-from-window)",   { desc = "Leap from Windows" })
      -- Exclusive pair for visual/operator-pending
      vim.keymap.set({ "x", "o" },      "x",  "<Plug>(leap-forward-till)",  { desc = "Leap Forward Till" })
      vim.keymap.set({ "x", "o" },      "X",  "<Plug>(leap-backward-till)", { desc = "Leap Backward Till" })
    end,
  },
}

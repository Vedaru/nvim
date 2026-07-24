--- Leap: Sneak-style s/S/gS jump motions.
return {
  {
    "leap.nvim",
    url = "https://codeberg.org/andyg/leap.nvim",
    dir = vim.fn.stdpath("data") .. "/lazy/leap.nvim",
    opts = { labeled_modes = "nx" },
    -- Override default f/F/t/T so they don't shadow our s/S mappings.
    keys = function()
      local ret = {}
      for _, key in ipairs({ "f", "F", "t", "T" }) do
        ret[#ret + 1] = { key, mode = { "n", "x", "o" } }
      end
      ret[#ret + 1] = { "s",  mode = { "n", "x", "o" }, desc = "Leap Forward" }
      ret[#ret + 1] = { "S",  mode = { "n", "x", "o" }, desc = "Leap Backward" }
      ret[#ret + 1] = { "gs", mode = "n",              desc = "Leap from Windows" }
      return ret
    end,
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      vim.keymap.set({ "n", "x", "o" }, "s",  "<Plug>(leap-forward)",      { desc = "Leap Forward" })
      vim.keymap.set({ "n", "x", "o" }, "S",  "<Plug>(leap-backward)",     { desc = "Leap Backward" })
      vim.keymap.set("n",              "gs", "<Plug>(leap-from-window)",   { desc = "Leap from Windows" })
      vim.keymap.set({ "x", "o" },      "x",  "<Plug>(leap-forward-till)",  { desc = "Leap Forward Till" })
      vim.keymap.set({ "x", "o" },      "X",  "<Plug>(leap-backward-till)", { desc = "Leap Backward Till" })
    end,
  },
}

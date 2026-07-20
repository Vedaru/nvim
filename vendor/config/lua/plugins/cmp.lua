return {
  {
    "hrsh7th/nvim-cmp",
    dir = vim.fn.stdpath("data") .. "/lazy/nvim-cmp",
    lazy = false,
    priority = 500,
    dependencies = {
      {
        "hrsh7th/cmp-buffer",
        dir = vim.fn.stdpath("data") .. "/lazy/cmp-buffer",
      },
      {
        "hrsh7th/cmp-path",
        dir = vim.fn.stdpath("data") .. "/lazy/cmp-path",
      },
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        sources = {
          { name = "buffer" },
          { name = "path" },
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
      })
    end,
  },
}

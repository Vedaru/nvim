-- 󰙅 Neo-tree: 侧边栏文件浏览器
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>",  desc = "󰙅 Explorer (Root Dir)" },
      { "<leader>E", "<cmd>Neotree toggle cwd<cr>", desc = "󰙅 Explorer (cwd)" },
    },
  },
}

-- Replace heavy lualine (12.67ms) with lightweight mini.statusline (~2ms)
return {
  "nvim-mini/mini.statusline",
  event = "VeryLazy",
  opts = {
    use_icons = true,
    set_vim_settings = true,
  },
}

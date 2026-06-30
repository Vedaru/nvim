-- ⚡ Buffer switching perf: debounce git status checks
return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      -- Debounce: only check git status every 500ms, not on every BufEnter
      watch_gitdir = {
        interval = 500,
        follow_files = true,
      },
      -- Skip files larger than 100KB (treesitter handles big files separately)
      max_file_length = 102400,
    },
  },
}

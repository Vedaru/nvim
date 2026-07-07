-- 补全（blink.cmp）键位定制
-- 主补全：Tab 确认、上下方向键选择、Enter 仅换行（不确认）
-- 命令行：上下方向键选择候选、Tab 确认
return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      -- super-tab 预设：<Tab> 接受补全、<Up>/<Down> 选择、不绑定 <CR>
      -- （LazyVim 会自动在 <Tab> 上追加 AI/snippet 接受逻辑）
      preset = "super-tab",
    },
    cmdline = {
      keymap = {
        preset = "cmdline",
        -- 方向键选择候选；菜单未弹出时回退为原生命令历史
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        -- Tab：菜单未弹出则弹出，已弹出则确认当前/首个候选
        ["<Tab>"] = { "show", "select_and_accept", "fallback" },
      },
    },
  },
}

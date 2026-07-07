-- mini.clue: lightweight which-key replacement
return {
  "nvim-mini/mini.clue",
  event = "VeryLazy",
  config = function()
    local miniclue = require("mini.clue")
    miniclue.setup({
      triggers = {
        { mode = "n", keys = "<Leader>" },
        { mode = "x", keys = "<Leader>" },
        { mode = "n", keys = "g" },
        { mode = "x", keys = "g" },
        { mode = "n", keys = "z" },
        { mode = "n", keys = "[" },
        { mode = "n", keys = "]" },
      },
      clues = {
        miniclue.gen_clues.g(),
        miniclue.gen_clues.z(),
        miniclue.gen_clues.builtin_completion(),
        miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        miniclue.gen_clues.windows(),
      },
      window = {
        delay = 0,
        config = {
          width = "auto",
          border = "rounded",
        },
      },
    })

    -- 用 TermOpen 补充（terminal buffer 无 FileType 事件）。
    -- 不用 BufEnter——避免每次切 buffer 都调用，影响性能。
    local group = vim.api.nvim_create_augroup("miniclue_triggers", { clear = true })
    vim.api.nvim_create_autocmd("TermOpen", {
      group = group,
      callback = function(args)
        vim.schedule(function()
          if vim.api.nvim_buf_is_loaded(args.buf) then
            pcall(miniclue.ensure_buf_triggers, args.buf)
          end
        end)
      end,
    })

    -- 启动时给当前 buffer 注册
    vim.schedule(function()
      pcall(miniclue.ensure_buf_triggers)
    end)
  end,
}

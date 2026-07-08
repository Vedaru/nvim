-- mini.clue: lightweight which-key replacement
return {
  "nvim-mini/mini.clue",
  lazy = false,
  priority = 10000,
  config = function()
    local miniclue = require("mini.clue")

    local function ensure_all_triggers()
      pcall(miniclue.ensure_buf_triggers)
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          pcall(miniclue.ensure_buf_triggers, buf)
        end
      end
    end

    -- 启动时一次性展开 gen_clues，避免每次按 <leader> 重新调用 gen_clues.g() 等函数
    local static_clues = {
      miniclue.gen_clues.g(),
      miniclue.gen_clues.z(),
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.windows(),
    }

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
      clues = static_clues,
      window = {
        delay = 0,
        config = {
          width = 60,
          border = "rounded",
        },
      },
    })

    local group = vim.api.nvim_create_augroup("miniclue_triggers", { clear = true })

    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = group,
      callback = function(args)
        if vim.api.nvim_buf_is_loaded(args.buf) and vim.fn.buflisted(args.buf) == 1 then
          pcall(miniclue.ensure_buf_triggers, args.buf)
        end
      end,
    })

    vim.api.nvim_create_autocmd("TermOpen", {
      group = group,
      callback = function(args)
        if vim.api.nvim_buf_is_loaded(args.buf) then
          pcall(miniclue.ensure_buf_triggers, args.buf)
        end
      end,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = group,
      callback = function(args)
        vim.schedule(function()
          if vim.api.nvim_buf_is_loaded(args.buf) then
            pcall(miniclue.ensure_buf_triggers, args.buf)
          end
        end)
      end,
    })

    local function refresh_triggers()
      ensure_all_triggers()
    end

    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      callback = function()
        pcall(miniclue.ensure_buf_triggers)
      end,
    })

    vim.api.nvim_create_autocmd("WinEnter", {
      group = group,
      callback = function()
        pcall(miniclue.ensure_buf_triggers)
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "VeryLazy",
      once = true,
      callback = function()
        -- 晚于 LazyVim keymaps 及其他 VeryLazy 插件的 schedule 回调
        vim.defer_fn(function()
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " })
          local win = vim.api.nvim_open_win(buf, false, {
            relative = "editor",
            width = 1,
            height = 1,
            row = 0,
            col = 0,
            border = "rounded",
            noautocmd = true,
          })
          pcall(vim.api.nvim_win_close, win, true)
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
          refresh_triggers()
        end, 150)
      end,
    })

    refresh_triggers()
  end,
}

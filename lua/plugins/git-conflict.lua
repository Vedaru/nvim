--- Git conflict: scanner, quickfix, and navigation.
--- All logic lives in config/git-conflict.lua.

local GC = require("config.git-conflict")

return {
  {
    "akinsho/git-conflict.nvim",
    keys = {
      {
        "<leader>gC",
        function()
          local qf_win = false
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "qf" then
              qf_win = true
              break
            end
          end
          if qf_win then
            vim.cmd("cclose")
          else
            GC.refresh(true)
          end
        end,
        desc = "Git Conflicts (Toggle Quickfix)",
      },
      { "]x", function() GC.navigate("next") end, desc = "Next Conflict (Global)" },
      { "[x", function() GC.navigate("prev") end, desc = "Previous Conflict (Global)" },
      { ".o", function() require("git-conflict").choose("ours") end,   desc = "Choose Ours" },
      { ".t", function() require("git-conflict").choose("theirs") end, desc = "Choose Theirs" },
      { ".b", function() require("git-conflict").choose("both") end,   desc = "Choose Both" },
      { ".0", function() require("git-conflict").choose("none") end,   desc = "Choose None" },
    },
    opts = {
      list_opener = nil,
      default_mappings = false,
    },
    config = function(_, opts)
      require("git-conflict").setup(opts)

      vim.api.nvim_create_autocmd("User", {
        pattern = "GitConflictResolved",
        callback = function()
          vim.defer_fn(function() pcall(GC.refresh, false) end, 100)
        end,
      })

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("GitConflictRefresh", { clear = true }),
        callback = function()
          if vim.fn.finddir(".git", ".;") ~= "" then
            pcall(GC.refresh, false)
          end
        end,
      })

      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("GitConflictSyncQf", { clear = true }),
        callback = function()
          if #GC.qf_files > 0 then
            GC.sync_qf_idx()
          end
        end,
      })

      -- Fix E925 in quickfix: manual <CR> handler.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function()
          vim.keymap.set("n", "<CR>", function()
            local line = vim.api.nvim_win_get_cursor(0)[1]
            local item = (vim.fn.getqflist())[line]
            if item and item.valid == 1 then
              local fname = vim.api.nvim_buf_get_name(item.bufnr)
              vim.cmd("wincmd p")
              vim.cmd("edit " .. vim.fn.fnameescape(fname))
              vim.api.nvim_win_set_cursor(0, { item.lnum, 0 })
              vim.cmd("normal! zz")
              pcall(vim.fn.setqflist, {}, "a", { idx = line })
            else
              vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false
              )
            end
          end, { buffer = true, silent = true })
        end,
      })
    end,
  },
}

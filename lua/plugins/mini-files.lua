-- ~/.config/nvim/lua/plugins/mini-files.lua
return {
  "nvim-mini/mini.files",
  version = false,
  lazy = false,
  keys = {
    { "<leader>e", desc = "Toggle file browser (project root)" },
  },
  opts = {
    windows = {
      preview = false,
      width_focus = 35,
      width_nofocus = 15,
    },
    options = {
      use_as_default_explorer = false,
    },
  },
  config = function(_, opts)
    local MiniFiles = require("mini.files")
    MiniFiles.setup(opts)

    local chroot = nil

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        local buf = args.data.buf_id
        if not chroot then return end
        local function block_go_out()
          local cur = vim.api.nvim_buf_get_name(buf)
          cur = cur:gsub("^minifiles://", "")
          if cur:gsub("/+$", "") == chroot:gsub("/+$", "") then
            vim.notify("At project root", vim.log.levels.WARN, { title = "mini.files" })
            return true
          end
          return false
        end
        vim.keymap.set("n", "-", function()
          if not block_go_out() then MiniFiles.go_out() end
        end, { buffer = buf })
        vim.keymap.set("n", "h", function()
          if not block_go_out() then MiniFiles.go_out() end
        end, { buffer = buf })
      end,
    })

    vim.keymap.set("n", "<leader>e", function()
      if MiniFiles.close() then return end
      local ok, P = pcall(require, "persistence")
      if ok and P._active_dir and vim.fn.isdirectory(P._active_dir) == 1 then
        chroot = P._active_dir
      else
        local fname = vim.api.nvim_buf_get_name(0)
        chroot = (fname ~= "" and vim.bo.buftype == "")
            and vim.fn.fnamemodify(fname, ":h")
            or vim.fn.getcwd()
      end
      MiniFiles.open(chroot)
    end, { desc = "Toggle file browser (project root)" })
  end,
}

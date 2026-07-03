-- ~/.config/nvim/lua/plugins/snacks.lua
local project_root = function()
  local ok, P = pcall(require, "persistence")
  if ok and P._active_dir then return P._active_dir end
  local buf = vim.api.nvim_buf_get_name(0)
  if vim.bo[0].buftype == "" and buf ~= "" then
    return vim.fs.root(buf, ".git") or vim.fn.fnamemodify(buf, ":h")
  end
  return vim.fn.getcwd()
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        hidden = true,
        ignored = true,
        follow = false, -- pin at git root; never chase buffers
      },
      picker = {
        hidden = true,
        ignored = true,
        follow = true,
        sources = {
          git_diff = {
            -- Suppress "Command failed" noise when outside a git repo.
            -- The picker shows "No results" anyway — no need for a red error.
            notify = false,
          },
        },
      },
      dashboard = {
        preset = {
          header = [[
██╗   ██╗███████╗██████╗  █████╗ ██████╗ ██╗   ██╗
██║   ██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██║   ██║
██║   ██║█████╗  ██║  ██║███████║██████╔╝██║   ██║
╚██╗ ██╔╝██╔══╝  ██║  ██║██╔══██║██╔══██╗██║   ██║
 ╚████╔╝ ███████╗██████╔╝██║  ██║██║  ██║╚██████╔╝
  ╚═══╝  ╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
          ]],
        },
      },
      -- Disable auto_insert so terminal stays in normal mode after <Esc><Esc>,
      -- allowing which-key's <Space> trigger to work.
      -- Replace LazyVim's buggy term_nav() mappings with direct <cmd> variants.
      -- Must include expr=true because snacks wraps string RHS in a function
      -- whose return value is ignored without it.
      -- auto_close=false: suppress "Terminal exited" notification on session switch
      terminal = {
        auto_insert = false,
        auto_close = false,
        win = {
          keys = {
            nav_h = { "<C-h>", "<cmd>wincmd h<cr>", desc = "Go to Left Window", mode = "t", expr = true },
            nav_j = { "<C-j>", "<cmd>wincmd j<cr>", desc = "Go to Lower Window", mode = "t", expr = true },
            nav_k = { "<C-k>", "<cmd>wincmd k<cr>", desc = "Go to Upper Window", mode = "t", expr = true },
            nav_l = { "<C-l>", "<cmd>wincmd l<cr>", desc = "Go to Right Window", mode = "t", expr = true },
          },
        },
      },
    },
    keys = {
      -- <leader>e: toggle explorer at project root
      {
        "<leader>e",
        function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_explorer" then
              return vim.api.nvim_win_close(win, true)
            end
          end
          Snacks.explorer.open({ cwd = project_root() })
        end,
        desc = "Toggle Explorer",
      },
      -- <leader>E: open explorer at CWD (fallback)
      {
        "<leader>E",
        function()
          Snacks.explorer.open({
            cwd = vim.fn.getcwd(),
          })
        end,
        desc = "Explorer (cwd)",
      },
      -- 查找类：基于 snacks.picker，统一使用 project_root()
      {
        "<leader>gd",
        function()
          Snacks.picker.git_diff({ cwd = project_root() })
        end,
        desc = "Git Diff (hunks)",
      },
      {
        "<leader>gD",
        function()
          Snacks.picker.git_diff({ cwd = project_root(), base = "origin", group = true })
        end,
        desc = "Git Diff (origin)",
      },
      {
        "<leader>ff",
        function()
          require("snacks.picker").files({ cwd = project_root() })
        end,
        silent = true,
        desc = "Find files",
      },
      {
        "<leader>fg",
        function()
          require("snacks.picker").grep({ cwd = project_root() })
        end,
        silent = true,
        desc = "Live grep",
      },
      {
        "<leader>fb",
        function()
          require("snacks.picker").buffers()
        end,
        silent = true,
        desc = "Find buffers",
      },
      {
        "<leader>fr",
        function()
          require("snacks.picker").recent()
        end,
        silent = true,
        desc = "Recent files",
      },
      -- <leader>fF: 用 Everything (es.exe) 实时搜索【整台电脑】的文件名
      {
        "<leader>fF",
        function()
          local instance = "1.5a" -- Everything 1.5 alpha 的命名实例
          local es = vim.fn.exepath("es")
          if es == "" then
            vim.notify(
              "Everything CLI (es.exe) not found. Make sure it is installed and on your PATH.",
              vim.log.levels.ERROR
            )
            return
          end

          -- 通过 es 能否连上来判断 Everything 是否已在运行
          local function es_ready()
            vim.fn.system({ es, "-instance", instance, "-n", "1" })
            return vim.v.shell_error == 0
          end

          -- 若没运行则通过“最高权限”计划任务无 UAC 启动它，并标记“是我们启动的”
          -- （计划任务 EverythingStart / EverythingExit 需用管理员 PowerShell 一次性创建）
          local started_by_us = false
          if not es_ready() then
            vim.fn.jobstart({ "schtasks", "/run", "/tn", "EverythingStart" }, { detach = true })
            started_by_us = true
            if not vim.wait(6000, es_ready, 200) then -- 等待启动+索引就绪（最多 6s）
              vim.notify(
                "Could not reach Everything. Create the 'EverythingStart' scheduled task (one-time admin setup).",
                vim.log.levels.WARN
              )
            end
          end

          Snacks.picker.pick({
            source = "everything",
            title = "Everything",
            live = true, -- 输入即重新查询 es
            supports_live = true,
            finder = function(_, ctx)
              local search = vim.trim(ctx.filter.search or "")
              if search == "" then
                return function() end
              end
              -- -n 500 限制条数保证流畅
              local args = { "-instance", instance, "-n", "500" }
              for _, term in ipairs(vim.split(search, " ", { plain = true, trimempty = true })) do
                args[#args + 1] = term
              end
              return require("snacks.picker.source.proc").proc({
                cmd = es,
                args = args,
                notify = false,
                transform = function(item)
                  item.file = item.text -- es 输出的是完整路径
                end,
              }, ctx)
            end,
            formatters = { file = { filename_first = true } },
            -- 仅当是本次自动启动的，才在 picker 关闭时退出 Everything（同样走计划任务，无 UAC）
            on_close = started_by_us and function()
              vim.fn.jobstart({ "schtasks", "/run", "/tn", "EverythingExit" }, { detach = true })
            end or nil,
          })
        end,
        silent = true,
        desc = "Find files on whole PC (Everything)",
      },
    },
  },
}

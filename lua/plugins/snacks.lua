-- ~/.config/nvim/lua/plugins/snacks.lua
local project_root = function()
  return require("config.session").project_root()
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        enabled = false,
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
        -- 不显示快捷选项、q 退出 nvim 等行为已在 snacks 源码里改好
        -- (defaults.sections 去掉 keys 段、preset.keys 清空、D:init q -> :qa)，
        -- build.sh 会把改过的 snacks.nvim 一起打包，重装不丢。
      },
      -- Disable auto_insert so terminal stays in normal mode after <Esc><Esc>,
      -- allowing which-key's <Space> trigger to work.
      -- Replace LazyVim's buggy term_nav() mappings with direct <cmd> variants.
      -- Must include expr=true because snacks wraps string RHS in a function
      -- whose return value is ignored without it.
      -- auto_close=false: suppress "Terminal exited" notification on session switch
      terminal = {
        enabled = true,
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
      -- WSL 兼容：跳过 schtasks，直接启动 Everything.exe，并转换 Windows 路径为 /mnt/ 路径
      {
        "<leader>fF",
        function()
          local instance = "1.5a" -- Everything 1.5 alpha 的命名实例
          local es = vim.fn.exepath("es.exe") ~= "" and vim.fn.exepath("es.exe")
            or vim.fn.exepath("es") ~= "" and vim.fn.exepath("es")
            or (vim.fn.executable("/mnt/d/Everything/es.exe") == 1 and "/mnt/d/Everything/es.exe")
            or (vim.fn.executable("/mnt/c/Program Files/Everything/es.exe") == 1 and "/mnt/c/Program Files/Everything/es.exe")
            or nil
          if not es then
            vim.notify(
              "Everything CLI (es.exe) not found. Make sure it is installed and on your PATH.",
              vim.log.levels.ERROR
            )
            return
          end

          -- WSL 检测
          local is_wsl = vim.fn.filereadable("/proc/sys/fs/binfmt_misc/WSLInterop") == 1

          -- 路径转换：Windows → WSL（例如 C:\foo → /mnt/c/foo）
          local function to_wsl_path(win_path)
            if not is_wsl then return win_path end
            local drive, rest = win_path:match("^(%a):(.+)$")
            if drive then
              return "/mnt/" .. drive:lower() .. (rest:gsub("\\", "/"))
            end
            return win_path
          end

          -- 通过 es 能否连上来判断 Everything 是否已在运行
          local function es_ready()
            vim.fn.system({ es, "-instance", instance, "-n", "1" })
            return vim.v.shell_error == 0
          end

          local started_by_us = false
          if not es_ready() then
            if is_wsl then
              -- WSL：直接启动 Windows 版 Everything.exe
              -- 常见安装路径：Program Files、用户目录、scoop/choco
              local candidates = {
                "/mnt/c/Program Files/Everything 1.5a/Everything.exe",
                "/mnt/c/Program Files/Everything/Everything.exe",
                "/mnt/d/Everything/Everything.exe",
              }
              for _, path in ipairs(candidates) do
                if vim.fn.executable(path) == 1 then
                  vim.fn.jobstart({ path, "-instance", instance, "-startup" }, { detach = true })
                  started_by_us = true
                  break
                end
              end
              if started_by_us then
                if not vim.wait(6000, es_ready, 200) then
                  vim.notify(
                    "Everything did not start in time. Start it manually.",
                    vim.log.levels.WARN
                  )
                end
              else
                vim.notify(
                  "Everything is not running. Start Everything manually first.",
                  vim.log.levels.WARN
                )
              end
            else
              -- Windows：通过“最高权限”计划任务无 UAC 启动
              -- （计划任务 EverythingStart / EverythingExit 需用管理员 PowerShell 一次性创建）
              vim.fn.jobstart({ "schtasks", "/run", "/tn", "EverythingStart" }, { detach = true })
              started_by_us = true
              if not vim.wait(6000, es_ready, 200) then
                vim.notify(
                  "Could not reach Everything. Create the 'EverythingStart' scheduled task (one-time admin setup).",
                  vim.log.levels.WARN
                )
              end
            end
          end

          Snacks.picker.pick({
            source = "everything",
            title = "Everything",
            live = true,
            supports_live = true,
            finder = function(_, ctx)
              local search = vim.trim(ctx.filter.search or "")
              if search == "" then
                return function() end
              end
              local args = { "-instance", instance, "-n", "500" }
              -- 用户没加搜索修饰符、也没写路径时，默认用 startwith: 匹配文件名前缀
              -- 这样搜 "Github" 直接命中项目目录，不会被 .github / node_modules 淹没
              local has_modifier = search:find("^[%w]+:") or search:find("!")
              local has_path = search:find("[\\/]")
              local query = (has_modifier or has_path) and search or ("startwith:" .. search)
              local terms = vim.split(query, " ", { plain = true, trimempty = true })
              for _, term in ipairs(terms) do
                args[#args + 1] = term
              end
              return require("snacks.picker.source.proc").proc({
                cmd = es,
                args = args,
                notify = false,
                transform = function(item)
                  item.file = to_wsl_path(item.text)
                end,
              }, ctx)
            end,
            formatters = { file = { filename_first = true } },
            on_close = started_by_us and function()
              if is_wsl then
                -- WSL：Nothing to do; Everything runs as a Windows background process
              else
                vim.fn.jobstart({ "schtasks", "/run", "/tn", "EverythingExit" }, { detach = true })
              end
            end or nil,
          })
        end,
        silent = true,
        desc = "Find files on whole PC (Everything)",
      },
    },
  },
}

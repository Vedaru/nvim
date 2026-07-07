-- Neovim 0.12 内置 LSP 补全 — 用 autocmd 确保触发
local group = vim.api.nvim_create_augroup("BuiltinCmp", { clear = true })
local enabled = {}

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method("textDocument/completion") then
      return
    end
    local key = client.id .. ":" .. args.buf
    if enabled[key] then
      return
    end
    enabled[key] = true

    -- 让所有可打印字符触发补全
    local chars = {}
    for i = 32, 126 do
      table.insert(chars, string.char(i))
    end
    client.server_capabilities.completionProvider.triggerCharacters = chars

    vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })

    vim.keymap.set("i", "<Tab>", function()
      if vim.fn.complete_info({ "selected" }).selected ~= -1 then
        return "<C-y>"
      end
      return "<Tab>"
    end, { buffer = args.buf, expr = true, desc = "Accept completion" })
  end,
})

return {}

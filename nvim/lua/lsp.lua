vim.lsp.enable("clangd")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local buf = args.buf
    local map = vim.keymap.set
    local buf = args.buf

    -- key mapping
    map("n", "gd", vim.lsp.buf.definition, { buffer = buf })
    map("n", "gD", vim.lsp.buf.declaration, { buffer = buf })
    map("n", "gi", vim.lsp.buf.implementation, { buffer = buf })
    map("n", "gr", vim.lsp.buf.references, { buffer = buf })
    map("n", "K", vim.lsp.buf.hover, { buffer = buf })
    map("n", "<leader>rn", vim.lsp.buf.rename, { buffer = buf })
    map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf })

    -- enable completion
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, args.data.client_id, buf, {
        autotrigger = true,
      })
    end
  end,
})

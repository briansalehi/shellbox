local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- pass cmp capabilities to all servers before enabling any
vim.lsp.config('*', { capabilities = capabilities })

vim.lsp.config('clangd', {
    cmd = { 'clangd', '--background-index', '--clang-tidy', '--header-insertion=iwyu' },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
    root_markers = { 'compile_commands.json', '.clangd', 'CMakeLists.txt', '.git' },
})

vim.lsp.enable("clangd")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local buf = args.buf
    local map = vim.keymap.set

    -- key mapping
    map("n", "gd", vim.lsp.buf.definition, { buffer = buf })
    map("n", "gD", vim.lsp.buf.declaration, { buffer = buf })
    map("n", "gi", vim.lsp.buf.implementation, { buffer = buf })
    map("n", "gr", vim.lsp.buf.references, { buffer = buf })
    map("n", "K", vim.lsp.buf.hover, { buffer = buf })
    map("n", "<leader>rn", vim.lsp.buf.rename, { buffer = buf })
    map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf })
    map("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, { buffer = buf, desc = "Format buffer" })
    map("v", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, { buffer = buf, desc = "Format selection" })
    map("n", "gl", vim.diagnostic.open_float, { buffer = buf })
    map("n", "]d", vim.diagnostic.goto_next, { buffer = buf })
    map("n", "[d", vim.diagnostic.goto_prev, { buffer = buf })

    -- signature help
    if client:supports_method("textDocument/signatureHelp") then
      map("i", "<C-s>", vim.lsp.buf.signature_help, { buffer = buf })
    end
  end,
})

-- clangd extensions
require("clangd_extensions").setup({
    inlay_hints = {
        inline = true,
        only_current_line = false,
        only_current_line_autocmd = { "CursorHold" },
        show_parameter_hints = true,
        parameter_hints_prefix = "<- ",
        other_hints_prefix = "=> ",
    },
    ast = {
        role_icons = {
            type = "",
            declaration = "",
            expression = "",
            specifier = "",
            statement = "",
            ["template argument"] = "",
        },
        kind_icons = {
            Compound = "",
            Recovery = "",
            TranslationUnit = "",
            PackExpansion = "",
            TemplateTypeParm = "",
            TemplateTemplateParm = "",
            TemplateParamObject = "",
        },
    },
    memory_usage = { border = "rounded" },
    symbol_info  = { border = "rounded" },
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "clangd" then
            local buf = args.buf
            local map = vim.keymap.set
            map("n", "<leader>lh", "<cmd>ClangdToggleInlayHints<CR>",   { buffer = buf, desc = "Toggle inlay hints" })
            map("n", "<leader>ls", "<cmd>ClangdSwitchSourceHeader<CR>", { buffer = buf, desc = "Switch source/header" })
            map("n", "<leader>la", "<cmd>ClangdAST<CR>",                { buffer = buf, desc = "Show AST" })
            map("n", "<leader>lm", "<cmd>ClangdMemoryUsage<CR>",        { buffer = buf, desc = "Memory usage" })
            map("n", "<leader>lt", "<cmd>ClangdTypeHierarchy<CR>",      { buffer = buf, desc = "Type hierarchy" })
            map("n", "<leader>lS", "<cmd>ClangdSymbolInfo<CR>",         { buffer = buf, desc = "Symbol info" })
            map("n", "<leader>li", function()
                vim.lsp.buf.code_action({
                    apply = true,
                    filter = function(action)
                        return action.title and action.title:match("Define in source file")
                    end,
                })
            end, { buffer = buf, desc = "Implement function in source file" })
            map("n", "<leader>lI", function()
                vim.lsp.buf.code_action({
                    apply = true,
                    filter = function(action)
                        return action.title and action.title:match("Move function body to declaration")
                    end,
                })
            end, { buffer = buf, desc = "Implement function inline at declaration" })
        end
    end,
})

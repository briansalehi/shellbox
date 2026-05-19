local opt = vim.opt

opt.number = true
opt.relativenumber = false
opt.smarttab = true
opt.expandtab = true
opt.termguicolors = true
opt.splitright = true
opt.splitbelow = true
opt.cursorline = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.signcolumn = "yes"

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "\u{F057}",
            [vim.diagnostic.severity.WARN]  = "\u{F071}",
            [vim.diagnostic.severity.INFO]  = "\u{F05A}",
            [vim.diagnostic.severity.HINT]  = "\u{F0EB}",
        },
    },
})
opt.updatetime = 250
opt.completeopt = "menu,noselect"
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.mouse = ""

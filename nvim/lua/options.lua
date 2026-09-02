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
opt.scrolloff = 8

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
opt.undofile = true

-- fold the leading license/copyright comment block
local function header_range(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, 100, false)
    local s = 1
    while lines[s] and (lines[s]:match("^%s*$") or lines[s]:match("^#!")) do
        s = s + 1
    end
    if not lines[s] then return nil end

    local e
    if lines[s]:match("^%s*/%*") then                 -- /* ... */ block
        e = s
        while lines[e] and not lines[e]:match("%*/") do e = e + 1 end
        if not lines[e] then return nil end
    else
        -- base comment marker, so /// //! and //=== banners all continue a
        -- // header instead of ending it
        local lead = lines[s]:match("^%s*(//)") or lines[s]:match("^%s*(#)")
            or lines[s]:match("^%s*(%-%-)") or lines[s]:match("^%s*(;)")
            or lines[s]:match("^%s*(%%)") or lines[s]:match('^%s*(")')
        if not lead then return nil end
        e = s
        while lines[e + 1] and lines[e + 1]:match("^%s*" .. vim.pesc(lead)) do e = e + 1 end
    end

    if e - s < 1 then return nil end                  -- ignore one-liners
    local text = table.concat(lines, "\n", s, e):lower()
    if not text:match("copyright") and not text:match("licen[sc]e")
        and not text:match("spdx") then return nil end
    return s, e
end

local header_fold_group = vim.api.nvim_create_augroup("HeaderFold", { clear = true })

-- reloading a buffer discards its manual folds, so let the header be folded again
vim.api.nvim_create_autocmd("BufReadPost", {
    group = header_fold_group,
    callback = function() vim.w.header_folded = nil end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = header_fold_group,
    callback = function(args)
        if vim.bo[args.buf].buftype ~= "" then return end
        -- folds are window-local, so remember per window which buffer we
        -- already folded: a split gets its own fold, but reopening the
        -- header with zo in this window sticks
        if vim.w.header_folded == args.buf then return end
        vim.w.header_folded = args.buf
        local s, e = header_range(args.buf)
        if not s then return end
        vim.wo.foldmethod = "manual"
        vim.wo.foldenable = true
        vim.cmd(string.format("%d,%dfold", s, e))

        -- the cursor sitting inside a freshly created fold makes something
        -- later in startup reopen it ('foldopen'), so close it again once
        -- everything else has run
        local win = vim.api.nvim_get_current_win()
        vim.schedule(function()
            if not vim.api.nvim_win_is_valid(win) then return end
            vim.api.nvim_win_call(win, function()
                if vim.fn.foldlevel(s) > 0 and vim.fn.foldclosed(s) == -1 then
                    pcall(vim.cmd, string.format("%dfoldclose", s))
                end
            end)
        end)
    end,
})

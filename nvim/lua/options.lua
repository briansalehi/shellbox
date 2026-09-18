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

-- every float that does not set its own border gets one: lsp hover, signature
-- help, diagnostics, telescope-ui-select. telescope, cmp and which-key set
-- border="none" explicitly, so they are unaffected rather than double-bordered.
opt.winborder = "rounded"

-- one statusline for the whole editor instead of one per window: splitting no
-- longer repeats the bar, and horizontal splits gain a separator line, which
-- nvim only draws in this mode (it used the per-window statusline as the
-- divider before). lualine reads laststatus at setup() and turns on
-- globalstatus to match, so options must stay required before plugins.
opt.laststatus = 3

-- always draw the tabline, even for a single tab. With the default 1 it appears
-- the moment a second tabpage exists, which costs every window on every tab a
-- row: opening neogit (kind = "tab") and coming back shrinks the agent terminal
-- by one line, resizing its pty and making the TUI reflow into duplicate lines.
-- A row that is always there never triggers a resize. Use 0 instead to hide the
-- tabline entirely; what must not happen is toggling between the two.
opt.showtabline = 2

-- the box-drawing characters are already nvim's defaults; these are the ones
-- that are not: blank out the ~ tildes past the last line and the dots that
-- pad foldtext, and hatch removed diff lines instead of filling them with -
opt.fillchars = { eob = " ", fold = " ", diff = "\u{2571}" }

-- Diagnostic messages under the cursor's line. The built-in virtual_lines
-- handler indents continuation lines to the diagnostic's column, so a long
-- message runs off the right edge; this handler wraps at the window width
-- and starts continuation lines at column 0.
local wrapped_ns = vim.api.nvim_create_namespace("wrapped_diagnostic_lines")
local wrapped_hl = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticVirtualLinesError",
    [vim.diagnostic.severity.WARN]  = "DiagnosticVirtualLinesWarn",
    [vim.diagnostic.severity.INFO]  = "DiagnosticVirtualLinesInfo",
    [vim.diagnostic.severity.HINT]  = "DiagnosticVirtualLinesHint",
}

local function wrap_words(text, first_width, width)
    local out, cur, limit = {}, "", first_width
    for word in text:gmatch("%S+") do
        if cur ~= "" and vim.fn.strdisplaywidth(cur .. " " .. word) > limit then
            table.insert(out, cur)
            cur, limit = word, width
        else
            cur = cur == "" and word or cur .. " " .. word
        end
    end
    if cur ~= "" then table.insert(out, cur) end
    return out
end

local function render_wrapped(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, wrapped_ns, 0, -1)
    local win = vim.fn.bufwinid(bufnr)
    if win == -1 then return end
    local width = vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff
    local lnum = vim.api.nvim_win_get_cursor(win)[1] - 1
    local virt_lines = {}
    for _, d in ipairs(vim.diagnostic.get(bufnr, { lnum = lnum })) do
        local hl = wrapped_hl[d.severity]
        local msg = d.code and string.format("%s: %s", d.code, d.message) or d.message
        local prefix = string.rep(" ", d.col) .. "\u{2514}\u{2500}\u{2500}\u{2500}\u{2500} "
        local first = math.max(width - vim.fn.strdisplaywidth(prefix), 20)
        for para in msg:gmatch("[^\n]+") do
            for _, line in ipairs(wrap_words(para, first, math.max(width, 20))) do
                if prefix then
                    table.insert(virt_lines, { { prefix, hl }, { line, hl } })
                    prefix = nil
                else
                    table.insert(virt_lines, { { line, hl } })
                end
            end
        end
    end
    if #virt_lines > 0 then
        vim.api.nvim_buf_set_extmark(bufnr, wrapped_ns, lnum, 0, { virt_lines = virt_lines })
    end
end

local wrapped_group = vim.api.nvim_create_augroup("wrapped_diagnostic_lines", {})
vim.diagnostic.handlers.wrapped_lines = {
    show = function(_, bufnr)
        vim.api.nvim_clear_autocmds({ group = wrapped_group, buffer = bufnr })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinResized" }, {
            group = wrapped_group,
            buffer = bufnr,
            callback = function() render_wrapped(bufnr) end,
        })
        render_wrapped(bufnr)
    end,
    hide = function(_, bufnr)
        vim.api.nvim_clear_autocmds({ group = wrapped_group, buffer = bufnr })
        vim.api.nvim_buf_clear_namespace(bufnr, wrapped_ns, 0, -1)
    end,
}

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "\u{F057}",
            [vim.diagnostic.severity.WARN]  = "\u{F071}",
            [vim.diagnostic.severity.INFO]  = "\u{F05A}",
            [vim.diagnostic.severity.HINT]  = "\u{F0EB}",
        },
    },
    virtual_lines = false,
    wrapped_lines = true,
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

vim.filetype.add({
    extension = {
        ato = "python",
        service = "systemd",
    },
})

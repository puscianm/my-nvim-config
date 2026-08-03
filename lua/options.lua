require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

vim.opt.relativenumber = true
vim.opt.scrolloff = 8        -- keeps cursor 8 lines from top/bottom when scrolling
vim.opt.signcolumn = "yes"   -- gutter always visible, prevents layout jumping
vim.opt.wrap = false         -- no line wrapping
vim.opt.expandtab = true     -- spaces instead of tabs
vim.opt.tabstop = 4          -- 4 spaces per tab
vim.opt.shiftwidth = 4       -- 4 spaces per indent
vim.opt.undofile = true      -- persistent undo history across sessions
vim.opt.ignorecase = true    -- case-insensitive search...
vim.opt.smartcase = true     -- ...unless you type uppercaseim.opt.number = true

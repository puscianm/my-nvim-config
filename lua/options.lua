require "nvchad.options"

local o = vim.o

o.relativenumber = true
o.scrolloff = 8 -- keeps cursor 8 lines from top/bottom when scrolling
o.signcolumn = "yes" -- gutter always visible, prevents layout jumping
o.wrap = false -- no line wrapping
o.cursorlineopt = "both" -- highlight the line and its number

o.expandtab = true -- spaces instead of tabs
o.tabstop = 4 -- 4 spaces per tab
o.shiftwidth = 4 -- 4 spaces per indent

o.undofile = true -- persistent undo history across sessions

o.ignorecase = true -- case-insensitive search...
o.smartcase = true -- ...unless you type uppercase

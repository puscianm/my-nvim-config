require "nvchad.mappings"

local map = vim.keymap.set

map("i", "jk", "<ESC>")
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader><leader>", "gt", { desc = "Go to next tab" })
map("n", "<leader>cs", "<cmd>Cheatsheet<cr>", { desc = "Cheatsheet" })

-- Terminal. <leader>ft toggles the float; <leader>f<n>t opens the n-th instance.
map("n", "<leader>ft", "<cmd>ToggleTerm<cr>", { desc = "Toggle floating terminal" })
for i = 1, 9 do
  map("n", "<leader>f" .. i .. "t", "<cmd>" .. i .. "ToggleTerm<cr>", { desc = "Toggle floating terminal " .. i })
end
map("t", "<Esc><Esc>", "<cmd>ToggleTerm<cr>", { desc = "Hide floating terminal" })

-- live grep with ripgrep args, e.g. `TODO --iglob *.py`
map("n", "<leader>fw", function()
  require("telescope").extensions.live_grep_args.live_grep_args()
end, { desc = "Live grep (with rg args)" })

map("n", "<leader>fb", "<cmd>Telescope file_browser<cr>", { desc = "File browser" })

-- Browse other branches read-only (see configs/git_browse.lua)
local function git_browse(fn)
  return function()
    require("configs.git_browse")[fn]()
  end
end
map("n", "<leader>gf", git_browse "files", { desc = "Git: find file on another branch" })
map("n", "<leader>gt", git_browse "tree", { desc = "Git: browse tree of another branch" })
map("n", "<leader>gD", git_browse "diff_current", { desc = "Git: diff this file vs branch" })

-- Close every other buffer without switching windows. NvChad's
-- closeAllBufs() moves the current window mid-loop, which wipes fugitive
-- buffers (they set bufhidden=delete) and leaves you in a diff buffer.
map("n", "<leader>X", function()
  local cur = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.t.bufs or {}) do
    if buf ~= cur and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, {})
    end
  end
  vim.cmd "redrawtabline"
end, { desc = "Close all buffers but current" })

map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover docs" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })

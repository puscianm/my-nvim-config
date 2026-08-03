require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("i", "jk", "<ESC>")
map("n", "<leader>cs", "<cmd>Cheatsheet<cr>")
map("n", "<leader>ft", "<cmd>ToggleTerm<cr>", { desc = "Toggle floating terminal" })

-- live grep with ripgrep args, e.g. `TODO --iglob *.py`
map("n", "<leader>fw", function()
  require("telescope").extensions.live_grep_args.live_grep_args()
end, { desc = "Live grep (with rg args)" })

-- <leader>f<number>t opens the k-th floating terminal instance
for i = 1, 9 do
  map("n", "<leader>f" .. i .. "t", "<cmd>" .. i .. "ToggleTerm<cr>", { desc = "Toggle floating terminal " .. i })
end

map("t", "<Esc><Esc>", "<cmd>ToggleTerm<cr>", { desc = "Hide floating terminal" })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

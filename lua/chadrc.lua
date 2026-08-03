-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 
---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "onedark",
  -- hl_override = {
  --   Comment = { italic = true },
  --   ["@comment"] = { italic = true },
  -- },
}

M.ui = {
  tabufline = {
    modules = {
      buffers = function()
        local buffers = {}
        local has_current = false
        vim.t.bufs = vim.tbl_filter(vim.api.nvim_buf_is_valid, vim.t.bufs)

        local opts = require("nvconfig").ui.tabufline
        local style_buf = require("nvchad.tabufline.utils").style_buf
        local txt = require("nvchad.tabufline.utils").txt

        local function available_space()
          return vim.o.columns - 30
        end

        for i, nr in ipairs(vim.t.bufs) do
          if vim.bo[nr].buftype ~= "terminal" then
            if ((#buffers + 1) * opts.bufwidth) > available_space() then
              if has_current then break end
              table.remove(buffers, 1)
            end
            has_current = vim.api.nvim_get_current_buf() == nr or has_current
            table.insert(buffers, style_buf(nr, i, opts.bufwidth))
          end
        end

        return table.concat(buffers) .. txt("%=", "Fill")
      end,
    },
  },
}

-- M.nvdash = { load_on_startup = true }

return M

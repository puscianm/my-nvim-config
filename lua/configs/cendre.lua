-- Cendre options, plus every group base46 would otherwise own, rebuilt from
-- cendre's palette.
--
-- Two problems, one fix. NvChad draws groups only base46 defines (St_* for the
-- statusline, Tb* for the tabufline, NvDash*), and cendre ships no groups for
-- telescope, nvim-cmp or indent-blankline. Both are answered here, through
-- on_highlights, so they follow :CendreBackground, which calls load() directly
-- and never fires the ColorScheme event.
--
-- Roles follow cendre's own map: ember for UI, frost for types and LSP, brass
-- for callables, sap for values, and the semantic family for diagnostics only.
local M = {
  background = "hard", -- "hard" | "medium" | "soft"
  italic_virtual_text = false,
}

local MODES = {
  Normal = "frost",
  Visual = "brass",
  Insert = "sap",
  Command = "ember",
  Replace = "cinder",
  Select = "potassium",
  Terminal = "sap",
  NTerminal = "frost",
  Confirm = "fg_dim",
}

-- cmp item kinds, mapped to the pigment that kind of token already wears in a
-- buffer, so the menu is not a second colour scheme
local KINDS = {}
local function kinds(pigment, names)
  for _, name in ipairs(names) do
    KINDS[name] = pigment
  end
end

kinds("brass", { "Function", "Method" })
kinds("frost", { "Class", "Constructor", "Enum", "Interface", "Struct", "Structure", "Type", "TypeParameter" })
kinds("ember", { "Field", "Property", "Variable", "Identifier", "EnumMember" })
kinds("sap", { "Constant", "Text", "Value", "Snippet", "Color", "Unit" })
kinds("cinder", { "Keyword", "Operator", "Event" })
kinds("fg_dim", { "File", "Folder", "Module", "Reference" })
kinds("potassium", { "Copilot", "Codeium", "TabNine", "SuperMaven" })

function M.on_highlights(hl, c)
  hl.StatusLine = { bg = c.bg2 }
  hl.StatusLineNC = { bg = c.bg_deep }

  -- the second block, which the mode and cwd separators hand off to
  hl.St_EmptySpace = { fg = c.comment, bg = c.bg3 }
  hl.ST_EmptySpace = hl.St_EmptySpace -- NvChad renders this spelling

  hl.St_file = { fg = c.fg, bg = c.bg3 }
  hl.St_file_sep = { fg = c.bg3, bg = c.bg2 }

  hl.St_cwd_icon = { fg = c.bg0, bg = c.ember }
  hl.St_cwd_text = { fg = c.fg, bg = c.bg3 }
  hl.St_cwd_sep = { fg = c.ember, bg = c.bg2 }

  hl.St_pos_icon = { fg = c.bg0, bg = c.brass }
  hl.St_pos_text = { fg = c.brass, bg = c.bg3 }
  hl.St_pos_sep = { fg = c.brass, bg = c.bg3 }

  hl.St_gitIcons = { fg = c.fg_dim, bg = c.bg2, bold = true }
  hl.St_Lsp = { fg = c.frost, bg = c.bg2 }
  hl.St_LspMsg = { fg = c.sap, bg = c.bg2 }

  -- NvChad uses both spellings depending on the statusline module
  hl.St_lspError = { fg = c.error, bg = c.bg2 }
  hl.St_lspWarning = { fg = c.warn, bg = c.bg2 }
  hl.St_lspHints = { fg = c.hint, bg = c.bg2 }
  hl.St_lspInfo = { fg = c.info, bg = c.bg2 }
  hl.St_LspHints = hl.St_lspHints
  hl.St_LspInfo = hl.St_lspInfo

  for mode, pigment in pairs(MODES) do
    hl["St_" .. mode .. "Mode"] = { fg = c.bg0, bg = c[pigment], bold = true }
    hl["St_" .. mode .. "ModeSep"] = { fg = c[pigment], bg = c.bg3 }
  end

  -- tabufline: the bar is bg_deep, the buffer you are in is the editor's own
  -- bg0, so the current buffer reads as a continuation of the window below it
  hl.TbFill = { bg = c.bg_deep }
  hl.Tabline = { bg = c.bg_deep }
  hl.TbBufOn = { fg = c.fg, bg = c.bg0 }
  hl.TbBufOff = { fg = c.comment, bg = c.bg_deep }
  hl.TbBufOnModified = { fg = c.sap, bg = c.bg0 }
  hl.TbBufOffModified = { fg = c.cinder, bg = c.bg_deep }
  hl.TbBufOnClose = { fg = c.cinder, bg = c.bg0 }
  hl.TbBufOffClose = { fg = c.comment, bg = c.bg_deep }
  hl.TbTabOn = { fg = c.ember, bg = c.bg0 }
  hl.TbTabOff = { fg = c.fg_dim, bg = c.bg_deep }
  hl.TbTabNewBtn = { fg = c.fg, bg = c.bg2 }
  hl.TbTabCloseBtn = { fg = c.bg0, bg = c.frost }
  hl.TBTabTitle = { fg = c.bg0, bg = c.ember }
  hl.TbThemeToggleBtn = { fg = c.fg, bg = c.bg3, bold = true }
  hl.TbCloseAllBufsBtn = { fg = c.bg0, bg = c.cinder, bold = true }

  -- telescope, in NvChad's borderless style: the prompt row lifts one step off
  -- the float, and the borders are the surface they sit on
  hl.TelescopeNormal = { fg = c.fg, bg = c.bg_deep }
  hl.TelescopeBorder = { fg = c.bg_deep, bg = c.bg_deep }
  hl.TelescopeResultsTitle = { fg = c.bg_deep, bg = c.bg_deep }
  hl.TelescopePreviewNormal = { bg = c.bg_deep }
  hl.TelescopePreviewBorder = { fg = c.bg_deep, bg = c.bg_deep }
  hl.TelescopePreviewTitle = { fg = c.bg0, bg = c.sap }
  hl.TelescopePromptNormal = { fg = c.fg, bg = c.bg1 }
  hl.TelescopePromptBorder = { fg = c.bg1, bg = c.bg1 }
  hl.TelescopePromptTitle = { fg = c.bg0, bg = c.ember }
  hl.TelescopePromptPrefix = { fg = c.ember, bg = c.bg1 }
  hl.TelescopePromptCounter = { fg = c.comment, bg = c.bg1 }
  hl.TelescopeSelection = { fg = c.fg, bg = c.bg2 }
  hl.TelescopeSelectionCaret = { fg = c.ember, bg = c.bg2 }
  hl.TelescopeMultiSelection = { fg = c.brass, bg = c.bg2 }
  hl.TelescopeMatching = { fg = c.brass, bold = true }
  hl.TelescopeResultsDiffAdd = { fg = c.ok }
  hl.TelescopeResultsDiffChange = { fg = c.warn }
  hl.TelescopeResultsDiffDelete = { fg = c.error }

  -- nvim-cmp. The popup stays painted for the same reason cendre keeps Pmenu
  -- painted under transparent: a see-through menu over code is not readable.
  hl.CmpPmenu = { bg = c.bg1 }
  hl.CmpBorder = { fg = c.bg3, bg = c.bg1 }
  hl.CmpDoc = { bg = c.bg_deep }
  hl.CmpDocBorder = { fg = c.bg3, bg = c.bg_deep }
  hl.CmpSel = { link = "PmenuSel", bold = true }
  hl.CmpItemAbbr = { fg = c.fg }
  hl.CmpItemAbbrMatch = { fg = c.brass, bold = true }
  hl.CmpItemAbbrMatchFuzzy = { fg = c.brass }
  hl.CmpItemAbbrDeprecated = { fg = c.comment, strikethrough = true }
  hl.CmpItemMenu = { fg = c.comment }

  -- one kind, one pigment, matching what the same token wears in the buffer
  for kind, pigment in pairs(KINDS) do
    hl["CmpItemKind" .. kind] = { fg = c[pigment] }
  end

  -- indent-blankline
  hl.IblChar = { fg = c.bg3 }
  hl.IblScopeChar = { fg = c.bg5 }

  -- NvChad's own windows
  hl.NvChHeading = { fg = c.bg0, bg = c.ember, bold = true }
  hl.NvChSection = { bg = c.bg_deep }
  hl.NvChAsciiHeader = { fg = c.ember, bg = c.bg_deep }
  hl.NvDashAscii = { fg = c.bg0, bg = c.ember }
  hl.NvDashButtons = { fg = c.fg, bg = c.bg1 }
  hl.NvDashFooter = { fg = c.sap }
end

--- Repaint. base46's per-plugin caches (syntax, treesitter, telescope, cmp,
--- nvimtree, git, lsp, mason, whichkey, blankline) are dofile'd when their
--- plugin loads, which is after cendre, so each one paints over the theme in
--- its own namespace. Reloading cendre puts it back, including everything
--- above. Devicons is refreshed by hand because load() sets colors_name
--- directly, so the ColorScheme autocmd the plugin installs never runs.
local function repaint()
  require("cendre").load()
  pcall(function()
    require("nvim-web-devicons").refresh()
  end)
end

--- Reload after any lazy-loaded plugin pulls in its base46 cache. Debounced to
--- one repaint per tick, since plugins load in bursts.
function M.attach()
  local queued = false

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyLoad",
    group = vim.api.nvim_create_augroup("CendreRepaint", { clear = true }),
    callback = function()
      if queued then
        return
      end
      queued = true
      vim.schedule(function()
        queued = false
        repaint()
      end)
    end,
  })
end

return M

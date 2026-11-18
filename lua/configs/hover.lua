-- LSP hover (K) with a border and a size cap, plus a side-window variant (gK),
-- and cleanup of the markdown basedpyright makes from Python docstrings.
--
-- basedpyright converts the three common docstring styles like this:
--
--   numpy    Parameters / ---------- sections; "name : type" lines, each
--            followed by a description indented with &nbsp;s
--   Google   "Args:" / "Returns:" / "Raises:" headers; items indented with
--            4 &nbsp;s ("name (type): desc"), continuations with 8
--   reST     ":param x: desc", ":type x: t", ":return: d", ":rtype: t",
--            ":raises E: desc" fields
--
-- What cleanup does, for all of them:
--   * &nbsp; indents (6 raw characters each, so lines wrapped early and
--     mid-word) become real spaces.
--   * every parameter becomes one line: its wrapped continuation lines,
--     including ones basedpyright left flush left, are joined back onto it,
--     so the window soft-wraps it with the right indent.
--   * parameter names are bold, types are inline code, section headers
--     ("Args:") are bold; numpy entries get a blank line between them.
--   * reST "simple tables" (blocks between ===== rules) go in a text code
--     block: as markdown, the rules would turn rows into giant headings.
--
-- Pressing K again while the popup is open jumps into it (shared focus_id).
local M = {}

local OPTS = { border = "rounded", max_width = 80, max_height = 20, focus_id = "lsp_hover" }

-- Google-style headers whose indented lines are "name: desc" items.
local GOOGLE_ITEM_SECTIONS = {
  Args = true, Arguments = true, Parameters = true, Params = true,
  ["Keyword Args"] = true, ["Keyword Arguments"] = true, Kwargs = true,
  ["Other Parameters"] = true, Attributes = true,
  Returns = true, Return = true, Yields = true, Yield = true,
  Raises = true, Raise = true, Exceptions = true, Warns = true,
}

local function is_rule(line)
  return line:match "^=+%s*$" ~= nil
end

local function unescape(s)
  return (s:gsub("\\([%*_%[%]\\`])", "%1"))
end

local function code(s)
  s = vim.trim(unescape(s))
  if s == "" or s:find("`", 1, true) then
    return s
  end
  return "`" .. s .. "`"
end

-- Number of leading "&nbsp;" and the rest of the line.
local function split_nbsp(line)
  local n = 0
  while line:sub(1, 6) == "&nbsp;" do
    line = line:sub(7)
    n = n + 1
  end
  return n, line
end

-- "name (type): desc" / "name: desc" -> bold name, code type
local function format_google_item(text)
  local name, typ, desc = text:match "^([%w_\\%*%.]+)%s*%((.-)%)%s*:%s*(.*)$"
  if name then
    return "**" .. name .. "** (" .. code(typ) .. "): " .. desc
  end
  name, desc = text:match "^([%w_\\%*%.]+)%s*:%s*(.*)$"
  if name then
    return "**" .. name .. "**: " .. desc
  end
  return text
end

-- ":param x: d", ":type x: t", ":return: d", ":rtype: t", ":raises E: d"
local function format_rest_field(text)
  local kind, arg, desc = text:match "^:(%a+)%s*([^:]*):%s*(.*)$"
  if not kind then
    return text
  end
  arg = vim.trim(arg)
  if kind == "param" or kind == "parameter" or kind == "arg" or kind == "argument" or kind == "key" or kind == "keyword" then
    return "**" .. arg .. "**: " .. desc
  elseif kind == "type" then
    return "**" .. arg .. "** type: " .. code(desc)
  elseif kind == "return" or kind == "returns" then
    return "**Returns**: " .. desc
  elseif kind == "rtype" then
    return "**Return type**: " .. code(desc)
  elseif kind == "raises" or kind == "raise" or kind == "except" or kind == "exception" then
    return "**Raises** " .. code(arg) .. ": " .. desc
  end
  return "**" .. vim.trim(kind .. " " .. arg) .. "**: " .. desc
end

-- numpy "name : type" (or a bare "type" in Returns) -> bold name, code type
local function format_numpy_header(text)
  local body = text:gsub("%s+$", "")
  local name, typ = body:match "^(.-)%s+:%s+(.+)$"
  if name then
    return "**" .. name .. "** : " .. code(typ)
  end
  return "**" .. body .. "**"
end

-- A line that starts a new item even without its indent (basedpyright
-- sometimes drops it, e.g. torch's "reduction (str, optional): ...").
local function is_item_start(line)
  return line:match "^[%w_\\%*%.]+%s*%(.-%)%s*:" ~= nil or line:match "^:%a+[^:]*:" ~= nil
end

-- Indent for n &nbsp;s. Kept under 4 spaces: after a blank line (numpy
-- descriptions with several paragraphs), 4 spaces would make an indented
-- code block in markdown.
local function indent_for(n)
  if n == 0 then
    return 0
  end
  return n >= 8 and 3 or 2
end

local function clean(lines)
  local out = {}
  local style -- "numpy" | "google" | "google_text" | "rest" | nil (plain)
  local item, item_indent -- index in `out` of the item collecting continuations
  local in_fence = false

  local function push(line)
    table.insert(out, line)
  end
  -- Items end with a markdown hard break ("  "), which reflow() reads as
  -- "never join the next line onto this one".
  local function push_item(line, indent)
    push(string.rep(" ", indent) .. line:gsub("%s+$", "") .. "  ")
    item, item_indent = #out, indent
  end
  local function continue_item(text)
    out[item] = out[item]:gsub("%s+$", "") .. " " .. vim.trim(text) .. "  "
  end

  local i = 1
  while i <= #lines do
    local raw = lines[i]
    local n, text = split_nbsp(raw)
    local next_n = split_nbsp(lines[i + 1] or "")

    if raw:match "^```" then
      in_fence = not in_fence
      push(raw)
      item = nil
    elseif in_fence then
      push(raw)
    elseif vim.trim(raw) == "" then
      push ""
      item = nil
    elseif is_rule(raw) and (i == 1 or lines[i - 1] == "") then
      -- reST simple table: copy through its closing rule (one followed by a
      -- blank line or the end), inside a fence.
      push "```text"
      push(raw)
      while i < #lines do
        i = i + 1
        push(unescape(lines[i]))
        if is_rule(lines[i]) and (i == #lines or lines[i + 1] == "") then
          break
        end
      end
      push "```"
      item = nil
    elseif raw:match "^%-%-%-+%s*$" and out[#out] and out[#out] ~= "" and not out[#out]:match "^```" then
      -- numpy section underline (setext heading). Not the "---" basedpyright
      -- puts between the signature's code block and the docs.
      push(raw)
      style, item = "numpy", nil
    elseif n == 0 and raw:match "^%u[%a ]*:%s*$" then
      -- Google section header ("Args:")
      local name = raw:match "^(.-):"
      style = GOOGLE_ITEM_SECTIONS[name] and "google" or "google_text"
      push("**" .. name .. "**  ")
      item = nil
    elseif n == 0 and style == "numpy" and next_n > 0 then
      -- numpy "name : type", with a blank line between entries
      if out[#out] ~= "" and not out[#out]:match "^[-=]+%s*$" then
        push ""
      end
      push(format_numpy_header(raw) .. "  ")
      item = nil
    elseif n == 0 and raw:match "^:%a+[^:]*:" then
      style = "rest"
      push_item(format_rest_field(raw), 0)
    elseif n == 0 and style == "google" and is_item_start(raw) then
      push_item(format_google_item(raw), indent_for(4))
    elseif item and (indent_for(n) > item_indent or (n == 0 and not is_item_start(raw))) then
      -- deeper-indented, or flush left where basedpyright dropped the indent
      continue_item(text)
    elseif n > 0 then
      if style == "google" and not text:match "^>>>" then
        push_item(format_google_item(text), indent_for(n))
      else
        -- numpy description, or any other indented block
        push_item(text, indent_for(n))
      end
    else
      push(raw)
      item = nil
    end
    i = i + 1
  end
  return out
end


M._clean = clean

-- Docstrings are hand-wrapped at ~75 columns, so a wide window still shows a
-- narrow column of text. Join each paragraph's (and each parameter
-- description's) lines into one, and let the window soft-wrap at its real
-- width. Left alone: fenced code, headings and their underlines, rules, list
-- items, quotes, tables, and lines ending in a markdown hard break ("  "),
-- which is how basedpyright ends "name : type" lines.
local function starts_block(line)
  return line:match "^```"
    or line:match "^#"
    or line:match "^%s*[-*+]%s"
    or line:match "^%s*%d+[.)]%s"
    or line:match "^[-=_*]+%s*$"
    or line:match "^%s*>"
    or line:match "^%s*|"
end

local function reflow(lines)
  local out = {}
  local in_fence = false
  for i, line in ipairs(lines) do
    local prev = out[#out]
    local next_line = lines[i + 1] or ""
    local joinable = not in_fence
      and prev
      and prev ~= ""
      and line ~= ""
      and not starts_block(line)
      and (not starts_block(prev) or prev:match "^%s*[-*+]%s" or prev:match "^%s*%d+[.)]%s") -- list items take wrapped continuations
      and not prev:match "  $"
      and not next_line:match "^[-=]+%s*$" -- line is a setext heading title
      and #prev:match "^ *" == #line:match "^ *" -- same indent level
    if joinable then
      out[#out] = prev:gsub("%s+$", "") .. " " .. vim.trim(line)
    else
      table.insert(out, line)
    end
    if line:match "^```" then
      in_fence = not in_fence
    end
  end
  return out
end

M._reflow = reflow

-- Ask every attached server for hover docs at the cursor; calls on_lines with
-- the cleaned markdown, or notifies when there is nothing.
local function fetch(on_lines)
  local buf = vim.api.nvim_get_current_buf()
  vim.lsp.buf_request_all(buf, "textDocument/hover", function(client)
    return vim.lsp.util.make_position_params(0, client.offset_encoding)
  end, function(results)
    local lines = {}
    for _, res in pairs(results) do
      local contents = res.result and res.result.contents
      if contents then
        local md = vim.lsp.util.convert_input_to_markdown_lines(contents)
        if #md > 0 then
          if #lines > 0 then
            table.insert(lines, "---")
          end
          vim.list_extend(lines, md)
        end
      end
    end
    if #lines == 0 then
      vim.notify("No information available", vim.log.levels.INFO)
      return
    end
    on_lines(clean(lines))
  end)
end

function M.hover()
  fetch(function(lines)
    local _, win = vim.lsp.util.open_floating_preview(lines, "markdown", OPTS)
    -- hanging indent: a wrapped line sits 2 columns right of where its item
    -- starts, so it doesn't read as the next item
    vim.wo[win].breakindentopt = "shift:2"
  end)
end

-- The same docs in a regular window on the right, for reading at length:
-- scroll, search, yank, keep it open while coding. Text is reflowed to the
-- window's width (and rewraps when you resize it). One docs window is reused,
-- so gK on another symbol replaces its contents. q closes it.
local doc_buf

function M.hover_split()
  fetch(function(lines)
    if not (doc_buf and vim.api.nvim_buf_is_valid(doc_buf)) then
      doc_buf = vim.api.nvim_create_buf(false, true)
      vim.bo[doc_buf].bufhidden = "hide"
      -- render-markdown skips nofile buffers (popups); this one is a normal
      -- window, so let it render. Must be set before the FileType event.
      vim.b[doc_buf].render_docs = true
      vim.bo[doc_buf].filetype = "markdown"
      vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = doc_buf, desc = "Close docs" })
    end

    vim.bo[doc_buf].modifiable = true
    vim.api.nvim_buf_set_lines(doc_buf, 0, -1, false, reflow(lines))
    vim.bo[doc_buf].modifiable = false

    local win = vim.fn.bufwinid(doc_buf)
    if win == -1 then
      vim.cmd("botright vsplit")
      win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, doc_buf)
      vim.api.nvim_win_set_width(win, math.floor(vim.o.columns / 2))
    else
      vim.api.nvim_set_current_win(win)
    end

    local wo = vim.wo[win]
    wo.wrap, wo.linebreak, wo.breakindent = true, true, true
    wo.breakindentopt = "shift:2" -- hanging indent, as in the popup
    wo.conceallevel, wo.concealcursor = 2, "n"
    wo.number, wo.relativenumber, wo.signcolumn = false, false, "no"
    vim.api.nvim_win_set_cursor(win, { 1, 0 })
  end)
end

return M

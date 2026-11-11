-- Kedro-aware gd / grr.
--
-- On a dataset string in a pipeline (or a top-level key in catalog*.yml):
--   grr -> nodes that take it as `inputs` (consumers)
--   gd  -> node that has it in `outputs` (producer); otherwise its catalog entry;
--          for "params:a.b" -> the a.b key in parameters*.yml
-- Anywhere else both fall back to the LSP.
--
-- Lookup is ripgrep over <root>/src (no cache, so never stale) plus treesitter to
-- classify each hit by its position inside Node(...). Reads files from disk, so
-- unsaved edits are not seen. Names built dynamically (f-strings, variables) are missed.

local M = {}

local ts = vim.treesitter

local function text(node, src)
  return ts.get_node_text(node, src)
end

local function unquote(s)
  return (s:gsub("^[\"']", ""):gsub("[\"']$", ""))
end

local function rg_escape(s)
  return (s:gsub("[%^%$%.%*%+%?%(%)%[%]%{%}%|\\%-]", "\\%0"))
end

---@return string|nil
local function kedro_root(buf)
  local root = vim.fs.root(buf or 0, "conf")
  if root and vim.uv.fs_stat(root .. "/conf/base/catalog.yml") then
    return root
  end
end

---@return {filename: string, lnum: integer, col: integer, text: string}[]
local function rg(root, pattern, glob, dir)
  local res = vim.system({ "rg", "--vimgrep", "--glob", glob, "-e", pattern, dir }, { cwd = root, text = true }):wait()
  local hits = {}
  for line in (res.stdout or ""):gmatch "[^\n]+" do
    local file, lnum, col, rest = line:match "^(.-):(%d+):(%d+):(.*)$"
    if file then
      hits[#hits + 1] = { filename = root .. "/" .. file, lnum = tonumber(lnum), col = tonumber(col), text = vim.trim(rest) }
    end
  end
  return hits
end

-- Treesitter classification ---------------------------------------------------

local function is_node_call(call, src)
  local fn = call:field("function")[1]
  return fn ~= nil and text(fn, src):match "[Nn]ode$" ~= nil
end

local function node_name(call, src)
  local args = call:field("arguments")[1]
  if not args then
    return nil
  end
  for child in args:iter_children() do
    if child:type() == "keyword_argument" and text(child:field("name")[1], src) == "name" then
      return unquote(text(child:field("value")[1], src))
    end
  end
end

-- Walks up from a string literal; returns "inputs"/"outputs" and the node name,
-- or nil if the string is not a dataset reference of a Node(...) call.
local function classify(str, src)
  local child, parent = str, str:parent()
  while parent do
    local t = parent:type()
    if t == "pair" then
      -- dict key = function argument name, not a dataset
      local key = parent:field("key")[1]
      if key and key:equal(child) then
        return nil
      end
    elseif t == "keyword_argument" then
      local role = text(parent:field("name")[1], src)
      local call = parent:parent() and parent:parent():parent()
      if (role == "inputs" or role == "outputs") and call and call:type() == "call" and is_node_call(call, src) then
        return role, node_name(call, src)
      end
      return nil
    elseif t == "argument_list" then
      local call = parent:parent()
      if not (call and call:type() == "call" and is_node_call(call, src)) then
        return nil
      end
      local idx = 0
      for arg in parent:iter_children() do
        if arg:named() and arg:type() ~= "keyword_argument" and arg:type() ~= "comment" then
          if arg:equal(child) then
            break
          end
          idx = idx + 1
        end
      end
      local role = ({ [1] = "inputs", [2] = "outputs" })[idx]
      return role, role and node_name(call, src)
    elseif not (t == "dictionary" or t == "list" or t == "tuple" or t == "parenthesized_expression") then
      return nil
    end
    child, parent = parent, parent:parent()
  end
end

-- All Node(...) references to `name` under src/, tagged with their role.
local function pipeline_refs(root, name)
  local dir = vim.uv.fs_stat(root .. "/src") and "src" or "."
  local hits = rg(root, "[\"']" .. rg_escape(name) .. "[\"']", "*.py", dir)
  local trees, refs = {}, {}
  for _, hit in ipairs(hits) do
    local t = trees[hit.filename]
    if not t then
      local src = table.concat(vim.fn.readfile(hit.filename), "\n")
      local ok, parser = pcall(ts.get_string_parser, src, "python")
      t = { src = src, root = ok and parser:parse()[1]:root() or nil }
      trees[hit.filename] = t
    end
    if t.root then
      local r, c = hit.lnum - 1, hit.col - 1
      local n = t.root:named_descendant_for_range(r, c, r, c)
      while n and n:type() ~= "string" do
        n = n:parent()
      end
      if n then
        local role, node = classify(n, t.src)
        if role then
          hit.role = role
          hit.text = ("[%s] %s"):format(role, node or hit.text)
          refs[#refs + 1] = hit
        end
      end
    end
  end
  return refs
end

-- YAML lookups ----------------------------------------------------------------

-- Explicit entries first, then dataset factory patterns ("{name}_raw") that match.
local function catalog_entries(root, name)
  local key = "^[\"']?" .. rg_escape(name) .. "[\"']?:"
  local hits = rg(root, key, "catalog*.yml", "conf")
  if #hits > 0 then
    return hits
  end
  for _, h in ipairs(rg(root, "^[\"'][^\"']*\\{[^\"']*[\"']:", "catalog*.yml", "conf")) do
    local pat = h.text:match "^[\"']([^\"']+)[\"']:"
    local lua_pat = "^" .. pat:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"):gsub("{[^}]*}", ".+") .. "$"
    if name:match(lua_pat) then
      h.text = "[factory] " .. pat
      hits[#hits + 1] = h
    end
  end
  return hits
end

-- Checks that the key on line `lnum` sits under segs[1] > segs[2] > ... (by indentation).
local function yaml_path_matches(file, lnum, segs)
  local lines = vim.fn.readfile(file, "", lnum)
  local indent = #lines[lnum]:match "^%s*"
  for i = #segs - 1, 1, -1 do
    local found = false
    for l = lnum - 1, 1, -1 do
      local ind, key = lines[l]:match "^(%s*)([^%s#:][^:]*):"
      if key and #ind < indent then
        if unquote(key) ~= segs[i] then
          return false
        end
        indent, lnum, found = #ind, l, true
        break
      end
    end
    if not found then
      return false
    end
  end
  return indent == 0
end

local function param_entries(root, path)
  local segs = vim.split(path, ".", { plain = true })
  local hits = rg(root, "^\\s*[\"']?" .. rg_escape(segs[#segs]) .. "[\"']?:", "parameters*.yml", "conf")
  return vim.tbl_filter(function(h)
    return yaml_path_matches(h.filename, h.lnum, segs)
  end, hits)
end

-- Cursor & results ------------------------------------------------------------

local function dataset_under_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  if ft == "yaml" then
    if not vim.fs.basename(vim.api.nvim_buf_get_name(buf)):match "^catalog" then
      return nil
    end
    local key = vim.api.nvim_get_current_line():match "^[\"']?([%w_%.%-@]+)[\"']?:"
    if key and not key:match "^_" then
      return key
    end
    return nil
  end

  if ft ~= "python" then
    return nil
  end
  if not ts.language.add "python" then
    vim.notify_once("Kedro nav: python treesitter parser missing (:TSInstall python); using LSP", vim.log.levels.WARN)
    return nil
  end
  -- Parse explicitly: get_node() only reads an existing tree, which may not be there yet.
  local ok, parser = pcall(ts.get_parser, buf, "python")
  if not (ok and parser) then
    return nil
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local n = parser:parse()[1]:root():named_descendant_for_range(row - 1, col, row - 1, col)
  while n and n:type() ~= "string" do
    n = n:parent()
  end
  if not n then
    return nil
  end
  local content
  for c in n:iter_children() do
    if c:type() == "interpolation" then
      return nil
    elseif c:type() == "string_content" then
      content = text(c, buf)
    end
  end
  if content and content:match "^[%w_%.:%-@]+$" then
    return content
  end
end

-- Captures the current position; calling the result pushes it onto the tag stack
-- (like LSP gd does), so <C-t> returns here. <C-o> works via the jumplist too.
local function tag_pusher(tagname)
  local win = vim.api.nvim_get_current_win()
  local from = vim.fn.getpos "."
  from[1] = vim.api.nvim_get_current_buf()
  return function()
    vim.fn.settagstack(win, { items = { { tagname = tagname, from = from } } }, "t")
  end
end

local function show(items, title, tagname)
  local push_tag = tag_pusher(tagname)
  if #items == 1 then
    local it = items[1]
    push_tag()
    vim.cmd "normal! m'"
    vim.cmd.edit(vim.fn.fnameescape(it.filename))
    vim.api.nvim_win_set_cursor(0, { it.lnum, it.col - 1 })
    return
  end
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local actions = require "telescope.actions"
  local conf = require("telescope.config").values
  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table { results = items, entry_maker = make_entry.gen_from_quickfix {} },
      previewer = conf.qflist_previewer {},
      sorter = conf.generic_sorter {},
      attach_mappings = function()
        -- push only when an entry is actually chosen, not on <Esc>
        actions.select_default:enhance { pre = push_tag }
        return true
      end,
    })
    :find()
end

-- Public ----------------------------------------------------------------------

---@return boolean handled
function M.definition()
  local root, name = kedro_root(), dataset_under_cursor()
  if not (root and name) then
    return false
  end

  local param = name:match "^params:(.+)$"
  if param then
    local hits = param_entries(root, param)
    if #hits > 0 then
      show(hits, "Parameter " .. param, name)
    else
      vim.notify("Kedro: no parameter " .. param .. " in conf/**/parameters*.yml", vim.log.levels.WARN)
    end
    return true
  end

  local producers = vim.tbl_filter(function(r)
    return r.role == "outputs"
  end, pipeline_refs(root, name))
  if #producers > 0 then
    show(producers, "Producers of " .. name, name)
    return true
  end

  local entries = catalog_entries(root, name)
  if #entries > 0 then
    show(entries, "Catalog entries for " .. name, name)
    return true
  end

  vim.notify("Kedro: nothing produces " .. name .. " and it has no catalog entry", vim.log.levels.WARN)
  return true
end

---@return boolean handled
function M.references()
  local root, name = kedro_root(), dataset_under_cursor()
  if not (root and name) then
    return false
  end
  local consumers = vim.tbl_filter(function(r)
    return r.role == "inputs"
  end, pipeline_refs(root, name))
  if #consumers > 0 then
    show(consumers, "Consumers of " .. name, name)
  else
    vim.notify("Kedro: no node takes " .. name .. " as input", vim.log.levels.WARN)
  end
  return true
end

-- Buffer-local maps so they win over NvChad's LSP on_attach `gd` (also buffer-local).
-- Scheduled so they are set after any LspAttach handler that ran first.
local function attach(buf)
  vim.schedule(function()
    if not (vim.api.nvim_buf_is_valid(buf) and kedro_root(buf)) then
      return
    end
    local function map(lhs, kedro_fn, lsp_fn, desc)
      vim.keymap.set("n", lhs, function()
        if not kedro_fn() then
          lsp_fn()
        end
      end, { buffer = buf, desc = desc })
    end
    map("gd", M.definition, vim.lsp.buf.definition, "Kedro producer / catalog, else LSP definition")
    map("grr", M.references, vim.lsp.buf.references, "Kedro consumers, else LSP references")
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("KedroNav", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "python", "yaml" },
    callback = function(ev)
      attach(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      attach(ev.buf)
    end,
  })
  -- mappings.lua is loaded deferred by NvChad, so the startup buffer's FileType may already have fired
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.tbl_contains({ "python", "yaml" }, vim.bo[buf].filetype) then
      attach(buf)
    end
  end
end

return M

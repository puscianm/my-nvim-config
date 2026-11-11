require("nvchad.configs.lspconfig").defaults()

-- Servers expected on every machine.
local servers = { "html", "cssls", "lua_ls" }

-- Everything else is enabled only when its binary is actually on PATH, so this
-- file works unchanged on both machines instead of erroring on the one where a
-- given toolchain isn't installed.
local optional = {
  ruff = "ruff",
  hls = "haskell-language-server-wrapper",
}

for name, binary in pairs(optional) do
  if vim.fn.executable(binary) == 1 then
    table.insert(servers, name)
  end
end

-- basedpyright is the stricter fork; fall back to pyright where that's the one
-- installed. Either way, point it at the project-local venv.
--
-- The venv is resolved by walking up rather than assumed to sit next to the
-- pyproject.toml that root_dir landed on. In a uv workspace the members
-- (packages/*, projects/*) each have their own pyproject.toml, so root_dir is
-- the member dir while the only venv lives at the monorepo root -- a relative
-- ".venv/bin/python" resolves to a path that doesn't exist and every import
-- silently goes unresolved.
local function venv_python(start)
  local hit = vim.fs.find(".venv", { path = start, upward = true, type = "directory" })[1]
  return hit and (hit .. "/bin/python") or nil
end

local python_settings = {
  -- `settings` is seeded here rather than only in the hook below: the client
  -- binds client.settings to this exact table when it is created, which happens
  -- before before_init runs. Assigning a fresh table in the hook would leave the
  -- client holding the original, so the hook mutates this one in place.
  settings = { python = { pythonPath = ".venv/bin/python" } },
  before_init = function(_, config)
    local py = venv_python(config.root_dir or vim.fn.getcwd())
    if py then
      config.settings.python.pythonPath = py
    end
  end,
}

if vim.fn.executable "basedpyright-langserver" == 1 then
  table.insert(servers, "basedpyright")
  vim.lsp.config("basedpyright", python_settings)
elseif vim.fn.executable "pyright-langserver" == 1 then
  table.insert(servers, "pyright")
  vim.lsp.config("pyright", python_settings)
end

vim.lsp.enable(servers)

-- NvChad's default virtual_text is single-line and clips long messages (e.g.
-- basedpyright's multi-line union dumps). virtual_lines on the current line
-- shows the full wrapped message below it without cluttering other lines;
-- float.max_width keeps manually-opened diagnostic floats from clipping too.
vim.diagnostic.config {
  virtual_text = false,
  virtual_lines = { current_line = true },
  float = { max_width = 100 },
}

-- read :h vim.lsp.config for changing options of lsp servers

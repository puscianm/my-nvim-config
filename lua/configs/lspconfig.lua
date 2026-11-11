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
local python_settings = { settings = { python = { pythonPath = ".venv/bin/python" } } }

if vim.fn.executable "basedpyright-langserver" == 1 then
  table.insert(servers, "basedpyright")
  vim.lsp.config("basedpyright", python_settings)
elseif vim.fn.executable "pyright-langserver" == 1 then
  table.insert(servers, "pyright")
  vim.lsp.config("pyright", python_settings)
end

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers

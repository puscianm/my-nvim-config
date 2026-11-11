-- Use the project's pinned ruff (.venv/bin/ruff, found upward from the file)
-- so nvim formats exactly like `uv run ruff`; fall back to ruff on PATH.
-- conform.util is required lazily: this file is read before conform loads.
local function project_ruff(self, ctx)
  return require("conform.util").find_executable({ ".venv/bin/ruff" }, "ruff")(self, ctx)
end

local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_organize_imports", "ruff_format" },
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  formatters = {
    ruff_format = { command = project_ruff },
    ruff_organize_imports = { command = project_ruff },
  },

  -- Format on :w for Python only. ruff reads pyproject.toml, so files a
  -- project excludes (e.g. old modules in psychopomps) are left untouched.
  format_on_save = function(bufnr)
    if vim.bo[bufnr].filetype ~= "python" then
      return nil
    end
    return { timeout_ms = 2000, lsp_format = "never" }
  end,
}

return options

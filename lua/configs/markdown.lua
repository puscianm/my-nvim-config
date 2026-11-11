-- :MarkdownSave -- render the current markdown buffer to standalone HTML.
--
-- Works on any markdown file anywhere, unlike the per-directory Makefile in
-- projects/be_nl/docs. Buffer contents are piped to pandoc on stdin rather than
-- read from disk, so an unsaved buffer renders fine and the file is never
-- written behind your back. The flip side: relative links/images resolve against
-- the cwd, not the file, since pandoc never learns where the source lives.
--
--   :MarkdownSave            -> <same dir>/<same name>.html
--   :MarkdownSave out.html   -> explicit output path
--   :MarkdownSave!           -> render, then open in the default browser
--
-- header.html injects mermaid.js so ```mermaid fences render as diagrams.

local HEADER = vim.fn.stdpath "config" .. "/pandoc/header.html"

local function markdown_save(opts)
  if vim.fn.executable "pandoc" ~= 1 then
    vim.notify("MarkdownSave: pandoc is not on PATH", vim.log.levels.ERROR)
    return
  end

  local src = vim.api.nvim_buf_get_name(0)
  local out
  if opts.args ~= "" then
    out = vim.fn.fnamemodify(opts.args, ":p")
  elseif src ~= "" then
    out = vim.fn.fnamemodify(src, ":r") .. ".html"
  else
    vim.notify("MarkdownSave: unnamed buffer, pass an output path", vim.log.levels.ERROR)
    return
  end

  local cmd = { "pandoc", "--standalone", "--toc", "--toc-depth=2", "-f", "gfm", "-t", "html5" }
  if vim.fn.filereadable(HEADER) == 1 then
    table.insert(cmd, "--include-in-header=" .. HEADER)
  end
  vim.list_extend(cmd, { "-o", out })

  local body = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

  vim.system(cmd, { stdin = body, text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify("MarkdownSave failed:\n" .. (res.stderr or "unknown error"), vim.log.levels.ERROR)
        return
      end
      vim.notify("MarkdownSave -> " .. vim.fn.fnamemodify(out, ":~:."))
      if opts.bang then
        vim.ui.open(out)
      end
    end)
  end)
end

vim.api.nvim_create_user_command("MarkdownSave", markdown_save, {
  nargs = "?",
  bang = true,
  complete = "file",
  desc = "Render this markdown buffer to standalone HTML (pandoc)",
})

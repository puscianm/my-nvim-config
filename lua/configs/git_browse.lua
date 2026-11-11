-- Browse other git refs read-only, without leaving the current branch.
-- Everything opens as a fugitive `<rev>:<path>` buffer, which is nomodifiable.

local M = {}

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- Pass argv as a list: systemlist skips the shell, so `%(refname:short)` and
-- friends never get mangled by zsh globbing/quoting.
local function git(argv)
  local cmd = { "git" }
  vim.list_extend(cmd, argv)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify(table.concat(cmd, " ") .. " failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return nil
  end
  return out
end

local function refs()
  return git {
    "for-each-ref",
    "--sort=-committerdate",
    "--format=%(refname:short)",
    "refs/heads",
    "refs/remotes",
    "refs/tags",
  }
end

-- Pick a ref, then hand it to `cb`.
local function pick_ref(prompt, cb)
  local list = refs()
  if not list then
    return
  end
  pickers
    .new({}, {
      prompt_title = prompt,
      finder = finders.new_table { results = list },
      sorter = conf.generic_sorter {},
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(bufnr)
          if entry then
            cb(entry[1])
          end
        end)
        return true
      end,
    })
    :find()
end

-- Ref -> file picker over `git ls-tree`, opens the blob read-only.
function M.files()
  pick_ref("Branch to browse", function(ref)
    local files = git { "ls-tree", "-r", "--name-only", ref }
    if not files then
      return
    end
    pickers
      .new({}, {
        prompt_title = "Files @ " .. ref,
        finder = finders.new_table { results = files },
        sorter = conf.file_sorter {},
        previewer = conf.file_previewer {},
        attach_mappings = function(bufnr)
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(bufnr)
            if entry then
              vim.cmd("Gedit " .. vim.fn.fnameescape(ref .. ":" .. entry[1]))
            end
          end)
          return true
        end,
      })
      :find()
  end)
end

-- Fugitive's own tree browser: directory listing you can walk with <CR>.
function M.tree()
  pick_ref("Browse tree of", function(ref)
    vim.cmd("Gedit " .. vim.fn.fnameescape(ref .. ":"))
  end)
end

-- Current file as it exists on another ref, side by side with the working copy.
function M.diff_current()
  local rel = vim.fn.expand "%:."
  if rel == "" then
    vim.notify("No file in this buffer", vim.log.levels.WARN)
    return
  end
  pick_ref("Diff " .. rel .. " against", function(ref)
    vim.cmd("Gvdiffsplit " .. vim.fn.fnameescape(ref .. ":" .. rel))
  end)
end

return M

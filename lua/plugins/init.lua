return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- load before the first :w so format_on_save is active
    cmd = { "ConformInfo" },
    opts = require "configs.conform",
  },

  -- Mason tools live in ~/.local/share/nvim, outside this repo, so a synced
  -- config alone doesn't bring them along. Install whatever is missing from
  -- this list on startup so every machine ends up with the same toolset.
  {
    "mason-org/mason.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("mason").setup(opts)
      local ensure = {
        "basedpyright",
        "ruff",
        "lua-language-server",
        "stylua",
        "html-lsp",
        "css-lsp",
      }
      local registry = require "mason-registry"
      registry.refresh(function()
        for _, name in ipairs(ensure) do
          local ok, pkg = pcall(registry.get_package, name)
          if ok and not pkg:is_installed() then
            vim.notify("Mason: installing " .. name)
            pkg:install()
          end
        end
      end)
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Theme. Loaded eagerly and at high priority so it wins over base46; the
  -- statusline/tabufline groups NvChad expects are rebuilt in configs/cendre.lua.
  {
    "Aejkatappaja/cendre",
    lazy = false,
    priority = 1000,
    config = function()
      local cendre = require "configs.cendre"
      require("cendre").setup(cendre)
      vim.cmd.colorscheme "cendre"
      cendre.attach()
    end,
  },

  -- Telescope: fzf sorter, ripgrep-args grep (<leader>fw), file browser (<leader>fb)
  --
  -- Configured on telescope.nvim itself, which loads whenever a picker opens.
  -- (This used to live in telescope-fzf-native's config, but nothing ever
  -- loaded that plugin, so none of it ran.) opts extends NvChad's own
  -- telescope opts rather than replacing them.
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-lua/plenary.nvim",
    },
    opts = function(_, opts)
      local lga_actions = require "telescope-live-grep-args.actions"

      return vim.tbl_deep_extend("force", opts or {}, {
        defaults = {
          -- --trim drops each matched line's leading indentation; without it
          -- a deeply indented match sits off the right edge of the results.
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename",
            "--line-number", "--column", "--smart-case", "--trim",
          },
          -- "file.py:12  dir/sub" instead of "dir/sub/file.py:12": the part
          -- you scan for comes first, the directory is dimmed after it.
          path_display = { "filename_first" },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                -- <C-k> quotes the prompt, <C-i> appends a --iglob flag,
                -- <C-f> searches the prompt literally (rg -F: "." is a dot)
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt { postfix = " --iglob " },
                ["<C-f>"] = lga_actions.quote_prompt { postfix = " -F " },
                -- <C-Space> freezes the grep results and fuzzy-filters them,
                -- e.g. by path ("src", "!test"), as plain live_grep does
                ["<C-Space>"] = require("telescope.actions").to_fuzzy_refine,
              },
            },
          },
        },
      })
    end,
    config = function(_, opts)
      local telescope = require "telescope"
      telescope.setup(opts)
      telescope.load_extension "fzf"
      telescope.load_extension "live_grep_args"
      telescope.load_extension "file_browser"
    end,
  },

  {
    "sudormrfbin/cheatsheet.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
      "nvim-lua/popup.nvim",
      "nvim-lua/plenary.nvim",
    },
    cmd = "Cheatsheet",
    opts = {
      bundled_cheatsheets = {
        disabled = { "nerd-fonts", "markdown", "netrw", "unicode" },
      },
    },
  },

  -- Git ------------------------------------------------------------------
  {
    "tpope/vim-fugitive",
    cmd = { "G", "Git", "Gedit", "Gsplit", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GRename", "GDelete", "GBrowse" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status (fugitive)" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
      { "<leader>gd", "<cmd>Gvdiffsplit<cr>", desc = "Git diff split" },
    },
  },

  {
    "rbong/vim-flog",
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = { "tpope/vim-fugitive" },
    keys = {
      { "<leader>gl", "<cmd>Flog<cr>", desc = "Git log graph (Flog)" },
      { "<leader>gL", "<cmd>Flog -path=%<cr>", desc = "Git log for current file" },
    },
  },

  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    opts = {
      file_panel = {
        listing_style = "tree",
        win_config = { width = 40 },
      },
    },
    keys = {
      -- Diffview buffers for any non-working-tree rev are read-only.
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview working tree" },
      { "<leader>gV", ":DiffviewOpen ", desc = "Diffview vs ref (type one)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview branch history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
    },
  },

  -- Editing --------------------------------------------------------------
  { "echasnovski/mini.align", opts = {}, event = "VeryLazy" },
  { "echasnovski/mini.surround", opts = {}, event = "VeryLazy" },

  {
    "otavioschwanck/arrow.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { "\\", "<leader>m" },
    opts = {
      show_icons = true,
      -- "\\" keeps `;` free for repeat-find
      leader_key = "\\",
      -- per-buffer line bookmarks; not "m", so Vim marks stay intact
      buffer_leader_key = "<leader>m",
    },
  },

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = "ToggleTerm", -- keymaps live in mappings.lua (<leader>ft, <leader>f<n>t)
    opts = {
      direction = "float",
      float_opts = {
        border = "curved",
      },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require "cmp"
      -- Accept completion with Tab instead of Enter
      opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm { behavior = cmp.ConfirmBehavior.Insert, select = true }
        elseif require("luasnip").expand_or_jumpable() then
          require("luasnip").expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" })
      -- Make Enter behave like a normal newline
      opts.mapping["<CR>"] = cmp.mapping(function(fallback)
        fallback()
      end, { "i", "s" })
      return opts
    end,
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },

  -- Data -----------------------------------------------------------------
  -- Column-aligned CSV/TSV view (virtual text only, file is untouched).
  -- Auto-enabled on open; toggle with :CsvViewToggle.
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    opts = {
      view = { display_mode = "border" },
    },
    config = function(_, opts)
      require("csvview").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv" },
        callback = function(args)
          require("csvview").enable(args.buf)
        end,
      })
    end,
  },

  -- Markdown -------------------------------------------------------------
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    -- Fetches a self-contained binary into app/bin instead of npm-installing the
    -- Node server's dependencies, so no node toolchain is needed and the `cond`
    -- guard that used to skip this plugin on npm-less machines can go.
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {
      heading = { sign = false },
      code = { sign = false, width = "block", right_pad = 2 },
      -- LSP hover/signature popups are markdown buffers too (buftype=nofile).
      -- Don't attach to them at all: its full-width rules and code banners
      -- overflow the popup, and merely disabling it (overrides.buftype) still
      -- stops nvim's own markdown conceal, so the ``` fences show.
      -- The gK docs window (configs/hover.lua) opts back in.
      ignore = function(buf)
        return vim.bo[buf].buftype == "nofile" and not vim.b[buf].render_docs
      end,
      -- ...and since popups are ignored, this only reaches the gK window:
      -- it's read-only, so never show raw markdown on the cursor line.
      overrides = {
        buftype = {
          nofile = { anti_conceal = { enabled = false } },
        },
      },
      -- By default it switches off the markdown query's conceal_lines rule for
      -- every buffer the first time it attaches anywhere, so after a gK window
      -- the (ignored) K popups would show their ``` fences again. Keep it on.
      patterns = { markdown = { disable = false } },
    },
  },

  -- nvim-treesitter's `main` branch (a rewrite, needs Nvim 0.12+) ignores
  -- `ensure_installed` and never starts highlighting by itself: parsers are
  -- installed with install() and highlighting is turned on per buffer with
  -- vim.treesitter.start(). Parsers live in ~/.local/share/nvim/site, outside
  -- this repo, so they are installed here on every machine that lacks them.
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      if vim.fn.has "nvim-0.12" ~= 1 then
        vim.notify_once("nvim-treesitter (main) needs Nvim 0.12+; using regex highlighting", vim.log.levels.WARN)
        return
      end

      local ts = require "nvim-treesitter"
      local parsers = {
        "vim", "lua", "luadoc", "vimdoc", "printf",
        "python", "html", "css", "json", "yaml", "toml", "bash",
        "markdown", "markdown_inline",
      }
      local missing = vim.tbl_filter(function(lang)
        return not vim.tbl_contains(ts.get_installed(), lang)
      end, parsers)
      if #missing > 0 then
        ts.install(missing)
      end

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          -- no-op for filetypes without an installed parser
          if pcall(vim.treesitter.start, args.buf) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },
}

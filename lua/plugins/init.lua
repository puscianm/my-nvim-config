return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- format on save, see configs/conform.lua
    opts = require "configs.conform",
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
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local lga_actions = require "telescope-live-grep-args.actions"

      require("telescope").setup {
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
                -- <C-k> quotes the prompt, <C-i> appends a --iglob flag
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt { postfix = " --iglob " },
              },
            },
          },
        },
      }

      require("telescope").load_extension "fzf"
      require("telescope").load_extension "live_grep_args"
      require("telescope").load_extension "file_browser"
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
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc",
        "python", "html", "css",
        "markdown", "markdown_inline",
      },
    },
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },
}

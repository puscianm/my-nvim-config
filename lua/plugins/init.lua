return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
    config = function()
      local lga_actions = require "telescope-live-grep-args.actions"

      require("telescope").setup({
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
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
              },
            },
          },
        },
      })
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("live_grep_args")
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
{
  "tpope/vim-fugitive",
  cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gedit", "Gread", "Gwrite", "Gclog", "GBrowse" },
},
{
  "rbong/vim-flog",
  cmd = { "Flog", "Flogsplit", "Floggit" },
  dependencies = { "tpope/vim-fugitive" },
},
{
  "NeogitOrg/neogit",
  dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
  cmd = "Neogit",
  config = true,
},
  {'echasnovski/mini.align', opts = {}, event = "VeryLazy" },
  {'echasnovski/mini.surround', opts = {}, event = "VeryLazy" },
{
  "akinsho/toggleterm.nvim",
  version = "*",
  cmd = "ToggleTerm",
  opts = {
    direction = "float",
    float_opts = {
      border = "curved",
    },
  },
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

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}

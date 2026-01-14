-- === Bootstrap lazy.nvim ===
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- === General Settings ===
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.scrolloff = 8
vim.opt.splitbelow, vim.opt.splitright = true, true -- New windows open bottom/right
vim.opt.ignorecase, vim.opt.smartcase = true, true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true

-- === Indentation Settings ===
-- Default: 4 spaces (Standard for Python, Lua, Rust)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Override: 2 spaces for Web (TS, JS, HTML, CSS, JSON)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "typescriptreact", "javascriptreact", "html", "css", "json", "yaml" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- === Keymaps ===
vim.keymap.set("n", "<leader>/", ":noh<CR>", { silent = true }) -- Clear search highlights
vim.keymap.set("n", "<leader>o", "<cmd>AerialToggle!<CR>") -- Outline
vim.api.nvim_create_user_command("E", "Explore", {})

-- Python Debugger Abbreviation (Type 'ipdb' + Space/Enter)
vim.cmd("iabbrev ipdb import ipdb; ipdb.set_trace()")

-- Standard Window Navigation (Ctrl + h/j/k/l)
vim.keymap.set("n", "<C-j>", "<C-w>h", { desc = "Window Left" })
vim.keymap.set("n", "<C-l>", "<C-w>j", { desc = "Window Down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window Up" })
vim.keymap.set("n", "<C-m>", "<C-w>l", { desc = "Window Right" })

-- === Plugins ===
require("lazy").setup({
  -- UI / Theme
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "catppuccin/nvim", name = "catppuccin", priority = 1000,
    opts = { flavour = "mocha", integrations = { cmp = true, gitsigns = true, treesitter = true } },
    init = function() vim.cmd.colorscheme "catppuccin" end
  },

  -- Search (Telescope)
  {
    "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>sf", "<cmd>Telescope find_files<cr>" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>" },
      { "<leader>sw", "<cmd>Telescope grep_string<cr>" },
      { "<leader>sb", "<cmd>Telescope buffers<cr>" },
    },
    opts = {
      defaults = {
        file_ignore_patterns = { ".git/", "node_modules", "__pycache__" },
        sorting_strategy = "ascending", -- List starts at top
        layout_config = {
          horizontal = { prompt_position = "top" }, -- Search bar at top
        },
        mappings = {
          i = { -- Allow using Ctrl+j/k to move in search results
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
          }
        }
      }
    }
  },

  -- Git
  { "lewis6991/gitsigns.nvim", opts = {} },
  { "tpope/vim-fugitive", cmd = "Git", keys = { { "<leader>gs", "<cmd>Git<cr>" } } },
  {
    "sindrets/diffview.nvim",
    opts = {},
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>dv", "<cmd>DiffviewOpen<cr>", desc = "Diff View" },
      { "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    },
  },

  -- Highlighting
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", main = "nvim-treesitter.configs",
    opts = { 
        ensure_installed = { "python", "lua", "bash", "markdown", "typescript", "javascript", "tsx" }, 
        highlight = { enable = true } 
    }
  },

  -- Tools
  { 
    "folke/trouble.nvim", 
    cmd = "Trouble", 
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    }
  },
  { "stevearc/aerial.nvim", opts = {} },
  { "github/copilot.vim" },

  -- LSP & Completion
  {
    "neovim/nvim-lspconfig",
    dependencies = { 
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/nvim-cmp", 
        "hrsh7th/cmp-nvim-lsp", 
        "L3MON4D3/LuaSnip" 
    },
    config = function()
      require("mason").setup()
      
      -- Define the servers you want
      -- "ts_ls" is the standard TypeScript server (formerly 'tsserver')
      local servers = { "jedi_language_server", "ts_ls" }

      -- Ensure they are installed via Mason
      require("mason-lspconfig").setup({
        ensure_installed = servers,
      })

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Global diagnostic config (makes errors look nicer)
      vim.diagnostic.config({
        virtual_text = false, -- Turn off inline text if it's too cluttery
        float = {
            border = "rounded",
            source = "always",
        },
        signs = true,
      })

      local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr }
        vim.keymap.set("n", "<leader>g", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "<leader>r", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>d", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      end
      
      -- Setup servers
      for _, server in ipairs(servers) do
        local opts = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        -- Specific fix for TypeScript "False Positives"
        if server == "ts_ls" then
            opts.root_dir = lspconfig.util.root_pattern("tsconfig.json", "package.json", ".git")
            opts.single_file_support = false -- Prevent it from running in single-file mode (which causes errors)
        end

        lspconfig[server].setup(opts)
      end

      -- Completion (CMP)
      local cmp = require("cmp")
      cmp.setup({
        snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({ ["<CR>"] = cmp.mapping.confirm({ select = true }) }),
        sources = { { name = "nvim_lsp" }, { name = "buffer" } },
      })
    end
  },
})

-- Auto-close Quickfix with 'q'
vim.api.nvim_create_autocmd("FileType", { pattern = "qf", command = "nnoremap <buffer> q <cmd>cclose<CR>" })

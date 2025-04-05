-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup plugins
require("lazy").setup({
  spec = {
    -- === Theme ===
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("catppuccin-mocha")
      end,
    },

    -- === Copilot ===
    {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      build = ":Copilot auth",
      config = function()
        require("copilot").setup({
          suggestion = { enabled = true, auto_trigger = true },
          panel = { enabled = false },
        })
      end,
    },

    -- === LSP ===
    { "neovim/nvim-lspconfig" },

    -- === Autocompletion ===
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "hrsh7th/cmp-cmdline" },
    { "L3MON4D3/LuaSnip" },
    { "saadparwaiz1/cmp_luasnip" },
  },
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = true },
  rocks = { enabled = false },
})

-- === Editor Options ===
vim.opt.number = true
vim.opt.encoding = "utf-8"
vim.opt.scrolloff = 999
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.cursorline = true
vim.opt.showmatch = true
vim.opt.grepprg = "rg --smart-case --vimgrep"

-- === Keybindings ===
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("v", "p", "pgvy", opts)
map("v", "P", "Pgvy", opts)
vim.cmd([[vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>]])
map("n", "<leader>/", ":noh<CR>", opts)
map("c", "<C-P>", "<Up>", opts)
map("c", "<C-N>", "<Down>", opts)
map("n", "<C-L>", "<C-W><C-J>", opts)
map("n", "<C-K>", "<C-W><C-K>", opts)
map("n", "<C-M>", "<C-W><C-L>", opts)
map("n", "<C-J>", "<C-W><C-H>", opts)
map("n", "<F7>", ":cp<CR>", opts)
map("n", "<F8>", ":cn<CR>", opts)
vim.cmd([[iabbrev ipdb import ipdb; ipdb.set_trace()]])
vim.api.nvim_create_autocmd("VimResized", {
  callback = function() vim.cmd("wincmd =") end,
})

-- === Copilot Keybinding ===
vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', {
  expr = true, silent = true, noremap = true,
})

-- === LSP: Python support ===
require("lspconfig").pyright.setup({})

-- === nvim-cmp setup ===
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  }),
})

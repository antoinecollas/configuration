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
				require("catppuccin").setup({
					flavour = "auto", -- latte, frappe, macchiato, mocha
					background = { -- :h background
						light = "latte",
						dark = "mocha",
					},
					transparent_background = false, -- disables setting the background color.
					show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
					term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
					dim_inactive = {
						enabled = false, -- dims the background color of inactive window
						shade = "dark",
						percentage = 0.15, -- percentage of the shade to apply to the inactive window
					},
					no_italic = false, -- Force no italic
					no_bold = false, -- Force no bold
					no_underline = false, -- Force no underline
					styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
						comments = { "italic" }, -- Change the style of comments
						conditionals = { "italic" },
						loops = {},
						functions = {},
						keywords = {},
						strings = {},
						variables = {},
						numbers = {},
						booleans = {},
						properties = {},
						types = {},
						operators = {},
						-- miscs = {}, -- Uncomment to turn off hard-coded styles
					},
					color_overrides = {},
					custom_highlights = {},
					default_integrations = true,
					integrations = {
						cmp = true,
						gitsigns = true,
						nvimtree = true,
						treesitter = true,
						notify = false,
						mini = {
							enabled = true,
							indentscope_color = "",
						},
						-- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
					},
				})

				-- setup must be called before loading
				vim.cmd.colorscheme "catppuccin-mocha"
			end,
		},

		-- === Treesitter ===
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			config = function()
				require("nvim-treesitter.configs").setup({
					ensure_installed = { "python", "lua", "bash", "json", "markdown", "yaml" },
					highlight = { enable = true },
					indent = { enable = true },
				})
			end,
		},

		-- === Copilot ===
		{
			"github/copilot.vim",
			lazy = false, -- must be eagerly loaded
		},

		-- === LSP ===
		{ "neovim/nvim-lspconfig" },
		{ "ray-x/lsp_signature.nvim", config = function()
			require("lsp_signature").setup({ hint_prefix = "→ " })
		end },
		
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
vim.opt.signcolumn = "yes"

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
vim.api.nvim_create_user_command('E', 'Explore', {})
vim.cmd([[iabbrev ipdb import ipdb; ipdb.set_trace()]])

vim.api.nvim_create_autocmd("VimResized", {
	callback = function() vim.cmd("wincmd =") end,
})

-- === LSP: Python via Jedi (runtime-aware resolution) ===
require("lspconfig").jedi_language_server.setup({
	on_attach = function(_, bufnr)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
		end
		map("<leader>g", vim.lsp.buf.definition, "Go to Definition")
		map("<leader>r", vim.lsp.buf.references, "Find References")
		map("<leader>d", vim.lsp.buf.hover, "Show Hover")
		map("<leader>i", vim.lsp.buf.implementation, "Go to Implementation")
	end,
})

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

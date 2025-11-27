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

-- Quickfix/Location list: Enter opens the selected entry; q closes the list
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(ev)
    local o = { buffer = ev.buf, silent = true }
    vim.keymap.set("n", "<CR>", "<CR>", o)
    vim.keymap.set("n", "q", "<cmd>cclose<CR>", o)
  end,
})

-- Setup plugins
require("lazy").setup({
	spec = {
		-- === UI Icons (Required for Telescope/Trouble) ===
		{ "nvim-tree/nvim-web-devicons", lazy = true },

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
					transparent_background = false,
					show_end_of_buffer = false,
					term_colors = false,
					dim_inactive = {
						enabled = false,
						shade = "dark",
						percentage = 0.15,
					},
					no_italic = false,
					no_bold = false,
					no_underline = false,
					styles = {
						comments = { "italic" },
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
						telescope = { enabled = true }, -- Enable Telescope highlights
						mini = {
							enabled = true,
							indentscope_color = "",
						},
					},
				})
				vim.cmd.colorscheme "catppuccin-mocha"
			end,
		},

		-- === Telescope (The Modern Grep) ===
		{
			"nvim-telescope/telescope.nvim",
			tag = "0.1.8",
			dependencies = { "nvim-lua/plenary.nvim" },
			config = function()
				local telescope = require("telescope")
				telescope.setup({
					defaults = {
						-- Layout config to make it look nice and modern
						layout_strategy = "horizontal",
						layout_config = {
							prompt_position = "top",
							preview_width = 0.55,
						},
						sorting_strategy = "ascending",
						file_ignore_patterns = { ".git/", "node_modules", "__pycache__" },
					},
					pickers = {
						find_files = { theme = "dropdown", previewer = false },
					},
				})

				-- Telescope Keymaps
				local builtin = require("telescope.builtin")
				vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Search Files" })
				vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Search Grep (Live)" })
				vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "Search Word under cursor" })
				vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "Search Buffers" })
				vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search Help" })
			end,
		},

		-- === Trouble (Better Quickfix UI) ===
		{
			"folke/trouble.nvim",
			opts = {}, -- uses default config
			cmd = "Trouble",
			keys = {
				{
					"<leader>xx",
					"<cmd>Trouble diagnostics toggle<cr>",
					desc = "Diagnostics (Trouble)",
				},
				{
					"<leader>xq",
					"<cmd>Trouble qflist toggle<cr>",
					desc = "Quickfix List (Trouble)",
				},
			},
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
			lazy = false,
		},

		-- === Git ===
		{ "tpope/vim-fugitive" },
		{ "lewis6991/gitsigns.nvim", opts = {} },

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

		-- === aerial.nvim ===
		{
			"stevearc/aerial.nvim",
			opts = {
				backends = { "lsp", "treesitter", "markdown" },
				layout = { default_direction = "prefer_right", max_width = { 40, 0.3 } },
				filter_kind = false,
			},
		},
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

-- Git: fugitive keymaps
vim.keymap.set("n", "<leader>gs", ":Git<CR>",       { desc = "Git status" })
vim.keymap.set("n", "<leader>gc", ":Git commit<CR>",{ desc = "Git commit" })
vim.keymap.set("n", "<leader>gp", ":Git push<CR>",  { desc = "Git push" })
vim.keymap.set("n", "<leader>gl", ":Git pull<CR>",  { desc = "Git pull" })
vim.keymap.set("n", "<leader>gb", ":Git blame<CR>", { desc = "Git blame" })

-- aerial.nvim toggle
vim.keymap.set("n", "<leader>o", "<cmd>AerialToggle!<CR>", { desc = "Outline" })

vim.api.nvim_create_autocmd("VimResized", {
	callback = function() vim.cmd("wincmd =") end,
})

-- === LSP: Python via Jedi (runtime-aware resolution) ===
require("lspconfig").jedi_language_server.setup({
	on_attach = function(client, bufnr)
		-- Disable lsp_signature for Jedi (known issue)
		client.server_capabilities.signatureHelpProvider = false

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

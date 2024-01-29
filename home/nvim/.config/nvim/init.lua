-- Load the .vim version of init, with the rest of the config.
-- local init_vim = vim.fn.stdpath("config") .. "/init_.vim"
-- vim.cmd.source(init_vim)

-- Basic editor settings.
vim.o.hlsearch = false
vim.wo.number = true
vim.opt.undofile = true

vim.o.autoindent = true
vim.o.smartindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4

-- Better colors (assuming light theme, otherwise use dark version of same colors).
vim.cmd([[
	highlight DiffAdd    ctermbg=14
	highlight DiffDelete ctermbg=9
	highlight DiffChange ctermbg=7
	highlight DiffText   ctermbg=15
]])

-- Shortcuts.
vim.g.mapleader = " "
vim.keymap.set("n", "<C-w>;", ":Sexplore<CR>")

-- Load the plugin manager and plugins.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	"nvim-lua/plenary.nvim",
	"guns/xterm-color-table.vim",
	"nvim-telescope/telescope.nvim",
	"jamessan/vim-gnupg",
	"Civitasv/cmake-tools.nvim",
	"neovim/nvim-lspconfig",
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"hrsh7th/nvim-cmp",
	"emileferreira/nvim-strict",
	"numToStr/Comment.nvim",
	"nvim-lualine/lualine.nvim",
}, {
	install = {
		--colorscheme = {
		--	"catppuccin",
		--},
	}
})

local Path = require("plenary.path")

-- Initializing telescope here, as we need it in the LSP server.
local telescope_builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>fd", telescope_builtin.find_files, {})
vim.keymap.set("n", "<leader>fb", telescope_builtin.buffers, {})
vim.keymap.set("n", "<leader>gl", telescope_builtin.live_grep, {})
vim.keymap.set("n", "<leader>gs", telescope_builtin.grep_string, {})
vim.keymap.set("v", "<leader>gs", telescope_builtin.grep_string, {})
-- TODO consider adding git navigation (commits, branches, etc)

-- Enable the LSP servers.
local lspconfig = require("lspconfig")
local on_attach = function(_, bufnr)
  local opts = { silent = true, buffer = bufnr }

  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "<C-w>gd", function() vim.cmd("rightbelow vsplit"); vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "<C-w>Gd", function() vim.cmd("leftabove split"); vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
  vim.keymap.set("n", "<C-w>gD", function() vim.cmd("rightbelow vsplit"); vim.lsp.buf.declaration() end, opts)
  vim.keymap.set("n", "<C-w>GD", function() vim.cmd("leftabove split"); vim.lsp.buf.declaration() end, opts)
  vim.keymap.set("n", "gk", vim.lsp.buf.type_definition, opts)
  vim.keymap.set("n", "<C-w>gk", function() vim.cmd("rightbelow vsplit"); vim.lsp.buf.type_definition() end, opts)
  vim.keymap.set("n", "<C-w>Gk", function() vim.cmd("leftabove split"); vim.lsp.buf.type_definition() end, opts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "<C-w>gi", function() vim.cmd("rightbelow vsplit"); vim.lsp.buf.implementation() end, opts)
  vim.keymap.set("n", "<C-w>Gi", function() vim.cmd("leftabove split"); vim.lsp.buf.implementation() end, opts)

  vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
  vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
  vim.keymap.set("n", "<leader>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, opts)

  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

  vim.keymap.set("n", "<leader>sr", telescope_builtin.lsp_references, opts)
  vim.keymap.set("n", "<leader>si", telescope_builtin.lsp_incoming_calls, opts)
  -- vim.keymap.set("n", "<leader>so", telescope_builtin.lsp_outgoing_calls, opts) -- not implemented
end

--## nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

local lsp_servers = { "clangd" }
for _, lsp in ipairs(lsp_servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- Enable CMake-tools.
require("cmake-tools").setup{
	cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
	cmake_build_directory = "build/${variant:buildType}",
	cmake_regenerate_on_save = false,
	cmake_soft_link_compile_commands = false,
	cmake_compile_commands_from_lsp = true,
}

-- Enable fuzzy autocompletion.
local cmp = require("cmp")

cmp.setup({
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	window = {
	},
	mapping = cmp.mapping.preset.insert({
    	["<C-e>"] = cmp.mapping.abort(),
    	["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "lua_snip" },
	}, {
		{ name = "buffer" },
	}),
})

--## TODO we may want more sources later on.

--## Use buffer source for `/` and `?` (doesn't work with `native_menu`).
cmp.setup.cmdline({ '/', '?' }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
	  { name = 'buffer' }
	}
})

--## Use cmdline & path source for ':' (doesn't work with `native_menu`).
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
})

-- Bad style highlights.
require("strict").setup({
	excluded_buftypes = { 'help', 'nofile', 'terminal', 'prompt' },
	deep_nesting = {
		highlight = false,
		highlight_group = "SpellBad",
		depth_limit = 5,
	},
	overlong_lines = {
		highlight = true,
		highlight_group = "SpellBad",
		length_limit = 120,
		split_on_save = false,
	},
	trailing_whitespace = {
		highlight = true,
		highlight_group = "SpellBad",
		remove_on_save = false,
	},
	trailing_empty_lines = {
		highlight = false,
		remove_on_save = false,
	},
	space_indentation = {
		highlight = false,
		convert_on_save = false,
	},
	tab_indentation = {
		highlight = false,
		convert_on_save = false,
	},
	-- I prefer the default highlight.
	todos = {
		highlight = false,
	},
})

require("Comment").setup() -- this sets the gcc/gbc keybindings.

require("lualine").setup({
	options = {
		theme = "dracula", -- assumes light theme
		section_separators = { left = "|", right = "|"},
		component_separators = { left = "|", right = "|"},
	},
})

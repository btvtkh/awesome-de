local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git", "--branch=stable",
		lazypath
	})
end

vim.opt.rtp:prepend(lazypath)

local plugins = {
	{ "nvim-treesitter/nvim-treesitter" },
	{ "neovim/nvim-lspconfig" },
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-buffer" },
	{ "hrsh7th/cmp-path" },
	{ "hrsh7th/cmp-cmdline" },
	{ "hrsh7th/nvim-cmp" },
	{ "hrsh7th/cmp-vsnip" },
	{ "hrsh7th/vim-vsnip" },
	{ "williamboman/mason.nvim" },
	{ "nvim-tree/nvim-tree.lua" },
	{ "willothy/nvim-cokeline", dependencies = { "nvim-lua/plenary.nvim" }, config = true },
	{ "nvim-lualine/lualine.nvim", dependencies = { "linrongbin16/lsp-progress.nvim" } },
	{ "lewis6991/gitsigns.nvim" },
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
	{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
	--{ "nvim-telescope/telescope.nvim", tag = "0.1.8", dependencies = { "nvim-lua/plenary.nvim" } },
	{ dir = "~/.config/nvim/themes/nymph" },
	{ dir = "~/.config/nvim/themes/haven" },
	{ dir = "~/.config/nvim/themes/everblush" },
	{ dir = "~/.config/nvim/themes/gruvbox" },
	{ dir = "~/.config/nvim/themes/placid" },
	{ dir = "~/.config/nvim/themes/astel" },
	{ dir = "~/.config/nvim/themes/ocean" }
}

require("lazy").setup(plugins)

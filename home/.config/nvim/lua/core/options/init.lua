vim.wo.number = true
vim.wo.relativenumber = true
vim.g.did_load_filetypes = 1
vim.g.formatoptions = "qrn1"
vim.opt.showmode = false
vim.opt.updatetime = 100
vim.wo.signcolumn = "yes"
vim.opt.scrolloff = 8
vim.opt.wrap = true
vim.wo.linebreak = true
vim.opt.virtualedit = "block"
vim.opt.undofile = true
vim.opt.shell = "/bin/sh"

vim.opt.mouse = "a"
vim.opt.mousefocus = true

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.clipboard = "unnamedplus"

vim.opt.shortmess:append("c")

vim.opt.expandtab = false
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true

vim.opt.fillchars = {
	vert = "┃",
	vertleft = "┫",
	vertright = "┣",
	verthoriz = "╋",
	horiz = "━",
	horizup = "┻",
	horizdown = "┳",
	fold = "·",
	eob = " ",
	diff = "-",
	msgsep = "━",
	foldopen = "-",
	foldsep = "│",
	foldclose = "+"
}

vim.opt.list = true
vim.opt.listchars = {
	space = "⋅",
	tab = "--",
}

vim.diagnostic.config({
	virtual_text = false,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = false,
})

vim.opt.termguicolors = true
vim.cmd.colorscheme("astel")

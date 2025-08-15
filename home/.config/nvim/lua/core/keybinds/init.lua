local map = vim.keymap.set
vim.g.mapleader = " "

map("n", "<leader>tt", ":NvimTreeToggle<CR>")
map("n", "<leader>tf", ":NvimTreeFocus<CR>")

map("n", "<S-Tab>", "<Plug>(cokeline-focus-prev)", { silent = true })
map("n", "<Tab>", "<Plug>(cokeline-focus-next)", { silent = true })
map("n", "<leader>x", ":bp<bar>sp<bar>bn<bar>bd<CR>")

for i = 1, 9 do
	map(
		"n",
		("<leader>%s"):format(i),
		("<Plug>(cokeline-focus-%s)"):format(i),
		{ silent = true }
	)
end

map("n", "<leader>df", vim.diagnostic.open_float)
map("n", "[d", vim.diagnostic.goto_prev)
map("n", "]d", vim.diagnostic.goto_next)
map("n", "<leader>dl", vim.diagnostic.setloclist)

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		local opts = { buffer = ev.buf }
		map("n", "gD", vim.lsp.buf.declaration, opts)
		map("n", "gd", vim.lsp.buf.definition, opts)
		map("n", "K", vim.lsp.buf.hover, opts)
		map("n", "gi", vim.lsp.buf.implementation, opts)
		map("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		map("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
		map("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
		map("n", "<space>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts)
		map("n", "<space>D", vim.lsp.buf.type_definition, opts)
		map("n", "<space>rn", vim.lsp.buf.rename, opts)
		map({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
		map("n", "gr", vim.lsp.buf.references, opts)
		map("n", "<space>f", function()
			vim.lsp.buf.format { async = true }
		end, opts)
	end,
})

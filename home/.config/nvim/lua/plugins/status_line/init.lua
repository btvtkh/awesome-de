require("lualine").setup {
	options = {
		theme = "auto",
		component_separators = "",
		section_separators = {left = "", right = ""},
		globalstatus = true
	},
	sections = {
		lualine_a = {"mode"},
		lualine_b = {"filename"},
		lualine_c = {
			{
				"branch",
				icon = ""
			},
			{
				"diff",
				symbols = { added = "+", modified = "~", removed = "-" },
				colored = false
			}
		},
		lualine_x = {},
		lualine_y = {
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = "E", warn = "W", info = "I", hint = "H" },
			},
			{
				function()
					local msg = "No Active Lsp"
					local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
					local clients = vim.lsp.get_clients()
					if next(clients) == nil then
						return msg
					end
					for _, client in ipairs(clients) do
						local filetypes = client.config.filetypes
						if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
							return client.name
						end
					end
					return msg
				end
			},
		},
		lualine_z = {
			"location",
			"progress"
		}
	}
}

vim.cmd([[
augroup lualine_augroup
	autocmd!
	autocmd User LspProgressStatusUpdated lua require("lualine").refresh()
augroup END
]])

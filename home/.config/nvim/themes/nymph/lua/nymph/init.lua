local Hl = require("nymph.highlights")
local Palette = require("nymph.palette")

local M = {}

function M.parse_color(color)
	if color == nil then
		return print('invalid color')
	end

	color = color:lower()

	if not color:find('#') and color ~= 'none' then
		color = Palette[color]
			or vim.api.nvim_get_color_by_name(color)
	end

	return color
end

function M.highlight(group, color)
	local fg = color.fg and M.parse_color(color.fg) or 'none'
	local bg = color.bg and M.parse_color(color.bg) or 'none'
	local sp = color.sp and M.parse_color(color.sp) or ''

	color = vim.tbl_extend('force', color, { fg = fg, bg = bg, sp = sp })
	vim.api.nvim_set_hl(0, group, color)
end

function M.set_colorscheme()
	if vim.g.colors_name then
		vim.cmd('hi clear')
	end

	vim.opt.termguicolors = true
	vim.g.colors_name = 'nymph'

	for group, color in pairs(Hl.set_colors(Palette)) do
		M.highlight(group, color)
	end
end

return M

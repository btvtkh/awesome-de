local get_hex = require("cokeline.hlgroups").get_hl_attr

require("cokeline").setup({
	default_hl = {
		fg = function(buffer)
			return buffer.is_focused and get_hex("Normal", "fg") or get_hex("Comment", "fg")
		end,
		bg = "NONE"
	},
	fill_hl = "Normal",
	sidebar = {
		filetype = {"NvimTree"},
		components = {
			{
				text = ""
			}
		}
	},
	components = {
		{
			text = function(buffer)
				return (buffer.index ~= 1) and "┃" or ""
			end,
			fg = get_hex("VertSplit", "fg")
		},
		{
			text = function(buffer)
				return "   " .. buffer.index .. ": " .. buffer.unique_prefix .. buffer.filename
			end,
		},
		{
			text = function(buffer)
				return buffer.is_modified and " • " or "   "
			end,
			fg = get_hex("Error", "fg")
		}
	}
})

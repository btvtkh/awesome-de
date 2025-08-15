local p = require('gruvbox.palette')

return {
	normal = {
		a = { bg = p.bg_alt, fg = p.yellow },
		b = { bg = p.bg_alt, fg = p.fg },
		c = { bg = p.bg_alt, fg = p.fg_alt },
	},
	insert = {
		a = { bg = p.bg_alt, fg = p.red },
		b = { bg = p.bg_alt, fg = p.fg },
		c = { bg = p.bg_alt, fg = p.fg_alt },
	},
	command = {
		a = { bg = p.bg_alt, fg = p.blue },
		b = { bg = p.bg_alt, fg = p.fg },
		c = { bg = p.bg_alt, fg = p.fg_alt },
	},
	visual = {
		a = { bg = p.bg_alt, fg = p.orange },
		b = { bg = p.bg_alt, fg = p.fg },
		c = { bg = p.bg_alt, fg = p.fg_alt },
	},
	replace = {
		a = { bg = p.bg_alt, fg = p.magenta },
		b = { bg = p.bg_alt, fg = p.fg },
		c = { bg = p.bg_alt, fg = p.fg_alt },
	},
	inactive = {
		a = { bg = p.bg_alt, fg = p.fg_alt },
		b = { bg = p.bg_alt, fg = p.fg_alt },
		c = { bg = p.bg_alt, fg = p.fg_alt },
	},
}

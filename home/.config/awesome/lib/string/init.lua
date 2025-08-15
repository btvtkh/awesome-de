local M = {}

function M.markup(text, args)
	if not text then return end
	args = args or {}

	local function pttostr(int)
		local str = tostring(int)
		return str:match("pt$") and str or str .. "pt"
	end

	local function prctostr(int)
		local str = tostring(int)
		return str:match("%%$") and str or str .. "%"
	end

	local font = args.font_name and " font='" .. args.font_name .. "'" or ""
	local size = args.font_size and " size='" .. pttostr(args.font_size) .. "'" or ""
	local style = args.font_style and " style='" .. args.font_style .. "'" or ""
	local weight = args.font_weight and " weight='" .. args.font_weight .. "'" or ""
	local underline = args.underline and " underline='" .. args.underline .. "'" or ""
	local overline = args.overline and " overline='" .. args.overline .. "'" or ""
	local strikethrough = args.strikethrough and " strikethrough='" .. tostring(args.strikethrough) .. "'" or ""
	local alpha = args.alpha and " alpha='" .. prctostr(args.alpha) .. "'" or ""
	local fg = args.fg and " foreground='" .. args.fg .. "'" or ""
	local bg = args.bg and " background='" .. args.bg .. "'" or ""

	return "<span" .. font .. size .. style .. weight .. underline ..
		overline .. strikethrough .. alpha .. fg .. bg .. ">" .. text .. "</span>"
end

function M.capitalize(str)
	if not str or str == "" then return str end
	return str:sub(1, 1):upper() .. str:sub(2):lower()
end

function M.lua_escape(str)
	return str:gsub("[%[%]%(%)%.%-%+%?%*%^%$%%]", "%%%1")
end

return M

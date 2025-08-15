local textbox = require("wibox.widget.textbox")
local gtable = require("gears.table")
local gstring = require("gears.string")

local label = {}

local function pttostr(int)
	local str = tostring(int)
	return str:match("pt$") and str or str .. "pt"
end

local function prctostr(int)
	local str = tostring(int)
	return str:match("%%$") and str or str .. "%"
end

local function markup(args)
	args = args or {}
	local text = args.label and gstring.xml_escape(tostring(args.label)) or ""
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

local properties = {
	"label",
	"fg",
	"bg",
	"font_name",
	"font_size",
	"font_weight",
	"font_style",
	"underline",
	"overline",
	"strikethrough",
	"alpha"
}

for _, prop_name in ipairs(properties) do
	label["set_" .. prop_name] = function(self, value)
		local changed = self._private[prop_name] ~= value
		self._private[prop_name] = value

		if changed then
			self:set_markup(markup(self._private))
		end
	end

	label["get_" .. prop_name] = function(self)
		return self._private[prop_name] == nil
			and properties[prop_name]
			or self._private[prop_name]
	end
end

local function new(args)
	args = args or {}

	local ret = textbox()
	gtable.crush(ret._private, args)
	gtable.crush(ret, label, true)

	if ret._private.label then
		ret:set_label(ret._private.label)
	end

	return ret
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })

local imagebox = require("wibox.widget.imagebox")
local gtable = require("gears.table")
local beautiful = require("beautiful")

local icon = {}

function icon:set_color(value)
	local changed = self._private.color ~= value
	self._private.color = value

	local stylesheet = "* { color: %s; !important }"

	if changed then
		self:set_stylesheet(string.format(stylesheet, value))
	end
end

function icon:get_color()
	return self._private.color
end

function icon:set_icon(value)
	local changed = self._private.color ~= value
	self._private.color = value

	if changed then
		self:set_image(value)
	end
end

function icon:get_icon()
	return self._private.icon
end

function icon:set_size(value)
	local changed = self._private.size ~= value
	self._private.size = value

	if changed then
		self:set_forced_width(value)
		self:set_forced_height(value)
	end
end

function icon:get_size()
	return self._private.size
end

local function new(args)
	args = args or {}

	local ret = imagebox()
	gtable.crush(ret._private, args)
	gtable.crush(ret, icon, true)

	ret:set_halign(args.halign or "center")
	ret:set_valign(args.valign or "center")
	ret:set_color(args.color or beautiful.fg)
	ret:set_icon(args.icon)

	return ret
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })

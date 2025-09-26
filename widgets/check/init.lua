local base = require("wibox.widget.base")
local gcolor = require("gears.color")
local gtable = require("gears.table")
local gshape = require("gears.shape")
local beautiful = require("beautiful")

local check = {}

local properties = {
	"checked",
	"trough_shape",
	"trough_color",
	"trough_margins",
	"trough_border_color",
	"trough_border_width",
	"check_shape",
	"check_color",
	"check_margins",
	"check_border_color",
	"check_border_width"
}

for _, prop_name in ipairs(properties) do
	check["set_" .. prop_name] = function(self, value)
		local changed = self._private[prop_name] ~= value
		self._private[prop_name] = value

		if changed then
			self:emit_signal("property::" .. prop_name, value)
			self:emit_signal("widget::redraw_needed")
		end
	end

	check["get_" .. prop_name] = function(self)
		return self._private[prop_name] == nil
			and properties[prop_name]
			or self._private[prop_name]
	end
end

function check:draw(_, cr, width, height)
	local wp = self._private

	local trough_offset = wp.trough_border_width/2 + wp.trough_margins
	local trough_width = width - wp.trough_border_width - wp.trough_margins*2
	local trough_height = height - wp.trough_border_width - wp.trough_margins*2

	cr:set_source(gcolor(wp.trough_color))
	cr:translate(trough_offset, trough_offset)
	wp.trough_shape(cr, trough_width, trough_height)

	if wp.trough_border_width == 0 then
		cr:fill()
	elseif wp.trough_border_width > 0 then
		cr:fill_preserve()
		cr:set_line_width(wp.trough_border_width)
		if wp.trough_border_color then
			cr:save()
			cr:set_source(gcolor(wp.trough_border_color))
			cr:stroke()
			cr:restore()
		else
			cr:stroke()
		end
	end

	if wp.checked then
		cr:translate(-trough_offset, -trough_offset)

		local check_offset = wp.check_border_width/2 + wp.check_margins
		local check_width = width - wp.check_border_width - wp.check_margins*2
		local check_height = height - wp.check_border_width - wp.check_margins*2

		cr:set_source(gcolor(wp.check_color))
		cr:translate(check_offset, check_offset)
		wp.check_shape(cr, check_width, check_height)

		if wp.check_border_width == 0 then
			cr:fill()
		elseif wp.check_border_width > 0 then
			cr:fill_preserve()
			cr:set_line_width(wp.check_border_width)
			if wp.check_border_color then
				cr:save()
				cr:set_source(gcolor(wp.check_border_color))
				cr:stroke()
				cr:restore()
			else
				cr:stroke()
			end
		end
	end
end

function check:fit(_, width, height)
	local size = math.min(width, height)
	return size, size
end

local function new(args)
	args = args or {}

	args.trough_shape = args.trough_shape or gshape.rectangle
	args.trough_color = args.trough_color or beautiful.bg_urg
	args.trough_margins = args.trough_margins or 0
	args.trough_border_color = args.trough_border_color or beautiful.bg_urg
	args.trough_border_width = args.trough_border_width or 0

	args.check_shape = args.check_shape or gshape.rectangle
	args.check_color = args.check_color or beautiful.ac
	args.check_margins = args.check_margins or 0
	args.check_border_color = args.check_border_color or beautiful.ac
	args.check_border_width = args.check_border_width or 0

	args.checked = args.checked or false

	local ret = base.make_widget(nil, nil, {
		enable_properties = true,
	})

	gtable.crush(ret._private, args)
	gtable.crush(ret, check, true)

	return ret
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })

local base = require("wibox.widget.base")
local gcolor = require("gears.color")
local gtable = require("gears.table")
local gshape = require("gears.shape")
local beautiful = require("beautiful")

local switch = {}

local properties = {
	"checked",
	"trough_shape",
	"trough_color",
	"trough_checked_color",
	"trough_height",
	"trough_margins",
	"trough_border_color",
	"trough_checked_border_color",
	"trough_border_width",
	"slider_shape",
	"slider_color",
	"slider_checked_color",
	"slider_height",
	"slider_width",
	"slider_margins",
	"slider_border_color",
	"slider_checked_border_color",
	"slider_border_width"
}

for _, prop_name in ipairs(properties) do
	switch["set_" .. prop_name] = function(self, value)
		local changed = self._private[prop_name] ~= value
		self._private[prop_name] = value

		if changed then
			self:emit_signal("property::" .. prop_name, value)
			self:emit_signal("widget::redraw_needed")
		end
	end

	switch["get_" .. prop_name] = function(self)
		return self._private[prop_name] == nil
			and properties[prop_name]
			or self._private[prop_name]
	end
end

function switch:draw(_, cr, width, height)
	local wp = self._private

	local trough_offset_x = wp.trough_border_width/2 + wp.trough_margins
	local trough_offset_y = (height - ((wp.trough_height or height) - wp.trough_border_width - wp.trough_margins*2))/2
	local trough_width = width - wp.trough_border_width - wp.trough_margins*2
	local trough_height = (wp.trough_height or height) - wp.trough_border_width - wp.trough_margins*2

	cr:set_source(gcolor(wp.checked and wp.trough_checked_color or wp.trough_color))
	cr:translate(trough_offset_x, trough_offset_y)
	wp.trough_shape(cr, trough_width, trough_height)

	if wp.trough_border_width == 0 then
		cr:fill()
	elseif wp.trough_border_width > 0 then
		cr:fill_preserve()
		cr:set_line_width(wp.trough_border_width)
		if wp.trough_border_color and wp.trough_checked_border_color then
			cr:save()
			cr:set_source(gcolor(wp.checked and wp.trough_checked_border_color or wp.trough_border_color))
			cr:stroke()
			cr:restore()
		else
			cr:stroke()
		end
	end

	cr:translate(-trough_offset_x, -trough_offset_y)

	local slider_offset_x = wp.checked
		and width - ((wp.slider_width or height) - wp.slider_border_width/2 - wp.slider_margins)
		or wp.slider_border_width/2 + wp.slider_margins
	local slider_offset_y = (height - ((wp.slider_height or height) - wp.slider_border_width - wp.slider_margins*2))/2
	local slider_width = (wp.slider_width or height) - wp.slider_border_width - wp.slider_margins*2
	local slider_height = (wp.slider_height or height) - wp.slider_border_width - wp.slider_margins*2

	cr:set_source(gcolor(wp.checked and wp.slider_checked_color or wp.slider_color))
	cr:translate(slider_offset_x, slider_offset_y)
	wp.slider_shape(cr, slider_width, slider_height)

	if wp.slider_border_width == 0 then
		cr:fill()
	elseif wp.slider_border_width > 0 then
		cr:fill_preserve()
		cr:set_line_width(wp.slider_border_width)
		if wp.slider_border_color and wp.slider_checked_border_color then
			cr:save()
			cr:set_source(gcolor(wp.checked and wp.slider_checked_border_color or wp.slider_border_color))
			cr:stroke()
			cr:restore()
		else
			cr:stroke()
		end
	end
end

function switch:fit(_, width, height)
	return width, height
end

local function new(args)
	args = args or {}

	args.trough_shape = args.trough_shape or gshape.rectangle
	args.trough_color = args.trough_color or beautiful.bg_urg
	args.trough_checked_color = args.trough_checked_color or beautiful.ac
	args.trough_height = args.trough_height
	args.trough_margins = args.trough_margins or 0
	args.trough_border_color = args.trough_border_color or beautiful.bg_urg
	args.trough_checked_border_color = args.trough_checked_border_color or beautiful.ac
	args.trough_border_width = args.trough_border_width or 0

	args.slider_shape = args.slider_shape or gshape.rectangle
	args.slider_color = args.slider_color or beautiful.fg
	args.slider_checked_color = args.slider_checked_color or beautiful.bg_alt
	args.slider_width = args.slider_width
	args.slider_height = args.slider_height
	args.slider_margins = args.slider_margins or 0
	args.slider_border_color = args.slider_border_color or beautiful.fg
	args.slider_checked_border_color = args.slider_checked_border_color or beautiful.bg_alt
	args.slider_border_width = args.slider_border_width or 0

	args.checked = args.checked or false

	local ret = base.make_widget(nil, nil, {
		enable_properties = true,
	})

	gtable.crush(ret._private, args)
	gtable.crush(ret, switch, true)

	return ret
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })

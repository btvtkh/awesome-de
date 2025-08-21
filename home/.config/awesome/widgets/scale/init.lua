local base = require("wibox.widget.base")
local gcolor = require("gears.color")
local gtable = require("gears.table")
local gshape = require("gears.shape")
local beautiful = require("beautiful")
local capi = { mouse = mouse, mousegrabber = mousegrabber, root = root }

local scale = {}

local properties = {
	"value",
	"min",
	"max",
	"trough_shape",
	"trough_color",
	"trough_height",
	"trough_margins",
	"trough_border_color",
	"trough_border_width",
	"highlight_shape",
	"highlight_color",
	"highlight_height",
	"highlight_margins",
	"highlight_border_color",
	"highlight_border_width",
	"slider_shape",
	"slider_color",
	"slider_height",
	"slider_width",
	"slider_margins",
	"slider_border_color",
	"slider_border_width"
}

for _, prop_name in ipairs(properties) do
	scale["set_" .. prop_name] = function(self, value)
		local changed = self._private[prop_name] ~= value
		self._private[prop_name] = value

		if changed then
			self:emit_signal("property::" .. prop_name, value)
			self:emit_signal("widget::redraw_needed")
		end
	end

	scale["get_" .. prop_name] = function(self)
		return self._private[prop_name] == nil
			and properties[prop_name]
			or self._private[prop_name]
	end
end

function scale:set_value(value)
	if not value then return end
	value = math.max(self:get_min(), math.min(self:get_max(), value))
	local changed = self._private.value ~= value

	self._private.value = value

	if changed then
		self:emit_signal( "property::value", value)
		self:emit_signal( "widget::redraw_needed" )
	end
end

function scale:get_is_dragging()
	return self._private.is_dragging
end

function scale:draw(_, cr, width, height)
	local wp = self._private
	local range = wp.max - wp.min
	local rate = (wp.value - wp.min)/range

	local trough_offset_x = wp.trough_border_width/2 + wp.trough_margins
	local trough_offset_y = (height - ((wp.trough_height or height) - wp.trough_border_width - wp.trough_margins*2))/2
	local trough_width = width - wp.trough_border_width - wp.trough_margins*2
	local trough_height = (wp.trough_height or height) - wp.trough_border_width - wp.trough_margins*2

	cr:set_source(gcolor(wp.trough_color))
	cr:translate(trough_offset_x, trough_offset_y)
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

	cr:translate(-trough_offset_x, -trough_offset_y)

	local highlight_offset_x = wp.highlight_border_width/2 + wp.highlight_margins
	local highlight_offset_y = (height - ((wp.highlight_height or height) - wp.highlight_border_width - wp.highlight_margins*2))/2
	local highlight_width = width*rate + (wp.slider_width or height)*(1 - rate) - wp.highlight_border_width - wp.highlight_margins*2
	local highlight_height = (wp.highlight_height or height) - wp.highlight_border_width - wp.highlight_margins*2

	cr:set_source(gcolor(wp.highlight_color))
	cr:translate(highlight_offset_x, highlight_offset_y)
	wp.highlight_shape(cr, highlight_width, highlight_height)

	if wp.highlight_border_width == 0 then
		cr:fill()
	elseif wp.highlight_border_width > 0 then
		cr:fill_preserve()
		cr:set_line_width(wp.highlight_border_width)
		if wp.highlight_border_color then
			cr:save()
			cr:set_source(gcolor(wp.highlight_border_color))
			cr:stroke()
			cr:restore()
		else
			cr:stroke()
		end
	end

	cr:translate(-highlight_offset_x, -highlight_offset_y)

	local slider_offset_x = width*rate + ((wp.slider_width or height)*(1 - rate) - ((wp.slider_width or height) - wp.slider_border_width/2 - wp.slider_margins))
	local slider_offset_y = (height - ((wp.slider_height or height) - wp.slider_border_width - wp.slider_margins*2))/2
	local slider_width = (wp.slider_width or height) - wp.slider_border_width - wp.slider_margins*2
	local slider_height = (wp.slider_height or height) - wp.slider_border_width - wp.slider_margins*2

	cr:set_source(gcolor(wp.slider_color))
	cr:translate(slider_offset_x, slider_offset_y)
	wp.slider_shape(cr, slider_width, slider_height)

	if wp.slider_border_width == 0 then
		cr:fill()
	elseif wp.slider_border_width > 0 then
		cr:fill_preserve()
		cr:set_line_width(wp.slider_border_width)
		if wp.slider_border_color then
			cr:save()
			cr:set_source(gcolor(wp.slider_border_color))
			cr:stroke()
			cr:restore()
		else
			cr:stroke()
		end
	end
end

function scale:fit(_, width, height)
	return width, height
end

local function get_extremums(self)
	local min = self._private.min
	local max = self._private.max
	local interval = max - min
	return min, max, interval
end

local function move_handle(self, width, x)
	local min, _, interval = get_extremums(self)
	self:set_value(min + (interval*x/width))
end

local function new(args)
	args = args or {}

	args.trough_shape = args.trough_shape or gshape.rectangle
	args.trough_color = args.trough_color or beautiful.bg_urg
	args.trough_height = args.trough_height
	args.trough_margins = args.trough_margins or 0
	args.trough_border_color = args.trough_border_color or beautiful.bg_urg
	args.trough_border_width = args.trough_border_width or 0

	args.highlight_shape = args.highlight_shape or gshape.rectangle
	args.highlight_color = args.highlight_color or beautiful.ac
	args.highlight_height = args.highlight_height
	args.highlight_margins = args.highlight_margins or 0
	args.highlight_border_color = args.highlight_border_color or beautiful.ac
	args.highlight_border_width = args.highlight_border_width or 0

	args.slider_shape = args.slider_shape or gshape.rectangle
	args.slider_color = args.slider_color or beautiful.bg_alt
	args.slider_width = args.slider_width
	args.slider_height = args.slider_height
	args.slider_margins = args.slider_margins or 0
	args.slider_border_color = args.slider_border_color or beautiful.bg_alt
	args.slider_border_width = args.slider_border_width or 0

	args.min = args.min or 0
	args.max = args.max or 100
	args.value = math.max(args.min, math.min(args.max, (args.value or 0)))

	local ret = base.make_widget(nil, nil, {
		enable_properties = true,
	})

	gtable.crush(ret._private, args)
	gtable.crush(ret, scale, true)

	local wp = ret._private

	wp.is_dragging = false

	wp.on_button_press = function(self, x, y, button_id, _, geo)
		if button_id ~= 1 then return end

		local matrix_from_device = geo.hierarchy:get_matrix_from_device()
		local width = geo.widget_width

		move_handle(self, width, x, y)
		self._private.is_dragging = true
		self:emit_signal("property::is_dragging", self._private.is_dragging)
		self:emit_signal("dragging-started")

		local wgeo = geo.drawable.drawable:geometry()
		local matrix = matrix_from_device:translate(-wgeo.x, -wgeo.y)

		capi.mousegrabber.run(function(mouse)
			if not mouse.buttons[1] then
				self._private.is_dragging = false
				self:emit_signal("property::is_dragging", self._private.is_dragging)
				self:emit_signal("dragging-stopped")
				return false
			end

			move_handle(self, width, matrix:transform_point(mouse.x, mouse.y))

			return true
		end, nil)
	end

	ret:connect_signal("button::press", wp.on_button_press)

	return ret
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })

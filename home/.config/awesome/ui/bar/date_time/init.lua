local awful = require("awful")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local dpi = beautiful.xresources.apply_dpi
local day_info_panel = require("ui.day_info_panel").get_default()

local function calc_timeout(real_timeout)
	return real_timeout - os.time() % real_timeout
end

return function()
	local ret = wibox.widget {
		widget = widgets.button,
		buttons = {
			awful.button({}, 1, nil, function()
				day_info_panel:toggle()
			end)
		},
		bg_normal = beautiful.bg_alt,
		bg_hover = beautiful.bg_urg,
		bg_active = beautiful.bg_alt,
		fg_active = beautiful.fg_alt,
		shape = shape.rrect(dpi(10)),
		{
			widget = wibox.container.margin,
			margins = { left = dpi(10), right = dpi(10) },
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(8),
				{
					id = "date-label",
					widget = widgets.label,
					font_weight = 500,
					font_size = 11
				},
				{
					widget = wibox.container.margin,
					margins = { top = dpi(8), bottom = dpi(8) },
					{
						id = "separator",
						widget = wibox.widget.separator,
						forced_height = 1,
						forced_width = beautiful.separator_thickness,
						orientation = "vertical"
					}
				},
				{
					id = "time-label",
					widget = widgets.label,
					font_weight = 500,
					font_size = 11
				}
			}
		}
	}

	local wp = ret._private
	local separator = ret:get_children_by_id("separator")[1]
	local date_label = ret:get_children_by_id("date-label")[1]
	local time_label = ret:get_children_by_id("time-label")[1]

	wp.timer = gtimer {
		timeout = calc_timeout(60),
		autostart = false,
		single_shot = false,
		call_now = false
	}

	wp.timer_callback = function()
		wp.timer.timeout = calc_timeout(60)
		date_label:set_label(os.date("%d %b, %a"))
		time_label:set_label(os.date("%H:%M"))
		wp.timer:again()
	end

	wp.on_hovered = function(w, is_hovered)
		separator:set_color(
			is_hovered and
				beautiful.fg_alt
			or
				( w:get_is_pressed() and
					beautiful.bg_urg
				or
					beautiful.fg_alt
				)
		)
	end

	wp.on_pressed = function(w, is_pressed)
		separator:set_color(
			is_pressed and
				beautiful.bg_urg
			or
				( w:get_is_hovered() and
					beautiful.fg_alt
				or
					beautiful.bg_urg
				)
		)
	end

	ret:connect_signal("property::is-pressed", wp.on_pressed)
	ret:connect_signal("property::is-hovered", wp.on_hovered)
	wp.timer:connect_signal("timeout", wp.timer_callback)

	date_label:set_label(os.date("%d %b, %a", os.time()))
	time_label:set_label(os.date("%H:%M", os.time()))
	wp.timer:start()

	return ret
end

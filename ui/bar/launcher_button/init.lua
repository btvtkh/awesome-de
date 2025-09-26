local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi
local Launcher = require("ui.launcher")

return function()
	local ret = wibox.widget {
		widget = widgets.button,
		buttons = {
			awful.button({}, 1, nil, function()
				Launcher.get_default():toggle()
			end)
		},
		bg_normal = beautiful.bg_alt,
		bg_hover = beautiful.bg_urg,
		bg_active = beautiful.bg_alt,
		fg_active = beautiful.fg_alt,
		shape = shape.rrect(dpi(10)),
		forced_width = dpi(32),
		{
			widget = wibox.container.place,
			halign = "center",
			valign = "center",
			{
				id = "icon",
				widget = widgets.icon,
				size = dpi(18),
				icon = icons.search
			}
		}
	}

	local wp = ret._private
	local icon = ret:get_children_by_id("icon")[1]

	wp.on_fg = function(_, fg)
		icon:set_color(fg)
	end

	ret:connect_signal("property::fg", wp.on_fg)
	icon:set_color(ret:get_fg_normal())

	return ret
end

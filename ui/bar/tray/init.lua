local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local shape = require("lib.shape")
local widgets = require("widgets")
local dpi = beautiful.xresources.apply_dpi
local icons = beautiful.icons

return function()
	local ret = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		shape = shape.rrect(dpi(10)),
		{
			widget = wibox.container.margin,
			margins = dpi(4),
			{
				id = "items-layout",
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(4),
				{
					id = "reveal-button",
					widget = widgets.button,
					forced_width = dpi(25),
					bg_normal = beautiful.bg_alt,
					bg_hover = beautiful.bg_urg,
					bg_active = beautiful.bg_alt,
					fg_active = beautiful.fg_alt,
					shape = shape.rrect(dpi(6)),
					{
						widget = wibox.container.place,
						halign = "center",
						valign = "center",
						{
							id = "reveal-icon",
							widget = widgets.icon,
							size = dpi(18)
						}
					}
				}
			}
		}
	}

	local wp = ret._private
	local items_layout = ret:get_children_by_id("items-layout")[1]
	local reveal_button = ret:get_children_by_id("reveal-button")[1]
	local reveal_icon = ret:get_children_by_id("reveal-icon")[1]

	wp.tray_visible = false

	wp.tray = wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(4),
		{
			widget = wibox.widget.systray
		}
	}

	wp.on_fg = function(_, fg)
		reveal_icon:set_color(fg)
	end

	reveal_button:buttons {
		awful.button({}, 1, function()
			wp.tray_visible = not wp.tray_visible

			reveal_icon:set_icon(wp.tray_visible and icons.chevron_right or icons.chevron_left)

			if wp.tray_visible then
				items_layout:insert(2, wp.tray)
			else
				items_layout:remove_widgets(wp.tray)
			end
		end)
	}

	reveal_button:connect_signal("property::fg", wp.on_fg)

	reveal_icon:set_color(reveal_button:get_fg_normal())
	reveal_icon:set_icon(wp.tray_visible and icons.chevron_right or icons.chevron_left)

	return ret
end

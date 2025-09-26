local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi

return function()
	local ret = wibox.widget {
		widget = wibox.container.background,
		forced_width = dpi(45),
		bg = beautiful.bg_alt,
		shape = shape.rrect(dpi(13)),
		{
			widget = wibox.container.margin,
			margins = dpi(4),
			{
				layout = wibox.layout.align.vertical,
				{
					id = "powermenu-button",
					widget = widgets.button,
					forced_width = dpi(37),
					forced_height = dpi(37),
					fg_normal = beautiful.red,
					fg_hover = beautiful.bg,
					fg_active = beautiful.bg,
					bg_hover = beautiful.red,
					bg_active = beautiful.fg_alt,
					shape = shape.rrect(dpi(8)),
					{
						widget = wibox.container.place,
						halign = "center",
						valign = "center",
						{
							id = "icon",
							widget = widgets.icon,
							size = dpi(18),
							icon = icons.power
						}
					}
				},
				nil,
				{
					layout = wibox.layout.fixed.vertical,
					spacing = beautiful.separator_thickness + dpi(2),
					spacing_widget = {
						widget = wibox.container.margin,
						margins = { left = dpi(10), right = dpi(10) },
						{
							widget = wibox.widget.separator,
							orientation = "horizontal"
						}
					},
					{
						id = "wallpaper-button",
						widget = widgets.button,
						forced_width = dpi(37),
						forced_height = dpi(37),
						fg_active = beautiful.fg_alt,
						bg_hover = beautiful.bg_urg,
						shape = shape.rrect(dpi(8)),
						{
							widget = wibox.container.place,
							halign = "center",
							valign = "center",
							{
								id = "icon",
								widget = widgets.icon,
								size = dpi(18),
								icon = icons.image
							}
						}
					},
					{
						id = "home-button",
						widget = widgets.button,
						forced_width = dpi(37),
						forced_height = dpi(37),
						fg_active = beautiful.fg_alt,
						bg_hover = beautiful.bg_urg,
						shape = shape.rrect(dpi(8)),
						{
							widget = wibox.container.place,
							halign = "center",
							valign = "center",
							{
								id = "icon",
								widget = widgets.icon,
								size = dpi(18),
								icon = icons.home
							}
						}
					}
				}
			}
		}
	}

	local wp = ret._private
	local powermenu_button = ret:get_children_by_id("powermenu-button")[1]
	local wallpaper_button = ret:get_children_by_id("wallpaper-button")[1]
	local home_button = ret:get_children_by_id("home-button")[1]

	wp.on_fg = function(w, fg)
		w:get_widget():get_widget():set_color(fg)
	end

	for _, b in ipairs({powermenu_button, wallpaper_button, home_button}) do
		b:connect_signal("property::fg", wp.on_fg)
		b:get_widget():get_widget():set_color(b:get_fg_normal())
	end

	return ret
end

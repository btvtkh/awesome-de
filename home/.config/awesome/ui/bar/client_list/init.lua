local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local dpi = beautiful.xresources.apply_dpi
local menu = require("ui.menu").get_default()

return function(s)
	local ret = awful.widget.tasklist {
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = {
			awful.button({}, 1, function(c)
				c:activate { context = "tasklist", action = "toggle_minimization" }
				menu:hide()
			end),
			awful.button({}, 3, function(c)
				menu:toggle_client_menu(c)
			end)
		},
		layout = {
			layout = wibox.layout.fixed.horizontal,
			spacing = dpi(3),
		},
		widget_template = {
			id = "c-button",
			widget = widgets.button,
			bg_normal = beautiful.bg_alt,
			bg_hover = beautiful.bg_urg,
			bg_active = beautiful.bg_alt,
			shape = shape.rrect(dpi(10)),
			{
				layout = wibox.layout.stack,
				{
					widget = wibox.container.margin,
					margins = { left = dpi(10), right = dpi(10) },
					{
						widget = wibox.container.constraint,
						strategy = "max",
						width = dpi(150),
						{
							id = "c-label",
							widget = widgets.label,
							align = "center",
							font_weight = 500,
							font_size = 11
						}
					}
				},
				{
					layout = wibox.layout.align.vertical,
					nil,
					nil,
					{
						widget = wibox.container.margin,
						margins = { left = dpi(13), right = dpi(13) },
						{
							id = "c-pointer",
							widget = wibox.container.background,
							shape = shape.prrect(true, true, false, false, dpi(2)),
							bg = beautiful.ac
						}
					}
				}
			}
		}
	}

	ret.widget_template.create_callback = function(cw, c)
		local c_button = cw:get_children_by_id("c-button")[1]
		local c_pointer = cw:get_children_by_id("c-pointer")[1]
		local c_label = cw:get_children_by_id("c-label")[1]

		c_label:set_label((c.class ~= nil and c.class ~= "") and c.class or "untitled")

		if c.minimized then
			c_button:set_fg_normal(beautiful.fg_alt)
			c_button:set_fg_hover(beautiful.fg_alt)
			c_button:set_fg_active(beautiful.fg)
		else
			c_button:set_fg_normal(beautiful.fg)
			c_button:set_fg_hover(beautiful.fg)
			c_button:set_fg_active(beautiful.fg)
		end

		if c.active then
			c_pointer:set_forced_height(dpi(3))
		else
			c_pointer:set_forced_height(0)
		end
	end

	ret.widget_template.update_callback = function(cw, c)
		local c_button = cw:get_children_by_id("c-button")[1]
		local c_pointer = cw:get_children_by_id("c-pointer")[1]

		if c.minimized then
			c_button:set_fg_normal(beautiful.fg_alt)
			c_button:set_fg_hover(beautiful.fg_alt)
			c_button:set_fg_active(beautiful.fg_alt)
		else
			c_button:set_fg_normal(beautiful.fg)
			c_button:set_fg_hover(beautiful.fg)
			c_button:set_fg_active(beautiful.fg_alt)
		end

		if c.active then
			c_pointer:set_forced_height(dpi(3))
		else
			c_pointer:set_forced_height(0)
		end
	end

	return ret
end

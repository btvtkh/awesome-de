local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi
local capi = { client = client }
local menu = require("ui.menu").get_default()
awful.titlebar.enable_tooltip = false

return function(c)
	if c.requests_no_titlebar then return end

	local ret = awful.titlebar(c, {
		size = dpi(35),
		position = "top"
	})

	ret._private = {}
	local wp = ret._private

	wp.close_button = wibox.widget {
		widget = widgets.button,
		bg_normal = c.active and beautiful.red or beautiful.bg_urg,
		bg_hover = c.active and beautiful.red or beautiful.bg_urg,
		bg_active = beautiful.fg_alt,
		fg_normal = beautiful.bg,
		fg_hover = beautiful.bg,
		fg_active = beautiful.bg,
		shape = shape.crcl(),
		{
			widget = wibox.container.margin,
			margins = dpi(3),
			{
				id = "icon",
				widget = widgets.icon,
				color = beautiful.bg,
				icon = icons.cross
			}
		}
	}

	wp.max_button = wibox.widget {
		widget = widgets.button,
		bg_normal = c.active and beautiful.yellow or beautiful.bg_urg,
		bg_hover = c.active and beautiful.yellow or beautiful.bg_urg,
		bg_active = beautiful.fg_alt,
		fg_normal = beautiful.bg,
		fg_hover = beautiful.bg,
		fg_active = beautiful.bg,
		shape = shape.crcl(),
		{
			widget = wibox.container.margin,
			margins = dpi(3),
			{
				id = "icon",
				widget = widgets.icon,
				color = beautiful.bg,
				icon = c.maximized and icons.minimize or icons.maximize
			}
		}
	}

	wp.min_button = wibox.widget {
		widget = widgets.button,
		bg_normal = c.active and beautiful.green or beautiful.bg_urg,
		bg_hover = c.active and beautiful.green or beautiful.bg_urg,
		bg_active = beautiful.fg_alt,
		fg_normal = beautiful.bg,
		fg_hover = beautiful.bg,
		fg_active = beautiful.bg,
		shape = shape.crcl(),
		{
			widget = wibox.container.margin,
			margins = dpi(3),
			{
				id = "icon",
				widget = widgets.icon,
				color = beautiful.bg,
				icon = icons.dash
			}
		}
	}

	wp.on_maximized = function()
		wp.max_button:get_children_by_id("icon")[1]:set_icon(
			c.maximized and icons.minimize or icons.maximize
		)
	end

	wp.on_active = function()
		wp.close_button:set_bg_normal(c.active and beautiful.red or beautiful.bg_urg)
		wp.close_button:set_bg_hover(c.active and beautiful.red or beautiful.bg_urg)
		wp.max_button:set_bg_normal(c.active and beautiful.yellow or beautiful.bg_urg)
		wp.max_button:set_bg_hover(c.active and beautiful.yellow or beautiful.bg_urg)
		wp.min_button:set_bg_normal(c.active and beautiful.green or beautiful.bg_urg)
		wp.min_button:set_bg_hover(c.active and beautiful.green or beautiful.bg_urg)
	end

	c:connect_signal("property::maximized", wp.on_maximized)
	c:connect_signal("property::active", wp.on_active)

	wp.close_button:buttons {
		awful.button({}, 1, nil, function()
			c:kill()
		end)
	}

	wp.max_button:buttons {
		awful.button({}, 1, nil, function()
			c.maximized = not c.maximized
			c:raise()
		end)
	}

	wp.min_button:buttons {
		awful.button({}, 1, nil, function()
			c.minimized = true
		end)
	}

	wp.buttons = {
		awful.button({}, 1, function()
			capi.client.focus = c
			c:raise()
			awful.mouse.client.move(c)
		end),
		awful.button({}, 2, function()
			menu:toggle_client_menu(c)
		end),
		awful.button({}, 3, function()
			capi.client.focus = c
			c:raise()
			awful.mouse.client.resize(c)
		end)
	}

	ret:setup {
		layout = wibox.layout.align.horizontal,
		{
			widget = wibox.container.background,
			buttons = wp.buttons
		},
		{
			widget = wibox.container.background,
			buttons = wp.buttons
		},
		{
			widget = wibox.container.margin,
			margins = dpi(9),
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(9),
				wp.min_button,
				wp.max_button,
				wp.close_button
			}
		}
	}

	return ret
end

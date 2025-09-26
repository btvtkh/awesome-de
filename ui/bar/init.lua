local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local has_common = require("lib.table").has_common
local dpi = beautiful.xresources.apply_dpi
local capi = { client = client }
local Client_list = require("ui.bar.client_list")
local Tag_list = require("ui.bar.tag_list")
local Tray = require("ui.bar.tray")
local Date_time = require("ui.bar.date_time")
local Kb_layout = require("ui.bar.kb_layout")
local Launcher_button = require("ui.bar.launcher_button")
local Control_button = require("ui.bar.control_button")
local Media_button = require("ui.bar.media_button")

local bar = {}

function bar.Secondary(s)
	local ret = awful.wibar {
		position = "bottom",
		ontop = true,
		screen = s,
		height = dpi(45),
		bg = "#00000000",
		widget = {
			widget = wibox.container.background,
			bg = beautiful.border_color_normal,
			{
				widget = wibox.container.margin,
				margins = { top = beautiful.border_width },
				{
					widget = wibox.container.background,
					bg = beautiful.bg,
					fg = beautiful.fg,
					{
						layout = wibox.layout.fixed.horizontal,
						{
							widget = wibox.container.margin,
							margins = dpi(6),
							{
								layout = wibox.layout.fixed.horizontal,
								spacing = dpi(3),
								Tag_list(s),
								Client_list(s)
							}
						}
					}
				}
			}
		}
	}

	local wp = ret._private

	wp.on_client_manage = function(c)
		local focused_screen = awful.screen.focused({ client = true })

		if ret.screen == focused_screen
		and has_common(c:tags(), focused_screen.selected_tags) then
			if c.fullscreen then
				ret.visible = false
			else
				ret.visible = true
			end
		end
	end

	wp.on_client_unmanage = function(c)
		local focused_screen = awful.screen.focused({ client = true })

		if ret.screen == focused_screen then
			if c.fullscreen then
				ret.visible = true
			end
		end
	end

	capi.client.connect_signal("request::manage", wp.on_client_manage)
	capi.client.connect_signal("focus", wp.on_client_manage)
	capi.client.connect_signal("property::fullscreen", wp.on_client_manage)

	capi.client.connect_signal("request::unmanage", wp.on_client_unmanage)
	capi.client.connect_signal("unfocus", wp.on_client_unmanage)
	capi.client.connect_signal("property::minimized", wp.on_client_unmanage)

	return ret
end

function bar.Primary(s)
	local ret = awful.wibar {
		position = "bottom",
		ontop = true,
		screen = s,
		height = dpi(45),
		bg = "#00000000",
		widget = {
			widget = wibox.container.background,
			bg = beautiful.border_color_normal,
			{
				widget = wibox.container.margin,
				margins = { top = beautiful.border_width },
				{
					widget = wibox.container.background,
					bg = beautiful.bg,
					fg = beautiful.fg,
					{
						layout = wibox.layout.align.horizontal,
						nil,
						{
							widget = wibox.container.margin,
							margins = dpi(6),
							{
								layout = wibox.layout.fixed.horizontal,
								spacing = dpi(3),
								Launcher_button(),
								Tag_list(s),
								Client_list(s)
							}
						},
						{
							widget = wibox.container.margin,
							margins = {
								top = dpi(6), bottom = dpi(6),
								left = 0, right = dpi(6)
							},
							{
								layout = wibox.layout.fixed.horizontal,
								spacing = dpi(3),
								Tray(),
								Kb_layout(),
								Media_button(),
								Date_time(),
								Control_button()
							}
						}
					}
				}
			}
		}
	}

	local wp = ret._private

	wp.on_client_manage = function(c)
		local focused_screen = awful.screen.focused({ client = true })

		if ret.screen == focused_screen
		and has_common(c:tags(), focused_screen.selected_tags) then
			if c.fullscreen then
				ret.visible = false
			else
				ret.visible = true
			end
		end
	end

	wp.on_client_unmanage = function(c)
		local focused_screen = awful.screen.focused({ client = true })

		if ret.screen == focused_screen then
			if c.fullscreen then
				ret.visible = true
			end
		end
	end

	capi.client.connect_signal("request::manage", wp.on_client_manage)
	capi.client.connect_signal("focus", wp.on_client_manage)
	capi.client.connect_signal("property::fullscreen", wp.on_client_manage)

	capi.client.connect_signal("request::unmanage", wp.on_client_unmanage)
	capi.client.connect_signal("unfocus", wp.on_client_unmanage)
	capi.client.connect_signal("property::minimized", wp.on_client_unmanage)

	return ret
end

return bar

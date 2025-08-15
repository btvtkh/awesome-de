local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi
local Network = require("service.network")

return function()
	local nm_client = Network.get_default()

	local ret = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(60),
		bg = beautiful.bg_alt,
		fg = beautiful.fg,
		shape = shape.rrect(dpi(13)),
		{
			layout = wibox.layout.fixed.horizontal,
			fill_space = true,
			{
				id = "toggle-button",
				widget = widgets.button,
				forced_width = dpi(180),
				bg_hover = beautiful.bg_urg,
				fg_normal = beautiful.fg,
				fg_hover = beautiful.fg,
				fg_active = beautiful.fg_alt,
				{
					layout = wibox.layout.align.horizontal,
					{
						widget = wibox.container.margin,
						margins = { left = dpi(15) },
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = dpi(15),
							{
								widget = wibox.container.place,
								halign = "center",
								valign = "center",
								{
									id = "toggle-icon",
									widget = widgets.icon,
									size = dpi(18),
									icon = icons.wifi
								}
							},
							{
								widget = wibox.container.place,
								halign = "center",
								{
									layout = wibox.layout.fixed.vertical,
									{
										widget = widgets.label,
										font_weight = "bold",
										font_size = 12,
										label = "Wifi"
									},
									{
										id = "state-label",
										widget = widgets.label,
										font_size = 9,
										alpha = 70,
									}
								}
							}
						}
					},
					nil,
					{
						widget = wibox.container.margin,
						margins = { top = dpi(15), bottom = dpi(15) },
						{
							id = "separator",
							widget = wibox.widget.separator,
							forced_width = 1,
						}
					}
				}
			},
			{
				id = "reveal-button",
				widget = widgets.button,
				bg_hover = beautiful.bg_urg,
				fg_normal = beautiful.fg,
				fg_hover = beautiful.fg,
				fg_active = beautiful.fg_alt,
				{
					widget = wibox.container.place,
					halign = "center",
					valign = "center",
					{
						id = "reveal-icon",
						widget = widgets.icon,
						size = dpi(18),
						icon = icons.chevron_right
					}
				},
			}
		}
	}

	local wp = ret._private
	local toggle_button = ret:get_children_by_id("toggle-button")[1]
	local toggle_icon = ret:get_children_by_id("toggle-icon")[1]
	local reveal_button = ret:get_children_by_id("reveal-button")[1]
	local reveal_icon = ret:get_children_by_id("reveal-icon")[1]
	local separator = ret:get_children_by_id("separator")[1]
	local state_label = ret:get_children_by_id("state-label")[1]

	wp.on_toggle_button_fg = function(_, fg)
		toggle_icon:set_color(fg)
	end

	wp.on_reveal_button_fg = function(_, fg)
		reveal_icon:set_color(fg)
	end

	wp.on_hovered = function(w, is_hovered)
		separator:set_color(
			not nm_client:get_wireless_enabled() and
				( is_hovered and
					beautiful.fg_alt
				or
					( w:get_is_pressed() and
						beautiful.bg_urg
					or
						beautiful.fg_alt
					)
				)
			or
				beautiful.bg
		)
	end

	wp.on_pressed = function(w, is_pressed)
		separator:set_color(
			not nm_client:get_wireless_enabled() and
				( is_pressed and
					beautiful.bg_urg
				or
					( w:get_is_hovered() and
						beautiful.fg_alt
					or
						beautiful.bg_urg
					)
				)
			or
				beautiful.bg
		)
	end

	wp.on_wireless_enabled = function(_, enabled)
		if enabled then
			state_label:set_label("Enabled")
			ret:set_bg(beautiful.ac)
			ret:set_fg(beautiful.bg)
			toggle_button:set_bg_normal(beautiful.ac)
			toggle_button:set_bg_hover(beautiful.ac)
			toggle_button:set_bg_active(beautiful.fg_alt)
			toggle_button:set_fg_normal(beautiful.bg)
			toggle_button:set_fg_hover(beautiful.bg)
			toggle_button:set_fg_active(beautiful.bg)
			reveal_button:set_bg_normal(beautiful.ac)
			reveal_button:set_bg_hover(beautiful.ac)
			reveal_button:set_bg_active(beautiful.fg_alt)
			reveal_button:set_fg_normal(beautiful.bg)
			reveal_button:set_fg_hover(beautiful.bg)
			reveal_button:set_fg_active(beautiful.bg)
			separator:set_color(beautiful.bg)
		else
			state_label:set_label("Disabled")
			ret:set_bg(beautiful.bg_alt)
			ret:set_fg(beautiful.fg)
			toggle_button:set_bg_normal(nil)
			toggle_button:set_bg_hover(beautiful.bg_urg)
			toggle_button:set_bg_active(nil)
			toggle_button:set_fg_normal(beautiful.fg)
			toggle_button:set_fg_hover(beautiful.fg)
			toggle_button:set_fg_active(beautiful.fg_alt)
			reveal_button:set_bg_normal(nil)
			reveal_button:set_bg_hover(beautiful.bg_urg)
			reveal_button:set_bg_active(nil)
			reveal_button:set_fg_normal(beautiful.fg)
			reveal_button:set_fg_hover(beautiful.fg)
			reveal_button:set_fg_active(beautiful.fg_alt)
			separator:set_color(toggle_button:get_is_hovered() and beautiful.fg_alt or beautiful.bg_urg)
		end
	end

	nm_client:connect_signal("property::wireless-enabled", wp.on_wireless_enabled)

	toggle_button:connect_signal("property::is-pressed", wp.on_pressed)
	toggle_button:connect_signal("property::is-hovered", wp.on_hovered)
	toggle_button:connect_signal("property::fg", wp.on_toggle_button_fg)
	reveal_button:connect_signal("property::is-pressed", wp.on_pressed)
	reveal_button:connect_signal("property::is-hovered", wp.on_hovered)
	reveal_button:connect_signal("property::fg", wp.on_reveal_button_fg)

	toggle_button:buttons {
		awful.button({}, 1, nil, function()
			nm_client:set_wireless_enabled(not nm_client:get_wireless_enabled())
		end)
	}

	toggle_icon:set_color(toggle_button:get_fg_normal())
	reveal_icon:set_color(reveal_button:get_fg_normal())

	wp.on_wireless_enabled(nm_client, nm_client:get_wireless_enabled())

	return ret
end

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi
local Bluetooth = require("service.bluetooth")

local function create_device_widget(path, device)
	local ret = wibox.widget {
		widget = widgets.button,
		shape = shape.rrect(dpi(13)),
		forced_height = dpi(55),
		bg_hover = beautiful.bg_urg,
		bg_active = beautiful.bg_alt,
		fg_active = beautiful.fg_alt,
		{
			widget = wibox.container.margin,
			margins = { left = dpi(15), right = dpi(15) },
			{
				layout = wibox.layout.align.horizontal,
				{
					widget = wibox.container.constraint,
					width = dpi(220),
					{
						widget = wibox.container.place,
						halign = "center",
						{
						layout = wibox.layout.fixed.vertical,
							{
								id = "name-label",
								widget = widgets.label,
								valign = "center",
								font_size = 12
							},
							{
								id = "description-label",
								widget = widgets.label,
								valign = "center",
								font_size = 9,
								alpha = 70
							}
						}
					}
				},
				nil,
				{
					widget = wibox.container.constraint,
					width = dpi(130),
					{
						id = "percentage-label",
						widget = widgets.label,
						align = "center",
						font_size = 12
					}
				}
			}
		}
	}

	local wp = ret._private
	local name_label = ret:get_children_by_id("name-label")[1]
	local description_label = ret:get_children_by_id("description-label")[1]
	local percentage_label = ret:get_children_by_id("percentage-label")[1]

	wp.device_path = path

	wp.on_connected = function(_, cnd)
		description_label:set_label(cnd and "Connected" or device:get_address())
	end

	wp.on_percentage = function(_, perc)
		percentage_label:set_label(perc ~= nil and string.format("%.0f%%", perc) or "")
	end

	device:connect_signal("property::connected", wp.on_connected)
	device:connect_signal("property::percentage", wp.on_percentage)

	ret:buttons {
		awful.button({}, 1, nil, function()
			if not device:get_connected() then
				device:connect()
			else
				device:disconnect()
			end
		end)
	}

	name_label:set_label(device:get_name() or "Unnamed device")
	description_label:set_label(device:get_connected() and "Connected" or device:get_address())

	percentage_label:set_label(
		device:get_percentage() and string.format("%.0f%%", device:get_percentage()) or ""
	)

	return ret
end

return function()
	local bt_adapter = Bluetooth.get_default()

	local ret = wibox.widget {
		widget = wibox.container.background,
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(8),
			{
				id = "devices-layout",
				layout = wibox.layout.overflow.vertical,
				forced_height = dpi(400),
				forced_width = dpi(400),
				scrollbar_enabled = false,
				step = 40,
				spacing = dpi(3)
			},
			{
				widget = wibox.container.background,
				forced_height = dpi(43),
				bg = beautiful.bg_alt,
				shape = shape.rrect(dpi(13)),
				{
					widget = wibox.container.margin,
					margins = dpi(4),
					{
						layout = wibox.layout.align.horizontal,
						{
							id = "bottombar-close-button",
							widget = widgets.button,
							forced_width = dpi(35),
							forced_height = dpi(35),
							shape = shape.rrect(dpi(9)),
							bg_hover = beautiful.bg_urg,
							fg_active = beautiful.fg_alt,
							{
								widget = wibox.container.place,
								halign = "center",
								valign = "center",
								{
									id = "bottombar-close-icon",
									widget = widgets.icon,
									size = dpi(18),
									icon = icons.chevron_left
								}
							}
						},
						nil,
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = beautiful.separator_thickness + dpi(2),
							spacing_widget = {
								widget = wibox.container.margin,
								margins = { top = dpi(10), bottom = dpi(10) },
								{
									widget = wibox.widget.separator,
									orientation = "vertical"
								}
							},
							{
								id = "bottombar-discover-button",
								widget = widgets.button,
								forced_width = dpi(35),
								forced_height = dpi(35),
								shape = shape.rrect(dpi(9)),
								bg_hover = beautiful.bg_urg,
								fg_active = beautiful.fg_alt,
								{
									widget = wibox.container.place,
									halign = "center",
									valign = "center",
									{
										id = "bottombar-discover-icon",
										widget = widgets.icon,
										size = dpi(18),
										icon = icons.search
									}
								}
							},
							{
								widget = wibox.container.margin,
								forced_width = dpi(60),
								margins = {
									top = dpi(6), bottom = dpi(6),
									left = dpi(10), right = dpi(6)
								},
								{
									widget = wibox.container.place,
									halign = "center",
									{
										id = "bottombar-toggle-switch",
										widget = widgets.switch,
										trough_color = beautiful.fg_alt,
										slider_color = beautiful.bg_alt,
										slider_margins = dpi(2),
										trough_shape = shape.rbar(),
										slider_shape = shape.rbar()
									}
								}
							}
						}
					}
				}
			}
		}
	}

	local wp = ret._private
	local devices_layout = ret:get_children_by_id("devices-layout")[1]
	local bottombar_toggle_switch = ret:get_children_by_id("bottombar-toggle-switch")[1]
	local bottombar_discover_button = ret:get_children_by_id("bottombar-discover-button")[1]
	local bottombar_discover_icon = ret:get_children_by_id("bottombar-discover-icon")[1]
	local bottombar_close_button = ret:get_children_by_id("bottombar-close-button")[1]
	local bottombar_close_icon = ret:get_children_by_id("bottombar-close-icon")[1]

	wp.on_bottombar_discover_button_fg = function(_, fg)
		bottombar_discover_icon:set_color(fg)
	end

	wp.on_bottombar_close_button_fg = function(_, fg)
		bottombar_close_icon:set_color(fg)
	end

	wp.on_device_added = function(_, path, device)
		local device_widget = create_device_widget(path, device)

		if #devices_layout.children == 1
			and not devices_layout.children[1]._private.device_path then
			devices_layout:reset()
		else
			for _, old_device_widget in ipairs(devices_layout.children) do
				if old_device_widget._private.device_path == path then
					devices_layout:remove_widgets(old_device_widget)
					devices_layout:set_scroll_factor(0)
				end
			end
		end

		if device:get_connected() then
			devices_layout:insert(1, device_widget)
		else
			devices_layout:add(device_widget)
		end

	end

	wp.on_device_removed = function(_, path, device)
		for _, device_widget in ipairs(devices_layout.children) do
			if device_widget._private.device_path == path then
				device:disconnect_signal("property::connected", device_widget._private.on_connected)
				device:disconnect_signal("property::percentage", device_widget._private.on_percentage)
				devices_layout:remove_widgets(device_widget)
				devices_layout:set_scroll_factor(0)
			end
		end

		if #devices_layout.children == 0 then
			devices_layout:add({
				widget = wibox.container.place,
				forced_height = dpi(400),
				halign = "center",
				valign = "center",
				{
					widget = widgets.icon,
					size = dpi(25),
					color = beautiful.fg_alt,
					icon = icons.loader
				}
			})
		end
	end

	wp.on_discovering = function(_, discovering)
		bottombar_discover_button:set_fg_normal(discovering and beautiful.fg_alt or beautiful.fg)
		bottombar_discover_button:set_fg_hover(discovering and beautiful.fg_alt or beautiful.fg)
		bottombar_discover_button:set_fg_active(discovering and beautiful.fg or beautiful.fg_alt)
	end

	wp.on_powered = function(_, powered)
		wp.on_discovering(nil, bt_adapter:get_discovering())
		bottombar_toggle_switch:set_checked(powered)

		if powered then
			devices_layout:reset()
			devices_layout:add({
				widget = wibox.container.place,
				forced_height = dpi(400),
				halign = "center",
				valign = "center",
				{
					widget = widgets.icon,
					size = dpi(25),
					color = beautiful.fg_alt,
					icon = icons.loader
				}
			})

			for path, device in pairs(bt_adapter:get_devices()) do
				wp.on_device_added(nil, path, device)
			end

			bt_adapter:start_discovery()
		else
			devices_layout:reset()
			devices_layout:add({
				widget = widgets.label,
				forced_height = dpi(400),
				fg = beautiful.fg_alt,
				align = "center",
				font_size = 17,
				label = "Bluetooth disabled"
			})
		end
	end

	bt_adapter:connect_signal("device-added", wp.on_device_added)
	bt_adapter:connect_signal("device-removed", wp.on_device_removed)
	bt_adapter:connect_signal("property::discovering", wp.on_discovering)
	bt_adapter:connect_signal("property::powered", wp.on_powered)

	bottombar_close_button:connect_signal("property::fg", wp.on_bottombar_close_button_fg)
	bottombar_discover_button:connect_signal("property::fg", wp.on_bottombar_discover_button_fg)

	bottombar_toggle_switch:buttons {
		awful.button({}, 1, nil, function()
			bt_adapter:set_powered(not bt_adapter:get_powered())
		end)
	}

	bottombar_discover_button:buttons {
		awful.button({}, 1, nil, function()
			if bt_adapter:get_powered() then
				if bt_adapter:get_discovering() then
					bt_adapter:stop_discovery()
				else
					bt_adapter:start_discovery()
				end
			end
		end)
	}

	wp.on_powered(bt_adapter, bt_adapter:get_powered())

	return ret
end

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi
local Network = require("service.network")

local wifi_page = {}

local function create_ap_widget(self, ap)
	local nm_client = Network.get_default()
	local wireless = nm_client.wireless
	local is_active = ap:get_path() == wireless:get_active_access_point_path()

	local ret = wibox.widget {
		widget = widgets.button,
		forced_height = dpi(55),
		shape = shape.rrect(dpi(13)),
		bg_hover = beautiful.bg_urg,
		bg_active = beautiful.bg_alt,
		fg_active = beautiful.fg,
		{
			widget = wibox.container.margin,
			margins = { left = dpi(15), right = dpi(15) },
			{
				layout = wibox.layout.align.horizontal,
				{
					widget = wibox.container.constraint,
					width = dpi(250),
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
					id = "strength-label",
					widget = widgets.label,
					align = "center",
					font_size = 12
				}
			}
		}
	}

	local wp = ret._private
	local name_label = ret:get_children_by_id("name-label")[1]
	local description_label = ret:get_children_by_id("description-label")[1]
	local strength_label = ret:get_children_by_id("strength-label")[1]

	wp.is_active = is_active

	ret:buttons {
		awful.button({}, 1, nil, function()
			self:open_ap_menu(ap)
		end)
	}

	name_label:set_label(ap:get_ssid())
	description_label:set_label(is_active and "Connected" or ap:get_security())

	local ap_strength = ap:get_strength()
	strength_label:set_label(
		ap_strength > 70 and "▂▄▆█"
		or ap_strength > 45 and "▂▄▆"
		or ap_strength > 20 and "▂▄"
		or "▂"
	)

	return ret
end

function wifi_page:open_ap_menu(ap)
	local nm_client = Network.get_default()
	local wireless = nm_client.wireless
	local wp = self._private
	local aps_layout = self:get_children_by_id("access-points-layout")[1]
	local close_button = wp.ap_menu:get_children_by_id("close-button")[1]
	local title_label = wp.ap_menu:get_children_by_id("title-label")[1]
	local password_widget = wp.ap_menu:get_children_by_id("password-widget")[1]
	local password_input = wp.ap_menu:get_children_by_id("password-input")[1]
	local connect_button = wp.ap_menu:get_children_by_id("connect-button")[1]

	close_button:buttons {
		awful.button({}, 1, nil, function()
			self:close_ap_menu()
		end)
	}

	title_label:set_label(ap:get_ssid())

	if ap:get_path() ~= wireless:get_active_access_point_path() then
		local obscure_icon = wp.ap_menu:get_children_by_id("obscure-icon")[1]
		local auto_connect_check = wp.ap_menu:get_children_by_id("auto-connect-check")[1]

		obscure_icon:buttons {
			awful.button({}, 1, function()
				password_input:set_obscure(not password_input:get_obscure())
				obscure_icon:set_icon(
					password_input:get_obscure() and icons.eye_off or icons.eye
				)
			end)
		}

		obscure_icon:set_icon(
			password_input:get_obscure() and icons.eye_off or icons.eye
		)

		auto_connect_check:buttons {
			awful.button({}, 1, function()
				auto_connect_check:set_checked(not auto_connect_check:get_checked())
			end)
		}

		connect_button:buttons {
			awful.button({}, 1, nil, function()
				nm_client:connect_access_point(
					wireless,
					ap,
					password_input:get_input(),
					auto_connect_check:get_checked()
				)
				self:close_ap_menu()
			end)
		}

		connect_button:get_widget():set_label("Connect")

		wp.on_password_input_executed = function(_, input)
			nm_client:connect_access_point(
				wireless,
				ap,
				input,
				auto_connect_check:get_checked()
			)
		end

		password_input:connect_signal("executed", wp.on_password_input_executed)

		password_input:set_obscure(true)
		password_input:set_input("")
		password_input:set_cursor_index(1)
		password_widget:set_visible(true)
		password_input:focus()
	else
		connect_button:get_widget():set_label("Disconnect")
		connect_button:buttons {
			awful.button({}, 1, nil, function()
				nm_client:disconnect_active_access_point(wireless)
				self:close_ap_menu()
			end)
		}

		password_widget:set_visible(false)
	end

	aps_layout:reset()
	aps_layout:add(wp.ap_menu)
end

function wifi_page:close_ap_menu()
	local nm_client = Network.get_default()
	local wp = self._private
	local aps_layout = self:get_children_by_id("access-points-layout")[1]
	local password_input = wp.ap_menu:get_children_by_id("password-input")[1]

	if nm_client:get_wireless_enabled() then
		password_input:unfocus()

		if wp.on_password_input_executed then
			password_input:disconnect_signal("executed", wp.on_password_input_executed)
			wp.on_password_input_executed = nil
		end

		aps_layout:reset()
		for _, ap_widget in ipairs(wp.ap_widgets) do
			if ap_widget._private.is_active then
				aps_layout:insert(1, ap_widget)
			else
				aps_layout:add(ap_widget)
			end
		end
	end
end

function wifi_page:refresh()
	local nm_client = Network.get_default()
	local wireless = nm_client.wireless
	local wp = self._private
	wp.on_ap_list(nil, nil, wireless:get_access_points())
	wireless:request_scan()
end

return function()
	local nm_client = Network.get_default()
	local wireless = nm_client.wireless

	local ret = wibox.widget {
		widget = wibox.container.background,
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(8),
			{
				id = "access-points-layout",
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
								id = "bottombar-refresh-button",
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
										id = "bottombar-refresh-icon",
										widget = widgets.icon,
										size = dpi(18),
										icon = icons.refresh
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

	gtable.crush(ret, wifi_page, true)
	local wp = ret._private

	wp.ap_widgets = {}

	wp.ap_menu = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		forced_height = dpi(400),
		{
			widget = wibox.container.margin,
			margins = dpi(10),
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(10),
				{
					id = "close-button",
					widget = widgets.button,
					forced_width = dpi(30),
					forced_height = dpi(30),
					shape = shape.rrect(dpi(8)),
					bg_hover = beautiful.bg_urg,
					bg_active = beautiful.bg_alt,
					fg_active = beautiful.fg_alt,
					{
						widget = wibox.container.place,
						halign = "center",
						valign = "center",
						{
							id = "close-icon",
							widget = widgets.icon,
							size = dpi(18),
							icon = icons.chevron_left
						}
					}
				},
				{
					id = "title-label",
					widget = widgets.label,
					font_weight = "bold",
					font_size = 13
				}
			}
		},
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(10),
			{
				id = "password-widget",
				widget = wibox.container.background,
				bg = beautiful.bg_alt,
				shape = shape.rrect(dpi(13)),
				{
					widget = wibox.container.margin,
					margins = dpi(15),
					{
						layout = wibox.layout.fixed.vertical,
						spacing = dpi(10),
						{
							widget = wibox.container.margin,
							margins = { left = dpi(10), right = dpi(10) },
							{
								layout = wibox.layout.align.horizontal,
								{
									widget = wibox.container.constraint,
									forced_width = dpi(310),
									strategy = "max",
									height = dpi(25),
									{
										id = "password-input",
										widget = widgets.input,
										placeholder = "Password",
										obscure_char = "●",
										cursor_bg = beautiful.fg,
										cursor_fg = beautiful.bg,
										placeholder_fg = beautiful.fg_alt,
										obscure = true,
										font_size = 12
									}
								},
								nil,
								{
									widget = wibox.container.place,
									forced_width = dpi(20),
									halign = "center",
									valign = "center",
									{
										id = "obscure-icon",
										widget = widgets.icon,
										size = dpi(18)
									}
								}
							}
						},
						{
							widget = wibox.widget.separator,
							forced_width = 1,
							forced_height = beautiful.separator_thickness,
							orientation = "horizontal"
						},
						{
							widget = wibox.container.margin,
							margins = { left = dpi(10), right = dpi(10) },
							{
								layout = wibox.layout.align.horizontal,
								{
									widget = widgets.label,
									align = "center",
									font_size = 12,
									label = "Auto connect"
								},
								nil,
								{
									id = "auto-connect-check",
									widget = widgets.check,
									forced_height = dpi(20),
									check_margins = dpi(6),
									check_shape = shape.rbar(),
									trough_shape = shape.rbar(),
									checked = true
								}
							}
						}
					}
				}
			},
			{
				id = "connect-button",
				widget = widgets.button,
				forced_height = dpi(45),
				shape = shape.rrect(dpi(13)),
				bg_normal = beautiful.bg_alt,
				bg_hover = beautiful.bg_urg,
				bg_active = beautiful.bg_alt,
				fg_active = beautiful.fg_alt,
				{
					widget = widgets.label,
					align = "center",
					font_weight = "bold",
					font_size = 12
				}
			}
		}
	}

	local aps_layout = ret:get_children_by_id("access-points-layout")[1]
	local bottombar_toggle_switch = ret:get_children_by_id("bottombar-toggle-switch")[1]
	local bottombar_refresh_button = ret:get_children_by_id("bottombar-refresh-button")[1]
	local bottombar_refresh_icon = ret:get_children_by_id("bottombar-refresh-icon")[1]
	local bottombar_close_button = ret:get_children_by_id("bottombar-close-button")[1]
	local bottombar_close_icon = ret:get_children_by_id("bottombar-close-icon")[1]
	local password_input = wp.ap_menu:get_children_by_id("password-input")[1]
	local ap_menu_close_button = wp.ap_menu:get_children_by_id("close-button")[1]
	local ap_menu_close_icon = wp.ap_menu:get_children_by_id("close-icon")[1]

	wp.on_bottombar_refresh_button_fg = function(_, fg)
		bottombar_refresh_icon:set_color(fg)
	end

	wp.on_bottombar_close_button_fg = function(_, fg)
		bottombar_close_icon:set_color(fg)
	end

	wp.on_ap_menu_close_button_fg = function(_, fg)
		ap_menu_close_icon:set_color(fg)
	end

	wp.on_wireless_enabled = function(_, enabled)
		bottombar_toggle_switch:set_checked(enabled)

		if enabled then
			aps_layout:reset()
			aps_layout:add({
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
		else
			wp.ap_widgets = {}
			aps_layout:reset()
			aps_layout:add({
				widget = widgets.label,
				forced_height = dpi(400),
				fg = beautiful.fg_alt,
				align = "center",
				font_size = 17,
				label = "Wifi disabled"
			})

			password_input:unfocus()
		end
	end

	wp.on_ap_list = function(_, _, aps)
		wp.ap_widgets = {}

		for _, ap in pairs(aps) do
			if ap:get_ssid() ~= nil then
				local ap_widget = create_ap_widget(ret, ap)
				table.insert(wp.ap_widgets, ap_widget)
			end
		end

		if aps_layout.children[1] ~= wp.ap_menu and #wp.ap_widgets ~= 0 then
			aps_layout:reset()
			for _, ap_widget in ipairs(wp.ap_widgets) do
				if ap_widget._private.is_active then
					aps_layout:insert(1, ap_widget)
				else
					aps_layout:add(ap_widget)
				end
			end
		end
	end

	wp.on_wireless_state = function(_, state)
		if state == Network.DeviceState.ACTIVATED
			or state == Network.DeviceState.DISCONNECTED then
			wp.on_ap_list(nil, nil, wireless:get_access_points())
		end
	end

	wp.on_password_input_unfocused = function()
		ret:close_ap_menu()
	end

	bottombar_close_button:connect_signal("property::fg", wp.on_bottombar_close_button_fg)
	bottombar_refresh_button:connect_signal("property::fg", wp.on_bottombar_refresh_button_fg)
	ap_menu_close_button:connect_signal("property::fg", wp.on_ap_menu_close_button_fg)
	password_input:connect_signal("unfocused", wp.on_password_input_unfocused)

	wireless:connect_signal("property::access-points", wp.on_ap_list)
	wireless:connect_signal("property::state", wp.on_wireless_state)
	nm_client:connect_signal("property::wireless-enabled", wp.on_wireless_enabled)

	bottombar_toggle_switch:buttons {
		awful.button({}, 1, nil, function()
			nm_client:set_wireless_enabled(not nm_client:get_wireless_enabled())
		end)
	}

	bottombar_refresh_button:buttons {
		awful.button({}, 1, nil, function()
			if nm_client:get_wireless_enabled() then
				ret:refresh()
			end
		end)
	}

	wp.on_wireless_enabled(nm_client, nm_client:get_wireless_enabled())
	wp.on_wireless_state(wireless, wireless:get_state())

	return ret
end

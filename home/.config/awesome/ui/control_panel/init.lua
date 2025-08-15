local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local shape = require("lib.shape")
local gtable = require("gears.table")
local dpi = beautiful.xresources.apply_dpi
local capi = { screen = screen }
local Notification_list = require("ui.control_panel.notification_list")
local Audio_sliders = require("ui.control_panel.audio_sliders")
local Wifi_button = require("ui.control_panel.wifi_applet.button")
local Wifi_page = require("ui.control_panel.wifi_applet.page")
local Bluetooth_button = require("ui.control_panel.bluetooth_applet.button")
local Bluetooth_page = require("ui.control_panel.bluetooth_applet.page")
local Audio = require("service.audio")

local control_panel = {}

function control_panel:setup_wifi_page()
	local wp = self._private
	local main_layout = self.widget:get_children_by_id("main-layout")[1]
	main_layout:reset()
	main_layout:add(wp.wifi_page)
end

function control_panel:setup_bluetooth_page()
	local wp = self._private
	local main_layout = self.widget:get_children_by_id("main-layout")[1]
	main_layout:reset()
	main_layout:add(wp.bluetooth_page)
end

function control_panel:setup_main_page()
	local wp = self._private
	local main_layout = self.widget:get_children_by_id("main-layout")[1]
	main_layout:reset()
	main_layout:add(
		wp.notification_list,
		wibox.widget {
			widget = wibox.container.background,
			forced_width = 1,
			forced_height = beautiful.separator_thickness,
			{
				widget = wibox.widget.separator,
				orientation = "horizontal"
			}
		},
		wp.audio_sliders,
		wibox.widget {
			layout = wibox.layout.flex.horizontal,
			spacing = dpi(4),
			wp.wifi_button,
			wp.bluetooth_button
		}
	)
end

function control_panel:show()
	if self.visible then return end
	Audio.get_default():get_default_sink_data()
	Audio.get_default():get_default_source_data()
	self:setup_main_page()
	self.visible = true
	self:emit_signal("property::visible", self.visible)
end

function control_panel:hide()
	if not self.visible then return end
	local wp = self._private
	wp.wifi_page:close_ap_menu()
	self.visible = false
	self:emit_signal("property::visible", self.visible)
end

function control_panel:toggle()
	if not self.visible then
		self:show()
	else
		self:hide()
	end
end

local function new()
	local ret = awful.popup {
		visible = false,
		ontop = true,
		type = "dock",
		screen = capi.screen.primary,
		bg = "#00000000",
		placement = function(d)
			awful.placement.bottom_right(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.bg,
			border_width = beautiful.border_width,
			border_color = beautiful.border_color_normal,
			shape = shape.rrect(dpi(23)),
			{
				widget = wibox.container.margin,
				margins = dpi(10),
				{
					id = "main-layout",
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(4)
				}
			}
		}
	}

	gtable.crush(ret, control_panel, true)
	local wp = ret._private

	wp.notification_list = Notification_list()
	wp.audio_sliders = Audio_sliders()
	wp.wifi_button = Wifi_button()
	wp.wifi_page = Wifi_page()
	wp.bluetooth_button = Bluetooth_button()
	wp.bluetooth_page = Bluetooth_page()

	wp.wifi_button:get_children_by_id("reveal-button")[1]:buttons {
		awful.button({}, 1, nil, function()
			ret:setup_wifi_page()
		end)
	}

	wp.wifi_page:get_children_by_id("bottombar-close-button")[1]:buttons {
		awful.button({}, 1, nil, function()
			ret:setup_main_page()
		end)
	}

	wp.bluetooth_button:get_children_by_id("reveal-button")[1]:buttons {
		awful.button({}, 1, nil, function()
			ret:setup_bluetooth_page()
		end)
	}

	wp.bluetooth_page:get_children_by_id("bottombar-close-button")[1]:buttons {
		awful.button({}, 1, nil, function()
			ret:setup_main_page()
		end)
	}

	return ret
end

local instance = nil
local function get_default()
	if not instance then
		instance = new()
	end
	return instance
end

return { get_default = get_default }

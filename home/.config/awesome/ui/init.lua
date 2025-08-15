local awful = require("awful")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local user = require("user")
local capi = { screen = screen, client = client }
local Bar = require("ui.bar")
local Notifications = require("ui.notifications")
local Wallpaper = require("ui.wallpaper")
local Titlebar = require("ui.titlebar")
local Menu = require("ui.menu")
local Launcher = require("ui.launcher")
local Powermenu = require("ui.powermenu")
local Control_panel = require("ui.control_panel")
local Day_info_panel = require("ui.day_info_panel")
local Media_panel = require("ui.media_panel")

local menu = Menu.get_default()
local launcher = Launcher.get_default()
local powermenu = Powermenu.get_default()
local control_panel = Control_panel.get_default()
local day_info_panel = Day_info_panel.get_default()
local media_panel = Media_panel.get_default()

local function on_primary_bar_visible()
	if control_panel.visible == true then
		gtimer.delayed_call(function()
			awful.placement.bottom_right(control_panel, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end)
	end

	if media_panel.visible == true then
		gtimer.delayed_call(function()
			awful.placement.bottom_right(media_panel, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end)
	end

	if day_info_panel.visible == true then
		gtimer.delayed_call(function()
			awful.placement.bottom_right(day_info_panel, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end)
	end

	if launcher.visible == true then
		gtimer.delayed_call(function()
			awful.placement.bottom_left(launcher, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end)
	end
end

awful.screen.connect_for_each_screen(function(s)
	if s == capi.screen.primary then
		s.bar = Bar.Primary(s)
		s.bar:connect_signal("property::visible", on_primary_bar_visible)
	else
		s.bar = Bar.Secondary(s)
	end

	s.notifications = Notifications(s)

	s.wallpaper = Wallpaper(s)

	if user.wallpaper then
		s.wallpaper:set_image(user.wallpaper)
	end
end)

capi.client.connect_signal("request::titlebars", function(c)
	Titlebar(c)
end)

powermenu:connect_signal("property::visible", function(_, visible)
	if visible then
		launcher:hide()
		control_panel:hide()
		day_info_panel:hide()
		media_panel:hide()
		menu:hide()
	end
end)

launcher:connect_signal("property::visible", function(_, visible)
	if visible then
		powermenu:hide()
		menu:hide()
	end
end)

control_panel:connect_signal("property::visible", function(_, visible)
	if visible then
		powermenu:hide()
		day_info_panel:hide()
		media_panel:hide()
		menu:hide()
	end
end)

day_info_panel:connect_signal("property::visible", function(_, visible)
	if visible then
		powermenu:hide()
		control_panel:hide()
		media_panel:hide()
		menu:hide()
	end
end)

media_panel:connect_signal("property::visible", function(_, visible)
	if visible then
		powermenu:hide()
		control_panel:hide()
		day_info_panel:hide()
		menu:hide()
	end
end)

local function click_hideaway()
	menu:hide()
	launcher:hide()
	powermenu:hide()
	control_panel:hide()
	day_info_panel:hide()
	media_panel:hide()
end

capi.client.connect_signal("request::manage", function(c)
	c:connect_signal("button::press", click_hideaway)
end)

capi.client.connect_signal("request::unmanage", function(c)
	c:disconnect_signal("button::press", click_hideaway)
end)

awful.mouse.append_global_mousebinding(
	awful.button({}, 1, click_hideaway)
)

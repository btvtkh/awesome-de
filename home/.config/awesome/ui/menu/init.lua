local Gio = require("lgi").require("Gio")
local awful = require("awful")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local gfs = require("gears.filesystem")
local widgets = require("widgets")
local user = require("user")
local dump_table = require("lib.file").dump
local capi = { awesome = awesome, screen = screen, client = client }
local Screenshot = require("service.screenshot")
local Powermenu = require("ui.powermenu")

local menu = {}

local function create_desktop_menu()
	return widgets.menu {
		theme = {
			item_font = beautiful.font_h0
		},
		items = {
			{
				label = "Awesome",
				items = {
					{
						label = "Open config",
						exec = function()
							local app = Gio.AppInfo.get_default_for_type("inode/directory")
							if app then
								awful.spawn(string.format(
									"%s %s",
									app:get_executable(),
									gfs.get_configuration_dir()
								))
							end
						end
					},
					{
						label = "Set wallpaper",
						exec = function()
							awful.spawn.easy_async(
								"zenity --file-selection --file-filter='Image files | *.png *.jpg *.jpeg'",
								function(stdout)
									stdout = string.gsub(stdout, "\n", "")
									if stdout ~= nil and stdout ~= "" then
										for s in capi.screen do
											s.wallpaper:set_image(stdout)
										end
										user.wallpaper = stdout
										dump_table(user, gfs.get_configuration_dir() .. "/user.lua")
									end
								end
							)
						end
					},
					{
						label = "Restart",
						exec = function()
							capi.awesome.restart()
						end
					},
					{
						label = "Powermenu",
						exec = function()
							Powermenu.get_default():toggle()
						end
					}
				}
			},
			{
				label = "Take screenshot",
				items = {
					{
						label = "Full",
						exec = function()
							Screenshot.get_default():take_full()
						end
					},
					{
						label = "Full 5s delay",
						exec = function()
							Screenshot.get_default():take_delay(5)
						end
					},
					{
						label = "Select area",
						exec = function()
							Screenshot.get_default():take_select()
						end
					}
				}
			},
			{
				label = "Open terminal",
				exec = function()
					local app = Gio.AppInfo.get_default_for_uri_scheme('terminal')
					if app then awful.spawn(app:get_executable()) end
				end
			},
			{
				label = "Browse files",
				exec = function()
					local app = Gio.AppInfo.get_default_for_type("inode/directory")
					if app then awful.spawn(app:get_executable()) end
				end
			},
			{
				label = "Browse web",
				exec = function()
					local app = Gio.AppInfo.get_default_for_type("text/html")
					if app then awful.spawn(app:get_executable()) end
				end
			}
		}
	}
end

local function create_client_menu(c)
	local move_to_tag_item = {}
	local toggle_on_tag_item = {}

	for _, t in ipairs(c.screen.tags) do
		table.insert(move_to_tag_item, {
			label = string.format("%s: %s", t.index, t.name),
			exec = function()
				c:move_to_tag(t)
			end
		})
		table.insert(toggle_on_tag_item, {
			label = string.format("%s: %s", t.index, t.name),
			exec = function()
				c:toggle_tag(t)
			end
		})
	end

	return widgets.menu {
		theme = {
			item_font = beautiful.font_h0
		},
		items = {
			{
				label = "Move to tag",
				items = move_to_tag_item
			},
			{
				label = "Toggle on tag",
				items = toggle_on_tag_item
			},
			not c.requests_no_titlebar and {
				label = "Toggle titlebar",
				exec = function()
					awful.titlebar.toggle(c, "top")
				end
			},
			{
				label = "Move to center",
				exec = function()
					awful.placement.centered(c, { honor_workarea = true })
				end
			},
			{
				label = c.ontop and "Unset ontop" or "Set ontop",
				exec = function()
					c.ontop = not c.ontop
				end
			},
			{
				label = c.fullscreen and "Unset fullscreen" or "Set fullscreen",
				exec = function()
					c.fullscreen = not c.fullscreen
					c:activate()
				end
			},
			{
				label = c.maximized and "Unmaximize" or "Maximize",
				exec = function()
					c.maximized = not c.maximized
					c:activate()
				end
			},
			{
				label = c.minimized and "Unminimize" or "Minimize",
				exec = function()
					if c.minimized then
						c.minimized = false
						c:activate()
					else
						c.minimized = true
					end
				end
			},
			{
				label = "Close",
				exec = function()
					c:kill()
				end
			}
		}
	}
end

function menu:hide()
	if self.menu_widget and self.menu_widget.visible then
		self.menu_widget:hide()
		self.menu_widget = nil
	end
end

function menu:show_desktop_menu()
	if self.menu_widget then
		if not self.menu_widget.visible then
			self.menu_widget = create_desktop_menu()
			self.menu_widget:show()
		end
	else
		self.menu_widget = create_desktop_menu()
		self.menu_widget:show()
	end
end

function menu:toggle_desktop_menu()
	if self.menu_widget then
		if self.menu_widget.visible then
			self.menu_widget:hide()
			self.menu_widget = nil
		else
			self.menu_widget = create_desktop_menu()
			self.menu_widget:show()
		end
	else
		self.menu_widget = create_desktop_menu()
		self.menu_widget:show()
	end
end

function menu:show_client_menu(c)
	c = c or capi.client.focus
	if not c then return end
	if self.menu_widget then
		if not self.menu_widget.visible then
			self.menu_widget = create_client_menu(c)
			self.menu_widget:show()
		end
	else
		self.menu_widget = create_client_menu(c)
		self.menu_widget:show()
	end
end

function menu:toggle_client_menu(c)
	c = c or capi.client.focus
	if not c then return end
	if self.menu_widget then
		if self.menu_widget.visible then
			self.menu_widget:hide()
			self.menu_widget = nil
		else
			self.menu_widget = create_client_menu(c)
			self.menu_widget:show()
		end
	else
		self.menu_widget = create_client_menu(c)
		self.menu_widget:show()
	end
end

local function new()
	local ret = {}
	gtable.crush(ret, menu, true)
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

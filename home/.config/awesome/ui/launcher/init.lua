local utf8 = require("lua-utf8")
local Gio = require("lgi").require("Gio")
local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local gfs = require("gears.filesystem")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local user = require("user")
local dpi = beautiful.xresources.apply_dpi
local lua_escape = require("lib.string").lua_escape
local dump_table = require("lib.file").dump
local capi = { screen = screen }
local Sidebar = require("ui.launcher.sidebar")
local Powermenu = require("ui.powermenu")

local launcher = {}

local function launch_app(app)
	if not app then return end
	local desktop_info = Gio.DesktopAppInfo.new(app:get_id())
	local term_needed = desktop_info:get_string("Terminal") == "true"
	local term = Gio.AppInfo.get_default_for_uri_scheme('terminal')

	awful.spawn(
		term_needed and
			term and string.format("%s -e %s", term:get_executable(), app:get_executable())
		or
			string.match(app:get_executable(), "^env") and
				string.gsub(app:get_commandline(), "%%%a", "")
			or
				app:get_executable()
	)
end

local function filter_apps(apps, query)
	query = lua_escape(query)
	local filtered = {}
	local filtered_any = {}

	for _, app in ipairs(apps) do
		if app:should_show() then
			local name_match = utf8.lower(utf8.sub(app:get_name(), 1, utf8.len(query))) == utf8.lower(query)
			local name_match_any = utf8.match(utf8.lower(app:get_name()), utf8.lower(query))
			local exec_match_any = utf8.match(utf8.lower(app:get_executable()), utf8.lower(query))

			if name_match then
				table.insert(filtered, app)
			elseif name_match_any or exec_match_any then
				table.insert(filtered_any, app)
			end
		end
	end

	table.sort(filtered, function(a, b)
		return utf8.lower(a:get_name()) < utf8.lower(b:get_name())
	end)

	table.sort(filtered_any, function(a, b)
		return utf8.lower(a:get_name()) < utf8.lower(b:get_name())
	end)

	for i = 1, #filtered_any do
		filtered[#filtered + 1] = filtered_any[i]
	end

	return filtered
end

local function App_button(app, index, self)
	local ret = wibox.widget {
		widget = widgets.button,
		bg_hover = beautiful.bg_urg,
		bg_active = beautiful.bg_alt,
		fg_active = beautiful.fg_alt,
		forced_height = dpi(60),
		shape = shape.rrect(dpi(13)),
		{
			widget = wibox.container.margin,
			margins = { left = dpi(15), right = dpi(15) },
			{
				widget = wibox.container.place,
				halign = "left",
				valign = "center",
				{
					layout = wibox.layout.fixed.vertical,
					{
						widget = wibox.container.constraint,
						strategy = "max",
						height = dpi(25),
						{
							widget = widgets.label,
							font_weight = "bold",
							font_size = 13,
							label = app:get_name()
						}
					},
					app:get_description() and {
						widget = wibox.container.constraint,
						strategy = "max",
						height = dpi(25),
						{
							widget = widgets.label,
							font_size = 9,
							alpha = 70,
							label = app:get_description()
						}
					}
				}
			}
		}
	}

	local wp = ret._private
	wp.is_app_button = true

	wp.on_clicked = function()
		if self._private.select_index == index then
			launch_app(app)
			self:hide()
		else
			self._private.prev_select_index = self._private.select_index
			self._private.select_index = index
			self._private.prev_row_index = self._private.row_index
			self._private.row_index = index - self._private.start_index + 1
			self:update_entries()
		end
	end

	ret:buttons {
		awful.button({}, 1, nil, wp.on_clicked)
	}

	return ret
end

function launcher:update_entries()
	local wp = self._private
	local entries_layout = self.widget:get_children_by_id("entries-layout")[1]

	if not wp.prev_row_index and not wp.prev_select_index then
		entries_layout:reset()
		if #wp.filtered > 0 then
			for i, app in ipairs(wp.filtered) do
				if i >= wp.start_index and i <= wp.start_index + wp.rows - 1 then
					entries_layout:add(App_button(app, i, self))
				end
			end
		else
			entries_layout:add({
				widget = widgets.label,
				forced_height = dpi(60) * wp.rows + dpi(3) * (wp.rows - 1),
				align = "center",
				font_size = 17,
				fg = beautiful.fg_alt,
				label = "No match found"
			})
		end
	elseif wp.row_index == wp.rows and wp.row_index == wp.prev_row_index
	and wp.select_index ~= wp.prev_select_index and wp.select_index <= #wp.filtered then
		local app_button = App_button(wp.filtered[wp.select_index], wp.select_index, self)
		entries_layout:remove(1)
		entries_layout:add(app_button)
	elseif wp.row_index == 1 and wp.row_index == wp.prev_row_index
	and wp.select_index ~= wp.prev_select_index and wp.select_index >= 1 then
		local app_button = App_button(wp.filtered[wp.select_index], wp.select_index, self)
		entries_layout:remove(#entries_layout.children)
		entries_layout:insert(1, app_button)
	end

	for i, widget in ipairs(entries_layout.children) do
		if widget._private.is_app_button then
			if i == self._private.row_index then
				widget:set_bg_normal(beautiful.ac)
				widget:set_bg_hover(beautiful.ac)
				widget:set_bg_active(beautiful.fg_alt)
				widget:set_fg_normal(beautiful.bg)
				widget:set_fg_hover(beautiful.bg)
				widget:set_fg_active(beautiful.bg)
			else
				widget:set_bg_normal(nil)
				widget:set_bg_hover(beautiful.bg_urg)
				widget:set_bg_active(beautiful.bg_alt)
				widget:set_fg_normal(beautiful.fg)
				widget:set_fg_hover(beautiful.fg)
				widget:set_fg_active(beautiful.fg_alt)
			end
		end
	end
end

function launcher:forward()
	local wp = self._private
	wp.prev_row_index = wp.row_index
	wp.row_index = math.min(wp.prev_row_index + 1, math.max(0, #wp.filtered), wp.rows)
	wp.prev_select_index = wp.select_index
	wp.select_index = math.min(wp.prev_select_index + 1, math.max(1, #wp.filtered))
	wp.start_index = math.max((wp.select_index - wp.rows) + 1, wp.start_index)
	self:update_entries()
end

function launcher:backward()
	local wp = self._private
	wp.prev_row_index = wp.row_index
	wp.row_index = math.max(wp.prev_row_index - 1, 1)
	wp.prev_select_index = wp.select_index
	wp.select_index = math.max(wp.prev_select_index - 1, 1)
	wp.start_index = math.min(wp.start_index, wp.select_index)
	self:update_entries()
end

function launcher:show()
	if self.visible then return end
	local wp = self._private
	local search_input = self.widget:get_children_by_id("search-input")[1]
	search_input:set_input("")
	search_input:set_cursor_index(1)
	wp.filtered = filter_apps(Gio.AppInfo.get_all(), "")
	wp.prev_select_index, wp.prev_row_index = nil, nil
	wp.start_index, wp.select_index, wp.row_index = 1, 1, 1
	self:update_entries()
	search_input:focus()
	self.visible = true
	self:emit_signal("property::visible", self.visible)
end

function launcher:hide()
	if not self.visible then return end
	local wp = self._private
	local entries_layout = self.widget:get_children_by_id("entries-layout")[1]
	local search_input = self.widget:get_children_by_id("search-input")[1]
	wp.filtered = {}
	wp.prev_select_index, wp.prev_row_index = nil, nil
	wp.select_index, wp.select_index, wp.row_index = 1, 1, 1
	search_input:unfocus()
	entries_layout:reset()
	self.visible = false
	self:emit_signal("property::visible", self.visible)
end

function launcher:toggle()
	if not self.visible then
		self:show()
	else
		self:hide()
	end
end

local function new()
	local ret = awful.popup {
		ontop = true,
		visible = false,
		type = "dock",
		screen = capi.screen.primary,
		bg = "#00000000",
		placement = function(d)
			awful.placement.bottom_left(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.bg,
			border_width = beautiful.border_width,
			border_color = beautiful.border_color_normal,
			shape = shape.rrect(dpi(21)),
			{
				widget = wibox.container.margin,
				margins = dpi(8),
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(4),
					fill_space = true,
					{
						id = "sidebar-widget",
						widget = Sidebar(),
					},
					{
						layout = wibox.layout.fixed.vertical,
						spacing = dpi(3),
						{
							layout = wibox.layout.fixed.vertical,
							{
								widget = wibox.container.margin,
								forced_width = 1,
								forced_height = dpi(50),
								margins = { left = dpi(10), right = dpi(10) },
								{
									widget = wibox.container.place,
									halign = "left",
									valign = "center",
									{
										widget = wibox.container.constraint,
										strategy = "max",
										height = dpi(25),
										{
											id = "search-input",
											widget = widgets.input,
											placeholder = "Search...",
											font_size = 12
										}
									}
								}
							},
							{
								widget = wibox.widget.separator,
								forced_width = 1,
								forced_height = beautiful.separator_thickness,
								orientation = "horizontal"
							}
						},
						{
							id = "entries-layout",
							layout = wibox.layout.fixed.vertical,
							forced_width = dpi(300),
							spacing = dpi(3)
						}
					}
				}
			}
		}
	}

	gtable.crush(ret, launcher, true)
	local wp = ret._private
	local entries_layout = ret.widget:get_children_by_id("entries-layout")[1]
	local search_input = ret.widget:get_children_by_id("search-input")[1]
	local sidebar_widget = ret.widget:get_children_by_id("sidebar-widget")[1]
	local powermenu_button = sidebar_widget:get_children_by_id("powermenu-button")[1]
	local wallpaper_button = sidebar_widget:get_children_by_id("wallpaper-button")[1]
	local home_button = sidebar_widget:get_children_by_id("home-button")[1]

	wp.rows = 6

	wp.on_unfocused = function()
		ret:hide()
	end

	wp.on_input_changed = function(_, input)
		wp.filtered = filter_apps(Gio.AppInfo.get_all(), input)
		wp.prev_select_index, wp.prev_row_index = nil, nil
		wp.start_index, wp.select_index, wp.row_index = 1, 1, 1
		ret:update_entries()
	end

	wp.on_executed = function()
		local app = wp.filtered[wp.select_index]
		if app then launch_app(app) end
	end

	wp.on_key_pressed = function(_, _, key)
		if key == "Down" then
			ret:forward()
		elseif key == "Up" then
			ret:backward()
		end
	end

	search_input:connect_signal("unfocused", wp.on_unfocused)
	search_input:connect_signal("input-changed", wp.on_input_changed)
	search_input:connect_signal("executed", wp.on_executed)
	search_input:connect_signal("key-pressed", wp.on_key_pressed)

	entries_layout:buttons {
		awful.button({}, 4, function()
			ret:backward()
		end),
		awful.button({}, 5, function()
			ret:forward()
		end)
	}

	entries_layout:set_forced_height(dpi(60) * wp.rows + dpi(3) * (wp.rows - 1))

	powermenu_button:buttons {
		awful.button({}, 1, nil, function()
			Powermenu.get_default():show()
		end)
	}

	wallpaper_button:buttons {
		awful.button({}, 1, nil, function()
			ret:hide()
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
		end)
	}

	home_button:buttons {
		awful.button({}, 1, nil, function()
			local app = Gio.AppInfo.get_default_for_type("inode/directory")
			ret:hide()
			if app then
				awful.spawn(string.format(
					"%s %s",
					app:get_executable(),
					os.getenv("HOME")
				))
			end
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

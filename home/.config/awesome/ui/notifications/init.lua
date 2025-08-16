local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local ncr = naughty.notification_closed_reason
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi

local function update_positions(self)
	if #self.popups > 0 then
		for i = 1, #self.popups do
			local screen = self._private.screen
			self.popups[i]:geometry({
				x = screen.workarea.x + screen.workarea.width
					- beautiful.notification_margins - self.popups[i].width,
				y = i > 1 and self.popups[i - 1].y
					+ self.popups[i - 1].height + beautiful.notification_spacing
					or screen.workarea.y + beautiful.notification_margins
			})
		end
	end
end

local function create_actions_widget(n)
	if #n.actions == 0 then return end

	local actions_widget = wibox.widget {
		widget = wibox.container.margin,
		margins = { top = dpi(5) },
		{
			id = "buttons-layout",
			layout = wibox.layout.flex.horizontal,
			spacing = dpi(3)
		}
	}

	local main_layout = actions_widget:get_children_by_id("buttons-layout")[1]
	for _, action in ipairs(n.actions) do
		main_layout:add({
			widget = widgets.button,
			buttons = {
				awful.button({}, 1, nil, function()
					action:invoke()
				end)
			},
			forced_height = dpi(35),
			bg_normal = beautiful.bg_alt,
			bg_hover = beautiful.bg_urg,
			bg_active = beautiful.bg_alt,
			fg_normal = beautiful.fg,
			fg_hover = beautiful.fg,
			fg_active = beautiful.fg_alt,
			shape = shape.rrect(dpi(10)),
			{
				widget = wibox.container.margin,
				margins = {
					left = dpi(15), right = dpi(15),
					top = dpi(8), bottom = dpi(8)
				},
				{
					widget = widgets.label,
					halign = "center",
					valign = "center",
					font_weight = "bold",
					font_size = 11,
					label = action.name
				}
			}
		})
	end

	return actions_widget
end

local function create_notification_popup(self, n)
	local ret = awful.popup {
		type = "notification",
		screen = n.screen,
		visible = false,
		ontop = true,
		minimum_width = dpi(380),
		maximum_width = dpi(450),
		minimum_height = dpi(100),
		maximum_height = dpi(280),
		bg = "#00000000",
		placement = function() return { 0, 0 } end,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.bg,
			fg = beautiful.fg,
			border_color = beautiful.border_color_normal,
			border_width = beautiful.border_width,
			shape = shape.rrect(dpi(18)),
			{
				widget = wibox.container.margin,
				margins = dpi(8),
				{
					layout = wibox.layout.fixed.vertical,
					{
						widget = wibox.container.margin,
						margins = dpi(5),
						{
							layout = wibox.layout.fixed.vertical,
							spacing = dpi(5),
							{
								layout = wibox.layout.align.horizontal,
								{
									widget = wibox.container.constraint,
									strategy = "max",
									width = dpi(150),
									height = dpi(25),
									{
										widget = widgets.label,
										fg = n.urgency == "critical" and beautiful.red or beautiful.fg,
										font_weight = "bold",
										font_size = 11,
										label = n.app_name
									}
								},
								nil,
								{
									layout = wibox.layout.fixed.horizontal,
									spacing = dpi(5),
									{
										widget = widgets.label,
										fg = beautiful.fg_alt,
										font_weight = 500,
										font_size = 9,
										label = os.date("%H:%M")
									},
									{
										id = "close-button",
										widget = widgets.button,
										forced_width = dpi(25),
										forced_height = dpi(25),
										bg_hover = beautiful.red,
										bg_active = beautiful.fg_alt,
										fg_normal = beautiful.red,
										fg_hover = beautiful.bg,
										fg_active = beautiful.bg,
										shape = shape.rrect(dpi(5)),
										{
											widget = wibox.container.place,
											halign = "center",
											valign = "center",
											{
												id = "close-icon",
												widget = widgets.icon,
												size = dpi(15),
												icon = icons.cross
											}
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
								id = "body-layout",
								layout = wibox.layout.fixed.horizontal,
								fill_space = true,
								spacing = dpi(10),
								{
									widget = wibox.container.constraint,
									strategy = "max",
									width = dpi(70),
									height = dpi(70),
									{
										widget = wibox.widget.imagebox,
										resize = true,
										halign = "center",
										valign = "top",
										clip_shape = shape.rrect(dpi(5)),
										image = n.icon
									}
								},
								{
									layout = wibox.layout.fixed.vertical,
									spacing = dpi(5),
									{
										widget = wibox.container.constraint,
										strategy = "max",
										height = dpi(25),
										{
											widget = widgets.label,
											font_weight = "bold",
											font_size = 13,
											label = n.title,
										}
									},
									{
										widget = wibox.container.constraint,
										strategy = "max",
										height = dpi(70),
										{
											widget = widgets.label,
											font_weight = 500,
											font_size = 10,
											label = n.text or n.massage,
										}
									}
								}
							}
						}
					},
					create_actions_widget(n)
				}
			}
		}
	}

	local wp = ret._private
	local body_layout = ret.widget:get_children_by_id("body-layout")[1]
	local close_button = ret.widget:get_children_by_id("close-button")[1]
	local close_icon = ret.widget:get_children_by_id("close-icon")[1]

	wp.notification = n

	wp.display_timer = gtimer {
		timeout = beautiful.notification_timeout or 5,
		autostart = false,
		single_shot = true,
		call_now = false,
		callback = function()
			ret.visible = false
			for i, p in ipairs(self.popups) do
				if p == ret then
					table.remove(self.popups, i)
				end
			end
			wp.display_timer = nil
			ret = nil
		end
	}

	wp.on_close_button_fg = function(_, fg)
		close_icon:set_color(fg)
	end

	close_button:connect_signal("property::fg", wp.on_close_button_fg)

	body_layout:buttons {
		awful.button({}, 1, nil, function()
			n:destroy(ncr.dismissed_by_user)
		end)
	}

	close_button:buttons {
		awful.button({}, 1, nil, function()
			n:destroy(ncr.silent)
		end)
	}

	close_icon:set_color(close_button:get_fg_normal())

	return ret
end

return function(s)
	if not s then return end
	local ret = {}
	ret._private = {}
	local wp = ret._private

	ret.popups = {}
	wp.screen = s

	wp.on_added = function(n)
		if n.screen == wp.screen then
			local popup = create_notification_popup(ret, n)
			table.insert(ret.popups, 1, popup)
			popup.visible = true
			update_positions(ret)
			popup._private.display_timer:start()
		end
	end

	wp.on_destroyed = function(n)
		for i, popup in ipairs(ret.popups) do
			if popup.screen == n.screen and popup._private.notification == n then
				if popup._private.display_timer then
					popup._private.display_timer:stop()
					popup._private.display_timer = nil
				end
				popup.visible = false
				table.remove(ret.popups, i)
				popup = nil
				update_positions(ret)
			end
		end
	end

	naughty.connect_signal("destroyed", wp.on_destroyed)
	naughty.connect_signal("request::display", wp.on_added)

	return ret
end

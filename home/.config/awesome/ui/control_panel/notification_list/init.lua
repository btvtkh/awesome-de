local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local ncr = naughty.notification_closed_reason
local dpi = beautiful.xresources.apply_dpi

local notification_list = {}

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
			bg_normal = beautiful.bg_urg,
			bg_hover = beautiful.ac,
			bg_active = beautiful.bg_urg,
			fg_normal = beautiful.fg,
			fg_hover = beautiful.bg,
			fg_active = beautiful.fg_alt,
			shape = shape.rrect(dpi(8)),
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

local function create_notification_widget(n)
	local ret = wibox.widget {
		widget = wibox.container.constraint,
		strategy = "max",
		height = 260,
		{
			widget = wibox.container.background,
			bg = beautiful.bg_alt,
			shape = shape.rrect(dpi(13)),
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
	local body_layout = ret:get_children_by_id("body-layout")[1]
	local close_button = ret:get_children_by_id("close-button")[1]
	local close_icon = ret:get_children_by_id("close-icon")[1]

	wp.notification = n

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

function notification_list:clear_notifications()
	local notifs_layout = self:get_children_by_id("notifications-layout")[1]

	notifs_layout:reset()
	notifs_layout:add({
		widget = widgets.label,
		forced_height = dpi(560),
		fg = beautiful.fg_alt,
		align = "center",
		font_size = 17,
		label = "No notifications",
	})

	self:update_count()
	naughty.destroy_all_notifications(nil, ncr.silent)
end

function notification_list:update_count()
	local notifs_layout = self:get_children_by_id("notifications-layout")[1]
	local title_label = self:get_children_by_id("title-label")[1]

	if #notifs_layout.children > 0
	and notifs_layout.children[1]._private.notification then
		title_label:set_label(string.format("Notifications (%s)", #notifs_layout.children))
	else
		title_label:set_label("Notifications")
	end
end

function notification_list:toggle_dnd()
	local wp = self._private
	wp.dnd_mode = not wp.dnd_mode

	if wp.dnd_mode then
		naughty.suspend()
	else
		naughty.resume()
	end
end

return function()
	local ret = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(50) + dpi(560),
		forced_width = dpi(450),
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(6),
			{
				widget = wibox.container.margin,
				forced_height = dpi(45),
				margins = dpi(5),
				{
					layout = wibox.layout.align.horizontal,
					{
						widget = wibox.container.margin,
						margins = { left = dpi(7) },
						{
							id = "title-label",
							widget = widgets.label,
							align = "center",
							font_weight = "bold",
							font_size = 13,
							label = "Notifications"
						}
					},
					nil,
					{
						layout = wibox.layout.fixed.horizontal,
						spacing = beautiful.separator_thickness + dpi(2),
						spacing_widget = {
							widget = wibox.container.margin,
							margins = { top = dpi(8), bottom = dpi(8) },
							{
								widget = wibox.widget.separator,
								orientation = "vertical"
							}
						},
						{
							id = "dnd-button",
							widget = widgets.button,
							forced_width = dpi(35),
							forced_height = dpi(35),
							shape = shape.rrect(dpi(8)),
							bg_hover = beautiful.bg_urg,
							bg_active = beautiful.bg_alt,
							fg_normal = beautiful.fg,
							fg_hover = beautiful.fg,
							fg_active = beautiful.fg,
							{
								widget = wibox.container.place,
								halign = "center",
								valign = "center",
								{
									id = "dnd-icon",
									widget = widgets.icon,
									size = dpi(18),
									icon = icons.bell
								}
							}
						},
						{
							id = "clear-button",
							widget = widgets.button,
							forced_width = dpi(35),
							forced_height = dpi(35),
							shape = shape.rrect(dpi(8)),
							bg_hover = beautiful.red,
							bg_active = beautiful.fg_alt,
							fg_normal = beautiful.red,
							fg_hover = beautiful.bg,
							fg_active = beautiful.bg,
							{
								widget = wibox.container.place,
								halign = "center",
								valign = "center",
								{
									id = "clear-icon",
									widget = widgets.icon,
									size = dpi(18),
									icon = icons.trash
								}
							}
						}
					}
				}
			},
			{
				id = "notifications-layout",
				layout = wibox.layout.overflow.vertical,
				scrollbar_enabled = false,
				step = 80,
				spacing = dpi(6)
			}
		}
	}

	gtable.crush(ret, notification_list, true)
	local wp = ret._private
	local dnd_button = ret:get_children_by_id("dnd-button")[1]
	local dnd_icon = ret:get_children_by_id("dnd-icon")[1]
	local clear_button = ret:get_children_by_id("clear-button")[1]
	local clear_icon = ret:get_children_by_id("clear-icon")[1]
	local notifs_layout = ret:get_children_by_id("notifications-layout")[1]

	wp.dnd_mode = false

	wp.on_dnd_button_fg = function(_, fg)
		dnd_icon:set_color(fg)
	end

	wp.on_clear_button_fg = function(_, fg)
		clear_icon:set_color(fg)
	end

	wp.on_added = function(n)
		if not n then return end

		if #notifs_layout.children == 1
		and not notifs_layout.children[1]._private.notification then
			notifs_layout:reset()
		end

		notifs_layout:insert(1, create_notification_widget(n))
		ret:update_count()
	end

	wp.on_destroyed = function(n)
		for i, w in ipairs(notifs_layout.children) do
			if w._private.notification == n then
				notifs_layout:remove(i)
			end
		end

		if #notifs_layout.children == 0 then
			notifs_layout:add({
				widget = widgets.label,
				forced_height = dpi(560),
				fg = beautiful.fg_alt,
				align = "center",
				font_size = 17,
				label = "No notifications",
			})
		end

		ret:update_count()
	end

	dnd_button:connect_signal("property::fg", wp.on_dnd_button_fg)
	clear_button:connect_signal("property::fg", wp.on_clear_button_fg)

	naughty.connect_signal("destroyed", wp.on_destroyed)
	naughty.connect_signal("request::display", wp.on_added)

	dnd_button:buttons {
		awful.button({}, 1, function()
			ret:toggle_dnd()
			dnd_icon:set_icon(wp.dnd_mode and icons.bell_off or icons.bell)
		end)
	}

	clear_button:buttons {
		awful.button({}, 1, function()
			ret:clear_notifications()
		end)
	}

	dnd_icon:set_color(dnd_button:get_fg_normal())
	clear_icon:set_color(clear_button:get_fg_normal())

	notifs_layout:add({
		widget = widgets.label,
		forced_height = dpi(560),
		fg = beautiful.fg_alt,
		align = "center",
		font_size = 17,
		label = "No notifications",
	})

	return ret
end

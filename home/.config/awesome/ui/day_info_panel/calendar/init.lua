local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi

local calendar = {}

local hebr_format = {
	[1] = 7,
	[2] = 1,
	[3] = 2,
	[4] = 3,
	[5] = 4,
	[6] = 5,
	[7] = 6
}

local function wday_widget(index)
	return wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(10),
		{
			widget = widgets.label,
			forced_width = dpi(25),
			align = "center",
			fg = index >= 6 and beautiful.red or beautiful.fg,
			font_size = 9,
			label = os.date("%a", os.time({ year = 1, month = 1, day = index }))
		}
	}
end

local function day_widget(day, is_current, is_another_month)
	local fg_color = ((is_current and beautiful.bg) or (is_another_month and beautiful.fg_alt)) or beautiful.fg
	local bg_color = is_current and beautiful.ac or nil

	return wibox.widget {
		widget = wibox.container.background,
		fg = fg_color,
		bg = bg_color,
		shape = shape.rrect(dpi(6)),
		{
			widget = wibox.container.margin,
			margins = dpi(10),
			{
				widget = widgets.label,
				align = "center",
				font_size = 12,
				label = day
			}
		}
	}
end

function calendar:set_date(date)
	local wp = self._private
	local days_layout = self:get_children_by_id("days-layout")[1]
	local year_label = self:get_children_by_id("year-label")[1]
	days_layout:reset()

	wp.date = date

	local curr_date = os.date("*t")
	local firstday = os.date("*t", os.time({ year = date.year, month = date.month, day = 1 }))
	local lastday = os.date("*t", os.time({ year = date.year, month = date.month + 1, day = 0 }))
	local month_count = lastday.day
	local month_start = not wp.sun_start and hebr_format[firstday.wday] or firstday.wday
	local rows = math.max(5, math.min(6, 5 - (36 - (month_start + month_count))))
	local month_prev_lastday = os.date("*t", os.time({ year = date.year, month = date.month, day = 0 })).day
	local month_prev_count = month_start - 1
	local month_next_count = rows*7 - lastday.day - month_prev_count

	for day = month_prev_lastday - (month_prev_count - 1), month_prev_lastday, 1 do
		days_layout:add(day_widget(day, false, true))
	end

	for day = 1, month_count, 1 do
		local is_current = day == curr_date.day and date.month == curr_date.month and date.year == curr_date.year
		days_layout:add(day_widget(day, is_current, false))
	end

	for day = 1, month_next_count, 1 do
		days_layout:add(day_widget(day, false, true))
	end

	year_label:set_label(os.date("%B, %Y", os.time(date)))
end

function calendar:inc(dir)
	local wp = self._private
	local new_calendar_month = wp.date.month + dir
	self:set_date({
		year = wp.date.year,
		month = new_calendar_month,
		day = wp.date.day
	})
end

function calendar:set_current_date()
	self:set_date(os.date("*t"))
end

return function()
	local ret = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		shape = shape.rrect(dpi(13)),
		{
			widget = wibox.container.margin,
			margins = dpi(15),
			{
				layout = wibox.layout.fixed.vertical,
				{
					layout = wibox.layout.align.horizontal,
					{
						id = "year-button",
						widget = widgets.button,
						forced_height = dpi(30),
						shape = shape.rrect(dpi(6)),
						bg_hover = beautiful.bg_urg,
						fg_active = beautiful.fg_alt,
						{
							widget = wibox.container.margin,
							margins = { left = dpi(8), right = dpi(8) },
							{
								id = "year-label",
								widget = widgets.label,
								align = "center",
								font_weight = "bold",
								font_size = 12
							}
						}
					},
					nil,
					{
						widget = wibox.layout.fixed.horizontal,
						spacing = dpi(5),
						{
							id = "dec-button",
							widget = widgets.button,
							forced_width = dpi(30),
							forced_height = dpi(30),
							shape = shape.rrect(dpi(6)),
							bg_hover = beautiful.bg_urg,
							fg_active = beautiful.fg_alt,
							{
								widget = wibox.container.place,
								halign = "center",
								valign = "center",
								{
									widget = widgets.icon,
									size = dpi(18),
									icon = icons.chevron_left
								}
							}
						},
						{
							id = "inc-button",
							widget = widgets.button,
							forced_width = dpi(30),
							forced_height = dpi(30),
							shape = shape.rrect(dpi(6)),
							bg_hover = beautiful.bg_urg,
							fg_active = beautiful.fg_alt,
							{
								widget = wibox.container.place,
								halign = "center",
								valign = "center",
								{
									widget = widgets.icon,
									size = dpi(18),
									icon = icons.chevron_right
								}
							}
						}
					}
				},
				{
					id = "wdays-layout",
					layout = wibox.layout.flex.horizontal
				},
				{
					id = "days-layout",
					layout = wibox.layout.grid,
					forced_num_cols = 7,
					expand = true,
					forced_height = dpi(230)
				}
			}
		}
	}

	gtable.crush(ret, calendar, true)

	local wp = ret._private
	local wdays_layout = ret:get_children_by_id("wdays-layout")[1]
	local year_button = ret:get_children_by_id("year-button")[1]
	local dec_button = ret:get_children_by_id("dec-button")[1]
	local inc_button = ret:get_children_by_id("inc-button")[1]

	wp.sun_start = false

	wp.on_fg = function(w, fg)
		w:get_widget():get_widget():set_color(fg)
	end

	year_button:buttons {
		awful.button({}, 1, nil, function()
			ret:set_current_date()
		end)
	}

	dec_button:buttons {
		awful.button({}, 1, nil, function()
			ret:inc(-1)
		end)
	}

	inc_button:buttons {
		awful.button({}, 1, nil, function()
			ret:inc(1)
		end)
	}

	for _, b in ipairs { dec_button, inc_button } do
		b:connect_signal("property::fg", wp.on_fg)
		b:get_widget():get_widget():set_color(b:get_fg_normal())
	end

	for i = 1, 7 do
		wdays_layout:add(wp.sun_start and wday_widget(hebr_format[i]) or wday_widget(i))
	end

	ret:set_current_date()

	return ret
end

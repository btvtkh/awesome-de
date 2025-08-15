local wibox = require("wibox")
local beautiful = require("beautiful")
local shape = require("lib.shape")
local gtable = require("gears.table")
local text_icons = require("beautiful").text_icons
local markup = require("lib.string").markup
local dpi = beautiful.xresources.apply_dpi
local Weather = require("service.weather")

local weather_applet = {}

local desc_map = {
	[0] = "Clear sky",
	[1] = "Mainly clear",
	[2] = "Partly cloudy",
	[3] = "Overcast",
	[45] = "Fog",
	[48] = "Depositing rime fog",
	[51] = "Light drizzle",
	[53] = "Moderate drizzle",
	[55] = "Dense drizzle",
	[56] = "Light freezing\ndrizzle",
	[57] = "Dense freezing\ndrizzle",
	[61] = "Slight rain",
	[63] = "Moderate rain",
	[65] = "Heavy rain",
	[66] = "Light freezing\nrain",
	[67] = "Heavy freezing\nrain",
	[71] = "Slight snow fall",
	[73] = "Moderate snow fall",
	[75] = "Heavy snow fall",
	[77] = "Snow grains",
	[80] = "Slight rains\nshowers",
	[81] = "Moderate rain\nshowers",
	[82] = "Violent rain\nshowers",
	[85] = "Slight snow\nnshowers",
	[86] = "Heavy snow\nshowers",
	[95] = "Thunderstorm",
	[96] = "Thunderstorm\nwith slight hail",
	[99] = "Thunderstorm\nwith heavy hail"
}

local icon_map = {
	[0] = text_icons.no_cloud,
	[1] = text_icons.no_cloud,
	[2] = text_icons.cloud,
	[3] = text_icons.cloud,
	[45] = text_icons.mist,
	[48] = text_icons.mist,
	[51] = text_icons.rain,
	[53] = text_icons.rain,
	[55] = text_icons.rain,
	[56] = text_icons.rain,
	[57] = text_icons.rain,
	[61] = text_icons.rain,
	[63] = text_icons.rain,
	[65] = text_icons.rain,
	[66] = text_icons.rain,
	[67] = text_icons.rain,
	[71] = text_icons.snow,
	[73] = text_icons.snow,
	[75] = text_icons.snow,
	[77] = text_icons.snow,
	[80] = text_icons.shower_rain,
	[81] = text_icons.shower_rain,
	[82] = text_icons.shower_rain,
	[85] = text_icons.snow,
	[86] = text_icons.snow,
	[95] = text_icons.thunder,
	[96] = text_icons.thunder,
	[99] = text_icons.thunder
}

local function to_direction(deg)
	if deg == nil then return "Unknown dir" end
	local directions = {
		"N", "NNE", "NE", "ENE",
		"E", "ESE", "SE", "SSE",
		"S", "SSW", "SW", "WSW",
		"W", "WNW", "NW", "NNW",
		"N"
	}
	return directions[math.floor((deg % 360) / 22.5) + 1]
end

local function create_current(data)
	local icon = icon_map[data.current.weather_code]
	local desc = desc_map[data.current.weather_code]
	local temp = string.format(
		"%d%s",
		math.floor(data.current.temperature_2m),
		data.current_units.temperature_2m
	)
	local feels_like = string.format(
		"Feels like %d%s",
		math.floor(data.current.apparent_temperature),
		data.current_units.apparent_temperature
	)
	local wind = string.format(
		text_icons.wind .. " %d%s (%s)",
		math.floor(data.current.wind_speed_10m),
		data.current_units.wind_speed_10m,
		to_direction(data.current.wind_direction_10m)
	)
	local humidity = string.format(
		text_icons.droplet .. " %d%s",
		data.current.relative_humidity_2m,
		data.current_units.relative_humidity_2m
	)
	local pressure = string.format(
		text_icons.thermometer .. " %d%s",
		math.floor(data.current.surface_pressure),
		data.current_units.surface_pressure
	)

	return wibox.widget {
		widget = wibox.container.margin,
		margins = {
			left = dpi(15), right = dpi(15),
			top = dpi(15), bottom = dpi(10)
		},
		{
			layout = wibox.layout.fixed.horizontal,
			fill_space = true,
			{
				layout = wibox.layout.fixed.vertical,
				{
					widget = wibox.widget.textbox,
					font = beautiful.font_h2,
					align = "left",
					markup = string.format("%s %s", icon, temp)
				},
				{
					widget = wibox.widget.textbox,
					align = "left",
					markup = feels_like
				},
				{
					widget = wibox.widget.textbox,
					align = "left",
					markup = desc
				}
			},
			{
				layout = wibox.layout.fixed.vertical,
				{
					widget = wibox.widget.textbox,
					align = "right",
					markup = wind
				},
				{
					widget = wibox.widget.textbox,
					align = "right",
					markup = pressure
				},
				{
					widget = wibox.widget.textbox,
					align = "right",
					markup = humidity
				}
			}
		}
	}
end

local function create_hourly(data)
	local step_width = dpi(40)
	local step_spacing = dpi(1)

	local widget = wibox.widget {
		widget = wibox.container.margin,
		margins = {
			top = 0, bottom = dpi(15),
			left = dpi(15), right = dpi(15)
		},
		{
			layout = wibox.layout.overflow.horizontal,
			scrollbar_enabled = false,
			step = 40,
			{
				layout = wibox.layout.fixed.vertical,
				forced_width = dpi(24 * step_width + 23 * step_spacing),
				spacing = dpi(5),
				{
					id = "times",
					layout = wibox.layout.flex.horizontal
				},
				{
					id = "graph",
					widget = wibox.widget.graph,
					forced_height = dpi(40),
					step_spacing = step_spacing,
					step_width = step_width,
					color = beautiful.ac,
					background_color = beautiful.bg_alt
				},
				{
					id = "temps",
					layout = wibox.layout.flex.horizontal
				}
			}
		}
	}

	local time_layout = widget:get_children_by_id("times")[1]
	local temp_graph = widget:get_children_by_id("graph")[1]
	local temp_layout = widget:get_children_by_id("temps")[1]

	local temp_arr = {}
	for i = 24, 1, -1 do
		local temp = math.floor(data.hourly.temperature_2m[i])
		table.insert(temp_arr, temp)
		temp_graph:add_value(temp)
	end

	temp_graph:set_min_value(math.min(table.unpack(temp_arr)) - 1)
	temp_graph:set_max_value(math.max(table.unpack(temp_arr)) + 1)

	for i = 2, 24, 2 do
		local time_str = os.date("%H:%M", data.hourly.time[i])
		local temp_str = string.format(
			"%d%s",
			math.floor(data.hourly.temperature_2m[i]),
			data.hourly_units.temperature_2m
		)

		time_layout:add(wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			font = beautiful.font_h0,
			markup = markup(time_str, {
				fg = beautiful.fg_alt
			})
		})

		temp_layout:add(wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			markup = temp_str
		})
	end

	return widget
end

local function create_daily(data)
	local widget = wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(15),
		{
			id = "days",
			layout = wibox.layout.overflow.horizontal,
			scrollbar_enabled = false,
			step = 40
		}
	}

	local day_layout = widget:get_children_by_id("days")[1]

	for i = 1, 7 do
		local time_str = os.date("%a", data.daily.time[i])
		local icon_str = icon_map[data.daily.weather_code[i]]
		local temp_str = string.format(
			"%d%s\n%d%s",
			math.floor(data.daily.temperature_2m_max[i]),
			data.daily_units.temperature_2m_max,
			math.floor(data.daily.temperature_2m_min[i]),
			data.daily_units.temperature_2m_min
		)

		day_layout:add(wibox.widget {
			widget = wibox.container.place,
			forced_width = dpi(110),
			halign = "center",
			{
				layout = wibox.layout.fixed.vertical,
				{
					widget = wibox.widget.textbox,
					align = "center",
					font = beautiful.font_h0,
					markup = markup(time_str, {
						fg = beautiful.fg_alt
					})
				},
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(7),
					{
						widget = wibox.widget.textbox,
						align = "center",
						markup = markup(icon_str, {
							size = "20pt"
						})
					},
					{
						widget = wibox.widget.textbox,
						align = "center",
						markup = temp_str
					}
				}
			}
		})
	end

	return widget
end

return function()
	local weather = Weather.get_default()

	local ret = wibox.widget {
		widget = wibox.container.background,
		forced_width = dpi(370),
		bg = beautiful.bg_alt,
		shape = shape.rrect(dpi(13)),
		{
			id = "main-layout",
			layout = wibox.layout.fixed.vertical
		}
	}

	gtable.crush(ret, weather_applet, true)
	local wp = ret._private
	local main_layout = ret:get_children_by_id("main-layout")[1]

	wp.on_data_received = function(_, data)
		main_layout:reset()

		if data then
			data = data[1] or data
			main_layout:add(
				create_current(data),
				create_hourly(data),
				wibox.widget {
					widget = wibox.container.margin,
					margins = { left = dpi(10), right = dpi(10) },
					{
						widget = wibox.widget.separator,
						forced_width = 1,
						forced_height = beautiful.separator_thickness,
						orientation = "horizontal"
					}
				},
				create_daily(data)
			)
		else
			local err_msg = wibox.widget {
				widget = wibox.container.background,
				bg = beautiful.bg_alt,
				fg = beautiful.fg_alt,
				forced_height = dpi(100),
				{
					widget = wibox.widget.textbox,
					align = "center",
					font = beautiful.font_h2,
					markup = "No weather data"
				}
			}

			main_layout:add(err_msg)
		end
	end

	weather:connect_signal("data-received", wp.on_data_received)

	return ret
end

local gobject = require("gears.object")
local gtable = require("gears.table")
local widgets = require("widgets")
local json = require("lib.json")
local user = require("user")

local weather = {}

function weather:set_remote_watch()
	local wp = self._private

	local curl_mockup = "curl -sf 'https://api.open-meteo.com/v1/forecast?"
		.. "latitude=%s&longitude=%s&current=temperature_2m,"
		.. "relative_humidity_2m,weather_code,surface_pressure,"
		.. "wind_speed_10m,wind_direction_10m,apparent_temperature,"
		.. "&hourly=temperature_2m,weather_code&daily=weather_code,"
		.. "temperature_2m_max,temperature_2m_min&wind_speed_unit=ms"
		.. "&forecast_hours=24&timeformat=unixtime&timezone=auto%s'"

	local cmd = string.format(
		curl_mockup,
		tostring(wp.lat),
		tostring(wp.lon),
		wp.imperial_units and "&temperature_unit=fahrenheit" or ""
	)

	wp.remote_watch = widgets.remote(cmd, wp.interval, wp.output_file, function(out)
		local data = out ~= "" and json.decode(out)
		self:emit_signal("data-received", data)
	end)
end

function weather:destroy_remote_watch()
	local wp = self._private
	wp.remote_watch:stop()
	wp.remote_watch = nil
end

local function new(args)
	args = args or {}
	local ret = gobject {}

	if args.output_file then
		gtable.crush(ret, weather, true)
		ret._private = {}

		local wp = ret._private
		wp.output_file = args.output_file
		wp.lat = args.lat or 0
		wp.lon = args.lon or 0
		wp.interval = args.interval or 600
		wp.imperial_units = args.imperial_units

		ret:set_remote_watch()
	end

	return ret
end

local instance = nil
local function get_default()
	if not instance then
		instance = new {
			output_file = "/tmp/awesomewm_weather.json",
			lat = user.weather_location and user.weather_location[1],
			lon = user.weather_location and user.weather_location[2],
			imperial_units = user.weather_imperial_units
		}
	end
	return instance
end

return { get_default = get_default }

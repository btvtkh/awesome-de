local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local beautiful = require("beautiful")

local wallpaper = {}

function wallpaper:set_image(new_image)
	if not new_image then return end
	self:set_widget {
		widget = wibox.widget.imagebox,
		resize = true,
		valign = "center",
		halign = "center",
		horizontal_fit_policy = "cover",
		vertical_fit_policy = "cover",
		image = new_image
	}
	self:repaint()
end

function wallpaper:unset()
	self:set_widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt
	}
	self:repaint()
end

return function(s)
	local ret = awful.wallpaper {
		screen = s,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.bg_alt
		}
	}

	gtable.crush(ret, wallpaper, true)
	return ret
end

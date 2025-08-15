local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local shape = require("lib.shape")
local gtable = require("gears.table")
local dpi = beautiful.xresources.apply_dpi
local capi = { screen = screen }
local Calendar = require("ui.day_info_panel.calendar")
--local Weather_applet = require("ui.day_info_panel.weather_applet")

local day_info = {}

function day_info:show()
	if self.visible then return end
	self.widget:get_children_by_id("calendar")[1]:set_current_date()
	self.visible = true
	self:emit_signal("property::visible", self.visible)
end

function day_info:hide()
	if not self.visible then return end
	self.visible = false
	self:emit_signal("property::visible", self.visible)
end

function day_info:toggle()
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
		widget = wibox.widget {
			widget = wibox.container.background,
			bg = beautiful.bg,
			border_width = beautiful.border_width,
			border_color = beautiful.border_color_normal,
			shape = shape.rrect(dpi(23)),
			{
				widget = wibox.container.margin,
				margins = dpi(10),
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(6),
					--Weather_applet(),
					{
						id = "calendar",
						widget = Calendar()
					}
				}
			}
		}
	}

	gtable.crush(ret, day_info, true)
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

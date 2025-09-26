local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local gtable = require("gears.table")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi
local capi = { awesome = awesome, screen = screen }

local powermenu = {}

local keys = {
	up = { "Up" },
	down = { "Down" },
	left = { "Left" },
	right = { "Right" },
	exec = { "Return" },
	close = { "Escape" }
}

local function run_keygrabber(self)
	local wp = self._private
	wp.keygrabber = awful.keygrabber.run(function(_, key, event)
		if event ~= "press" then return end
		if gtable.hasitem(keys.up, key) then
			self:forward()
			self:update_elements()
		elseif gtable.hasitem(keys.down, key) then
			self:backward()
			self:update_elements()
		elseif gtable.hasitem(keys.left, key) then
			self:backward()
			self:update_elements()
		elseif gtable.hasitem(keys.right, key) then
			self:forward()
			self:update_elements()
		elseif gtable.hasitem(keys.exec, key) then
			wp.elements[wp.select_index].exec()
		elseif gtable.hasitem(keys.close, key) then
			self:hide()
		end
	end)
end

local function Powermenu_button(element, index, self)
	local ret = wibox.widget {
		widget = widgets.button,
		forced_width = dpi(120),
		forced_height = dpi(120),
		shape = shape.rrect(dpi(20)),
		{
			widget = wibox.container.place,
			halign = "center",
			valign = "center",
			{
				id = "icon",
				widget = widgets.icon,
				size = dpi(32),
				icon = element.icon
			}
		}
	}

	local wp = ret._private
	local icon = ret:get_children_by_id("icon")[1]

	wp.on_fg = function(_, fg)
		icon:set_color(fg)
	end

	wp.on_clicked = function()
		if self._private.select_index == index then
			element.exec()
		else
			self._private.select_index = index
			self:update_elements()
		end
	end


	ret:connect_signal("property::fg", wp.on_fg)

	ret:buttons {
		awful.button({}, 1, nil, wp.on_clicked)
	}

	icon:set_color(ret:get_fg_normal())

	if index == self._private.select_index then
		ret:set_bg_normal(beautiful.ac)
		ret:set_bg_hover(beautiful.ac)
		ret:set_bg_active(beautiful.fg_alt)
		ret:set_fg_normal(beautiful.bg)
		ret:set_fg_hover(beautiful.bg)
		ret:set_fg_active(beautiful.bg)
	else
		ret:set_bg_normal(nil)
		ret:set_bg_hover(beautiful.bg_urg)
		ret:set_bg_active(beautiful.bg_alt)
		ret:set_fg_normal(beautiful.fg)
		ret:set_fg_hover(beautiful.fg)
		ret:set_fg_active(beautiful.fg_alt)
	end

	return ret
end

function powermenu:forward()
	local wp = self._private
	wp.prev_select_index = wp.select_index
	wp.select_index = math.min(wp.prev_select_index + 1, math.max(1, #wp.elements))
end

function powermenu:backward()
	local wp = self._private
	wp.prev_select_index = wp.select_index
	wp.select_index = math.max(wp.prev_select_index - 1, 1)
end

function powermenu:update_elements()
	local elements_layout = self.widget:get_children_by_id("elements-layout")[1]

	for i, widget in ipairs(elements_layout.children) do
		if i == self._private.select_index then
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

function powermenu:show()
	if self.visible then return end
	local wp = self._private
	wp.select_index = 1
	self:update_elements()
	run_keygrabber(self)
	self.visible = true
	self:emit_signal("property::visible", self.visible)
end

function powermenu:hide()
	if not self.visible then return end
	local wp = self._private
	awful.keygrabber.stop(wp.keygrabber)
	wp.select_index = 1
	self.visible = false
	self:emit_signal("property::visible", self.visible)
end

function powermenu:toggle()
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
		placement = awful.placement.centered,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.bg,
			border_width = beautiful.border_width,
			border_color = beautiful.border_color_normal,
			shape = shape.rrect(dpi(30)),
			{
				widget = wibox.container.margin,
				margins = dpi(10),
				{
					id = "elements-layout",
					spacing = dpi(4),
					layout = wibox.layout.fixed.horizontal
				}
			}
		}
	}

	gtable.crush(ret, powermenu, true)
	local wp = ret._private
	local elements_layout = ret.widget:get_children_by_id("elements-layout")[1]

	wp.elements = {
		{
			icon = icons.power,
			exec = function() awful.spawn("poweroff") end
		},
		{
			icon = icons.refresh,
			exec = function() awful.spawn("reboot") end
		},
		{
			icon = icons.log_out,
			exec = function() capi.awesome.quit() end
		}
	}


	for i, element in ipairs(wp.elements) do
		elements_layout:add(Powermenu_button(element, i, ret))
	end

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

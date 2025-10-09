local background = require("wibox.container.background")
local gtable = require("gears.table")
local beautiful = require("beautiful")

local button = {}

local properties = {
	["is_hovered"] = true,
	["is_pressed"] = true,
	["bg_normal"] = false,
	["bg_hover"] = false,
	["bg_active"] = false,
	["fg_normal"] = false,
	["fg_hover"] = false,
	["fg_active"] = false
}

for prop_name, read_only in pairs(properties) do
	if not read_only then
		button["set_" .. prop_name] = function(self, value)
			local changed = self._private[prop_name] ~= value
			self._private[prop_name] = value

			if changed then
				if self._private.is_pressed then
					self:set_bg(self._private.bg_active)
					self:set_fg(self._private.fg_active)
				elseif self._private.is_hovered then
					self:set_bg(self._private.bg_hover)
					self:set_fg(self._private.fg_hover)
				else
					self:set_bg(self._private.bg_normal)
					self:set_fg(self._private.fg_normal)
				end
			end
		end
	end

	button["get_" .. prop_name] = function(self)
		return self._private[prop_name] == nil
			and properties[prop_name]
			or self._private[prop_name]
	end
end

local function new(args)
	args = args or {}

	args.fg_normal = args.fg_normal or beautiful.fg
	args.fg_hover = args.fg_hover or args.fg_normal
	args.fg_active = args.fg_active or args.fg_normal
	args.bg_normal = args.bg_normal
	args.bg_hover = args.bg_hover or args.bg_normal
	args.bg_active = args.bg_active or args.bg_normal

	local ret = background()
	gtable.crush(ret._private, args)
	gtable.crush(ret, button, true)

	local wp = ret._private

	wp.on_mouse_enter = function(self)
		if wp.is_hovered then return end
		wp.is_hovered = true
		self:emit_signal("property::is-hovered", wp.is_hovered)
		if not wp.is_pressed then
			self:set_bg(wp.bg_hover)
			self:set_fg(wp.fg_hover)
		end
	end

	wp.on_mouse_leave = function(self)
		if not wp.is_hovered then return end
		wp.is_hovered = false
		self:emit_signal("property::is-hovered", wp.is_hovered)
		wp.is_pressed = false
		self:emit_signal("property::is-pressed", wp.is_pressed)
		self:set_bg(wp.bg_normal)
		self:set_fg(wp.fg_normal)
	end

	wp.on_button_press = function(self)
		wp.is_pressed = true
		self:emit_signal("property::is-pressed", wp.is_pressed)
		self:set_bg(wp.bg_active)
		self:set_fg(wp.fg_active)
	end

	wp.on_button_release = function(self)
		wp.is_pressed = false
		self:emit_signal("property::is-pressed", wp.is_pressed)
		if wp.is_hovered then
			self:set_bg(wp.bg_hover)
			self:set_fg(wp.fg_hover)
		else
			self:set_bg(wp.bg_normal)
			self:set_fg(wp.fg_normal)
		end
	end

	ret:connect_signal("mouse::leave", wp.on_mouse_leave)
	ret:connect_signal("mouse::enter", wp.on_mouse_enter)
	ret:connect_signal("button::release", wp.on_button_release)
	ret:connect_signal("button::press", wp.on_button_press)

	wp.is_pressed = false
	wp.is_hovered = false

	ret:set_widget(args.widget)

	return ret
end

return setmetatable({ new = new }, { __call = function(_, ...) return new(...) end })

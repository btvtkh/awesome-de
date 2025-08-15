local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")

local audio = {}

function audio:get_default_sink_data()
	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-volume @DEFAULT_SINK@", function(stdout)
		self.default_sink_volume = tonumber(stdout:match("/%s+(%d+)%%"))
		self:emit_signal("default-sink::volume", self.default_sink_volume)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-mute @DEFAULT_SINK@", function(stdout)
		self.default_sink_mute = stdout:match("%s+(%w+)") == "yes"
		self:emit_signal("default-sink::mute", self.default_sink_mute)
	end)
end

function audio:set_default_sink_volume(value)
	awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ " .. tostring(value) .. "%", false)
end

function audio:toggle_default_sink_mute()
	awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false)
end

function audio:get_default_source_data()
	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-volume @DEFAULT_SOURCE@", function(stdout)
		self.default_source_volume = tonumber(stdout:match("/%s+(%d+)%%"))
		self:emit_signal("default-source::volume", self.default_source_volume)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-mute @DEFAULT_SOURCE@", function(stdout)
		self.default_source_mute = stdout:match("%s+(%w+)") == "yes"
		self:emit_signal("default-source::mute", self.default_source_mute)
	end)
end

function audio:set_default_source_volume(value)
	awful.spawn("pactl set-source-volume @DEFAULT_SOURCE@ " .. tostring(value) .. "%", false)
end

function audio:toggle_default_source_mute()
	awful.spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle", false)
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, audio, true)

	ret.default_sink_volume = 0
	ret.default_sink_mute = false
	ret.default_source_volume = 0
	ret.default_source_mute = false

	ret:get_default_sink_data()
	ret:get_default_source_data()

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

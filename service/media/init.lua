local GLib = require("lgi").require("GLib")
local dbus_proxy = require("lib.dbus_proxy")
local gobject = require("gears.object")
local gtable = require("gears.table")

local media = {}
local player = {}
local metadata = {}

local PlaybackStatus = {
	PLAYING = "Playing",
	PAUSED = "Paused",
	STOPPED = "Stopped"
}

local LoopStatus = {
	NONE = "None",
	TRACK = "Track",
	PLAYLIST = "Playlist"
}

function media:get_players()
	return self.players
end

function media:get_player(name)
	return self.players[name]
end

function player:get_playback_status()
	return self._private.properties_proxy:Get(
		self._private.player_proxy.interface,
		"PlaybackStatus"
	)
end

function player:get_metadata()
	return setmetatable(
		self._private.properties_proxy:Get(
			self._private.player_proxy.interface,
			"Metadata"
		),
		{ __index = metadata }
	)
end

function player:get_position()
	return self._private.properties_proxy:Get(
		self._private.player_proxy.interface,
		"Position"
	)
end

function player:get_loop_status()
	return self._private.properties_proxy:Get(
		self._private.player_proxy.interface,
		"LoopStatus"
	)
end

function player:get_shuffle()
	return self._private.properties_proxy:Get(
		self._private.player_proxy.interface,
		"Shuffle"
	)
end

function player:next()
	self._private.player_proxy:NextAsync(nil, {})
end

function player:previous()
	self._private.player_proxy:PreviousAsync(nil, {})
end

function player:play()
	self._private.player_proxy:PlayAsync(nil, {})
end

function player:pause()
	self._private.player_proxy:PauseAsync(nil, {})
end

function player:play_pause()
	self._private.player_proxy:PlayPauseAsync(nil, {})
end

function player:set_position(id, pos)
	self._private.player_proxy:SetPositionAsync(nil, {}, id, pos)
end

function player:seek(offset)
	self._private.player_proxy:SeekAsync(nil, {}, offset)
end

function player:set_loop_status(status)
	self._private.player_proxy:SetAsync(
		nil,
		{},
		self._private.player_proxy.interface,
		"LoopStatus",
		GLib.Variant("s", status)
	)

	self._private.player_proxy.LoopStatus = {
		signature = "s",
		value = status
	}
end

function player:set_shuffle(shuffle)
	self._private.player_proxy:SetAsync(
		nil,
		{},
		self._private.player_proxy.interface,
		"Shuffle",
		GLib.Variant("b", shuffle)
	)

	self._private.player_proxy.Shuffle = {
		signature = "b",
		value = shuffle
	}
end

function metadata:get_track_id()
	return self["mpris:trackid"]
end

function metadata:get_title()
	return self["xesam:title"]
end

function metadata:get_album()
	return self["xesam:album"]
end

function metadata:get_artist()
	return self["xesam:artist"]
end

function metadata:get_art_url()
	return self["mpris:artUrl"]
end

function metadata:get_url()
	return self["xesam:url"]
end

function metadata:get_length()
	return self["mpris:length"]
end

local function create_player_object(name)
	local ret = gobject {}
	gtable.crush(ret, player, true)
	ret._private = {}

	ret._private.player_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SESSION,
		name = name,
		path = "/org/mpris/MediaPlayer2",
		interface = "org.mpris.MediaPlayer2.Player"
	}

	ret._private.properties_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SESSION,
		name = name,
		path = "/org/mpris/MediaPlayer2",
		interface = "org.freedesktop.DBus.Properties"
	}

	ret._private.properties_proxy:connect_signal("PropertiesChanged", function(_, _, props)
		if props.PlaybackStatus ~= nil then
			ret:emit_signal("property::playback-status", props.PlaybackStatus)
		end
		if props.Metadata ~= nil then
			ret:emit_signal("property::metadata", setmetatable(
				props.Metadata,
				{ __index = metadata }
			))
		end
		if props.LoopStatus then
			ret:emit_signal("property::loop-status", props.LoopStatus)
		end
		if props.Shuffle ~= nil then
			ret:emit_signal("property::shuffle", props.Shuffle)
		end
	end)

	ret._private.player_proxy:connect_signal("Seeked", function(_, pos)
		ret:emit_signal("seeked", pos)
	end)

	return ret
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, media, true)
	ret._private = {}

	local names_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SESSION,
		name = "org.freedesktop.DBus",
		path = "/org/freedesktop/DBus",
		interface = "org.freedesktop.DBus"
	}

	ret.players = {}
	if names_proxy then
		names_proxy:connect_signal("NameOwnerChanged", function(_, name, old_owner, new_owner)
			if name:match("org%.mpris%.MediaPlayer2%.%w+") then
				if old_owner == "" and new_owner ~= "" then
					ret.players[name] = create_player_object(name)
					ret:emit_signal("player-added", name, ret:get_player(name))
				elseif old_owner ~= "" and new_owner == "" then
					ret:emit_signal("player-removed", name, ret:get_player(name))
					ret.players[name] = nil
				end
			end
		end)

		for _, name in ipairs(names_proxy:ListNames()) do
			if name:match("org%.mpris%.MediaPlayer2%.%w+") then
				ret.players[name] = create_player_object(name)
			end
		end
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

return {
	PlaybackStatus = PlaybackStatus,
	LoopStatus = LoopStatus,
	get_default = get_default
}

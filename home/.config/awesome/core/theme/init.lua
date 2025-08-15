local beautiful = require("beautiful")
local gfs = require("gears.filesystem")
local user = require("user")

local themes = {
	["astel"] = true,
	["astel_blacked"] = true
}

local theme_name = themes[user.theme] and user.theme or "astel"
beautiful.init(gfs.get_configuration_dir() .. "themes/" .. theme_name .. "/theme.lua")

local awful = require("awful")
local Media_panel = require("ui.media_panel")

awful.keyboard.append_global_keybinding(
	awful.key({ "Mod4" }, "k", function()
		Media_panel.get_default():toggle()
	end)
)

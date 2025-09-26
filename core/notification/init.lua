local Gio = require("lgi").require("Gio")
local awful = require("awful")
local naughty = require("naughty")
local rnotification = require("ruled.notification")
local ncr = naughty.notification_closed_reason
local capi = { awesome = awesome }
local Screenshot = require("service.screenshot")

rnotification.connect_signal("request::rules", function()
	rnotification.append_rule {
		id = "global",
		rule = {},
		properties = {
			timeout = 0
		}
	}
end)

capi.awesome.connect_signal("exit", function()
	naughty.destroy_all_notifications(nil, ncr.silent)
end)

local screenshot = Screenshot.get_default()

screenshot:connect_signal("saved", function(_, dir, name)
	local view_file = naughty.action { name = "View" }
	local open_dir = naughty.action { name = "Folder" }
	local copy = naughty.action { name = "Copy" }

	view_file:connect_signal("invoked", function()
		local app = Gio.AppInfo.get_default_for_type("image/png")
		if app then awful.spawn(string.format("%s %s", app:get_executable(), dir .. name)) end
	end)

	open_dir:connect_signal("invoked", function()
		local app = Gio.AppInfo.get_default_for_type("inode/directory")
		if app then awful.spawn(string.format("%s %s", app:get_executable(), dir)) end
	end)

	copy:connect_signal("invoked", function()
		screenshot:copy_screenshot(dir .. name)
	end)

	local display_dir = dir:gsub(tostring(os.getenv("HOME")), "~")

	naughty.notification {
		app_name = "Screenshot",
		title = "Screenshot taken",
		text = "Saved to: " .. display_dir,
		icon = dir .. name,
		actions = { view_file, open_dir, copy }
	}
end)

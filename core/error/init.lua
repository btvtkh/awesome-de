local naughty = require("naughty")

naughty.connect_signal("request::display_error", function(message, startup)
	naughty.notification {
		app_name = "Awesome",
		urgency = "critical",
		title = "An error happened" .. (startup and " during startup!" or "!"),
		text = message
	}
end)

local awful = require("awful")
local capi = { tag = tag }

local tags = {
	"tag-1",
	"tag-2",
	"tag-3",
	"tag-4",
	"tag-5"
}

local layouts = {
	awful.layout.suit.floating,
	awful.layout.suit.tile
}

capi.tag.connect_signal("request::default_layouts", function()
	awful.layout.append_default_layouts(layouts)
end)

awful.screen.connect_for_each_screen(function(s)
	awful.tag(tags, s, layouts[1])
end)

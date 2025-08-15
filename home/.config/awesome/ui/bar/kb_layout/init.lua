local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local markup = require("lib.string").markup
local capitalize = require("lib.string").capitalize
local dpi = beautiful.xresources.apply_dpi

return function()
	local ret = wibox.widget {
		widget = widgets.button,
		forced_width = dpi(35),
		bg_normal = beautiful.bg_alt,
		bg_hover = beautiful.bg_urg,
		bg_active = beautiful.bg_alt,
		fg_active = beautiful.fg_alt,
		shape = shape.rrect(dpi(10)),
		{
			widget = wibox.container.place,
			halign = "center",
			content_fill_vertical = true,
			{
				id = "kb-layout-widget",
				widget = awful.widget.keyboardlayout
			}
		}
	}

	local wp = ret._private
	local kb_layout_textbox = ret:get_children_by_id("kb-layout-widget")[1].widget

	wp.on_kb_text = function(w, text)
		w:set_markup(
			markup(capitalize(text:gsub("%s+", "")), { font_size = 11 })
		)
	end

	kb_layout_textbox:connect_signal("property::text", wp.on_kb_text)

	wp.on_kb_text(kb_layout_textbox, kb_layout_textbox:get_text())

	return ret
end

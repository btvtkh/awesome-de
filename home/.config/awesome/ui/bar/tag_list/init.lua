local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local dpi = beautiful.xresources.apply_dpi
local capi = { client = client }
local mod = "Mod4"

return function(s)
	local ret = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		shape = shape.rrect(dpi(10)),
		{
			widget = wibox.container.margin,
			margins = dpi(4),
			{
				id = "taglist",
				widget = awful.widget.taglist {
					screen = s,
					filter = awful.widget.taglist.filter.all,
					buttons = {
						awful.button({}, 1, function(t)
							t:view_only()
						end),
						awful.button({}, 3, function(t)
							awful.tag.viewtoggle(t)
						end),
						awful.button({}, 4, function(t)
							awful.tag.viewprev(t.screen)
						end),
						awful.button({}, 5, function(t)
							awful.tag.viewnext(t.screen)
						end),
						awful.button({ mod }, 1, function(t)
							if capi.client.focus then
								capi.client.focus:move_to_tag(t)
							end
						end),
						awful.button({ mod }, 3, function(t)
							if capi.client.focus then
								capi.client.focus:toggle_tag(t)
							end
						end),
					},
					layout = {
						layout = wibox.layout.fixed.horizontal,
						spacing = dpi(2)
					},
					widget_template = {
						id = "t-button",
						widget = widgets.button,
						forced_width = dpi(25),
						shape = shape.rrect(dpi(6)),
						{
							id = "t-label",
							widget = widgets.label,
							halign = "center",
							valign = "center",
							font_weight = 500,
							font_size = 11
						}
					}
				}
			}
		}
	}

	local taglist = ret:get_children_by_id("taglist")[1]

	taglist.widget_template.create_callback = function(tw, t)
		local t_button = tw:get_children_by_id("t-button")[1]
		local t_label = tw:get_children_by_id("t-label")[1]

		t_label:set_label(t.index)

		if t.selected then
			t_button:set_bg_normal(beautiful.ac)
			t_button:set_bg_hover(beautiful.ac)
			t_button:set_bg_active(beautiful.fg_alt)
			t_button:set_fg_normal(beautiful.bg)
			t_button:set_fg_hover(beautiful.bg)
			t_button:set_fg_active(beautiful.bg)
		elseif #t:clients() > 0 then
			t_button:set_bg_normal(nil)
			t_button:set_bg_hover(beautiful.bg_urg)
			t_button:set_bg_active(nil)
			t_button:set_fg_normal(beautiful.fg)
			t_button:set_fg_hover(beautiful.fg)
			t_button:set_fg_active(beautiful.fg)
		else
			t_button:set_bg_normal(nil)
			t_button:set_bg_hover(beautiful.bg_urg)
			t_button:set_bg_active(nil)
			t_button:set_fg_normal(beautiful.fg_alt)
			t_button:set_fg_hover(beautiful.fg_alt)
			t_button:set_fg_active(beautiful.bg_urg)
		end

		for _, c in ipairs(t:clients()) do
			if c.urgent then
				t_button:set_bg_normal(beautiful.red)
				t_button:set_bg_hover(beautiful.bg_urg)
				t_button:set_bg_active(nil)
				t_button:set_fg_normal(beautiful.bg)
				t_button:set_fg_hover(beautiful.red)
				t_button:set_fg_active(beautiful.fg)
				break
			end
		end
	end

	taglist.widget_template.update_callback = function(tw, t)
		local t_button = tw:get_children_by_id("t-button")[1]
		local t_label = tw:get_children_by_id("t-label")[1]

		t_label:set_label(t.index)

		if t.selected then
			t_button:set_bg_normal(beautiful.ac)
			t_button:set_bg_hover(beautiful.ac)
			t_button:set_bg_active(beautiful.fg_alt)
			t_button:set_fg_normal(beautiful.bg)
			t_button:set_fg_hover(beautiful.bg)
			t_button:set_fg_active(beautiful.bg)
		elseif #t:clients() > 0 then
			t_button:set_bg_normal(nil)
			t_button:set_bg_hover(beautiful.bg_urg)
			t_button:set_bg_active(nil)
			t_button:set_fg_normal(beautiful.fg)
			t_button:set_fg_hover(beautiful.fg)
			t_button:set_fg_active(beautiful.fg)
		else
			t_button:set_bg_normal(nil)
			t_button:set_bg_hover(beautiful.bg_urg)
			t_button:set_bg_active(nil)
			t_button:set_fg_normal(beautiful.fg_alt)
			t_button:set_fg_hover(beautiful.fg_alt)
			t_button:set_fg_active(beautiful.bg_urg)
		end

		for _, c in ipairs(t:clients()) do
			if c.urgent then
				t_button:set_bg_normal(beautiful.red)
				t_button:set_bg_hover(beautiful.bg_urg)
				t_button:set_bg_active(nil)
				t_button:set_fg_normal(beautiful.bg)
				t_button:set_fg_hover(beautiful.red)
				t_button:set_fg_active(beautiful.fg)
				break
			end
		end
	end

	return ret
end

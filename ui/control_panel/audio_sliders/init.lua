local AstalWp = require("lgi").require("AstalWp")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local icons = beautiful.icons
local dpi = beautiful.xresources.apply_dpi

return function()
	local astal_wp = AstalWp.get_default()
	local audio = astal_wp:get_audio()
	local speaker = audio:get_default_speaker()
	local microphone = audio:get_default_microphone()

	local ret = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		shape = shape.rrect(dpi(13)),
		{
			widget = wibox.container.margin,
			margins = dpi(10),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(2),
				{
					layout = wibox.layout.fixed.horizontal,
					fill_space = true,
					{
						id = "speaker-mute-button",
						widget = widgets.button,
						forced_width = dpi(40),
						forced_height = dpi(40),
						shape = shape.rrect(dpi(8)),
						fg_active = beautiful.fg_alt,
						bg_hover = beautiful.bg_urg,
						{
							widget = wibox.container.place,
							halign = "center",
							valign = "center",
							{
								id = "speaker-mute-icon",
								widget = widgets.icon,
								size = dpi(18)
							}
						}
					},
					{
						id = "speaker-slider",
						widget = widgets.scale,
						min = 0,
						max = 1,
						forced_width = dpi(330),
						forced_height = dpi(40),
						trough_margins = dpi(19),
						trough_color = beautiful.bg_urg,
						trough_shape = shape.rbar(),
						highlight_margins = dpi(19),
						highlight_shape = shape.rbar(),
						slider_color = beautiful.bg_alt,
						slider_border_color = beautiful.ac,
						slider_border_width = dpi(2),
						slider_margins = dpi(10),
						slider_shape = shape.rbar()
					},
					{
						id = "speaker-volume-label",
						widget = widgets.label,
						align = "center",
						font_size = 11
					}
				},
				{
					layout = wibox.layout.fixed.horizontal,
					fill_space = true,
					{
						id = "microphone-mute-button",
						widget = widgets.button,
						forced_width = dpi(40),
						forced_height = dpi(40),
						shape = shape.rrect(dpi(8)),
						fg_active = beautiful.fg_alt,
						bg_hover = beautiful.bg_urg,
						{
							widget = wibox.container.place,
							halign = "center",
							valign = "center",
							{
								id = "microphone-mute-icon",
								widget = widgets.icon,
								size = dpi(18)
							}
						}
					},
					{
						id = "microphone-slider",
						widget = widgets.scale,
						min = 0,
						max = 1,
						forced_width = dpi(330),
						forced_height = dpi(40),
						trough_margins = dpi(19),
						trough_color = beautiful.bg_urg,
						trough_shape = shape.rbar(),
						highlight_margins = dpi(19),
						highlight_shape = shape.rbar(),
						slider_color = beautiful.bg_alt,
						slider_border_color = beautiful.ac,
						slider_border_width = dpi(2),
						slider_margins = dpi(10),
						slider_shape = shape.rbar()
					},
					{
						id = "microphone-volume-label",
						widget = widgets.label,
						align = "center",
						font_size = 11
					}
				}
			}
		}
	}

	local wp = ret._private
	local speaker_mute_button = ret:get_children_by_id("speaker-mute-button")[1]
	local speaker_mute_icon = ret:get_children_by_id("speaker-mute-icon")[1]
	local speaker_slider = ret:get_children_by_id("speaker-slider")[1]
	local speaker_volume_label = ret:get_children_by_id("speaker-volume-label")[1]
	local microphone_mute_button = ret:get_children_by_id("microphone-mute-button")[1]
	local microphone_mute_icon = ret:get_children_by_id("microphone-mute-icon")[1]
	local microphone_slider = ret:get_children_by_id("microphone-slider")[1]
	local microphone_volume_label = ret:get_children_by_id("microphone-volume-label")[1]

	wp.on_speaker_mute_fg = function(_, fg)
		speaker_mute_icon:set_color(fg)
	end

	wp.on_speaker_slider_value = function(_, value)
		speaker:set_volume(value)
		speaker_volume_label:set_label(tostring(math.floor(value*100)) .. "%")
	end

	wp.on_speaker_volume = function()
		if not speaker_slider:is_dragging() then
			speaker_slider:set_value(speaker:get_volume())
		end
	end

	wp.on_speaker_mute = function()
		if speaker:get_mute() then
			speaker_mute_icon:set_icon(icons.speaker_mute)
			speaker_slider:set_highlight_color(beautiful.fg_alt)
			speaker_slider:set_slider_border_color(beautiful.fg_alt)
		else
			speaker_mute_icon:set_icon(icons.speaker)
			speaker_slider:set_highlight_color(beautiful.ac)
			speaker_slider:set_slider_border_color(beautiful.ac)
		end
	end

	wp.on_microphone_mute_fg = function(_, fg)
		microphone_mute_icon:set_color(fg)
	end

	wp.on_microphone_slider_value = function(_, value)
		microphone:set_volume(value)
		microphone_volume_label:set_label(tostring(math.floor(value*100)) .. "%")
	end

	wp.on_microphone_volume = function()
		if not microphone_slider:is_dragging() then
			microphone_slider:set_value(microphone:get_volume())
		end
	end

	wp.on_microphone_mute = function()
		if microphone:get_mute() then
			microphone_mute_icon:set_icon(icons.microphone_mute)
			microphone_slider:set_highlight_color(beautiful.fg_alt)
			microphone_slider:set_slider_border_color(beautiful.fg_alt)
		else
			microphone_mute_icon:set_icon(icons.microphone)
			microphone_slider:set_highlight_color(beautiful.ac)
			microphone_slider:set_slider_border_color(beautiful.ac)
		end
	end

	speaker_mute_button:connect_signal("property::fg", wp.on_speaker_mute_fg)
	speaker_slider:connect_signal("property::value", wp.on_speaker_slider_value)
	microphone_mute_button:connect_signal("property::fg", wp.on_microphone_mute_fg)
	microphone_slider:connect_signal("property::value", wp.on_microphone_slider_value)

	speaker.on_notify:connect(wp.on_speaker_volume, "volume", false)
	speaker.on_notify:connect(wp.on_speaker_mute, "mute", false)
	microphone.on_notify:connect(wp.on_microphone_volume, "volume", false)
	microphone.on_notify:connect(wp.on_microphone_mute, "mute", false)

	speaker_mute_button:buttons {
		awful.button({}, 1, nil, function()
			speaker:set_mute(not speaker:get_mute())
		end)
	}

	microphone_mute_button:buttons {
		awful.button({}, 1, nil, function()
			microphone:set_mute(not microphone:get_mute())
		end)
	}

	return ret
end

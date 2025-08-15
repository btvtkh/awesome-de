local awful = require("awful")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local widgets = require("widgets")
local shape = require("lib.shape")
local dpi = beautiful.xresources.apply_dpi
local icons = beautiful.icons
local capi = { screen = screen }
local Media = require("service.media")

local media_panel = {}

local function us_to_hms(us)
	if not us then return "" end

	local total_s = us/1000000
	local h = math.floor(total_s/3600)
	local remaining_s = total_s%3600
	local m = math.floor(remaining_s/60)
	local s = remaining_s%60

	return (h > 0 and string.format("%02d", math.floor(h)) .. ":" or "")
		.. string.format("%02d", math.floor(m)) .. ":"
		.. string.format("%02d", math.floor(s))
end

local function create_player_widget(self, name, player)
	local player_widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		forced_width = dpi(450),
		shape = shape.rrect(dpi(13)),
		{
			widget = wibox.container.margin,
			margins = dpi(5),
			{
				layout = wibox.layout.fixed.horizontal,
				fill_space = true,
				spacing = dpi(5),
				{
					widget = wibox.container.background,
					shape = shape.rrect(dpi(8)),
					{
						id = "preview-image",
						widget = wibox.widget.imagebox,
						forced_width = 120,
						forced_height = 120,
						resize = true,
						halign = "center",
						valign = "center",
						horizontal_fit_policy = "cover",
						vertical_fit_policy = "cover",
						stylesheet = "* { color: " .. beautiful.fg_alt .. "; }"
					}
				},
				{
					widget = wibox.container.margin,
					margins = dpi(10),
					{
						layout = wibox.layout.align.vertical,
						{
							layout = wibox.layout.fixed.vertical,
							{
								layout = wibox.layout.fixed.horizontal,
								{
									id = "title-label",
									widget = widgets.label,
									forced_width = dpi(220),
									forced_height = dpi(25),
									font_size = 12,
								}
							},
							{
								layout = wibox.layout.fixed.horizontal,
								{
									id = "artist-label",
									widget = widgets.label,
									forced_width = dpi(200),
									forced_height = dpi(20),
									font_size = 10,
									alpha = 70
								}
							}
						},
						nil,
						{
							layout = wibox.layout.fixed.vertical,
							{
								layout = wibox.layout.flex.horizontal,
								{
									widget = wibox.container.place,
									halign = "left",
									{
										widget = wibox.container.background,
										fg = beautiful.fg_alt,
										{
											id = "position-label",
											widget = widgets.label,
											font_size = 9
										}
									}
								},
								{
									widget = wibox.container.place,
									halign = "center",
									{
										layout = wibox.layout.fixed.horizontal,
										spacing = dpi(5),
										{
											id = "previous-button",
											widget = widgets.button,
											forced_width = dpi(25),
											forced_height = dpi(25),
											shape = shape.rrect(dpi(6)),
											bg_hover = beautiful.bg_urg,
											fg_active = beautiful.fg_alt,
											{
												widget = wibox.container.place,
												halign = "center",
												valign = "center",
												{
													id = "previous-icon",
													widget = widgets.icon,
													size = dpi(18),
													icon = icons.skip_back
												}
											}
										},
										{
											id = "play-button",
											widget = widgets.button,
											forced_width = dpi(25),
											forced_height = dpi(25),
											shape = shape.rrect(dpi(6)),
											bg_hover = beautiful.bg_urg,
											fg_active = beautiful.fg_alt,
											{
												widget = wibox.container.place,
												halign = "center",
												valign = "center",
												{
													id = "play-icon",
													widget = widgets.icon,
													size = dpi(18)
												}
											}
										},
										{
											id = "next-button",
											widget = widgets.button,
											forced_width = dpi(25),
											forced_height = dpi(25),
											shape = shape.rrect(dpi(6)),
											bg_hover = beautiful.bg_urg,
											fg_active = beautiful.fg_alt,
											{
												widget = wibox.container.place,
												halign = "center",
												valign = "center",
												{
													id = "next-icon",
													widget = widgets.icon,
													size = dpi(18),
													icon = icons.skip_forward
												}
											}
										}
									}
								},
								{
									widget = wibox.container.place,
									halign = "right",
									{
										widget = wibox.container.background,
										fg = beautiful.fg_alt,
										{
											id = "length-label",
											widget = widgets.label,
											font_size = 9
										}
									}
								}
							},
							{
								id = "timeline-slider",
								widget = widgets.scale,
								forced_height = dpi(20),
								trough_margins = dpi(9),
								trough_color = beautiful.bg_urg,
								trough_shape = shape.rbar(),
								highlight_margins = dpi(9),
								highlight_color = beautiful.ac,
								highlight_shape = shape.rbar(),
								slider_margins = dpi(4),
								slider_border_width = dpi(2),
								slider_color = beautiful.bg_alt,
								slider_border_color = beautiful.ac,
								slider_shape = shape.rbar()
							}
						}
					}
				}
			}
		}
	}

	local wp = player_widget._private
	local preview_image = player_widget:get_children_by_id("preview-image")[1]
	local title_label = player_widget:get_children_by_id("title-label")[1]
	local artist_label = player_widget:get_children_by_id("artist-label")[1]
	local previous_button = player_widget:get_children_by_id("previous-button")[1]
	local previous_icon = player_widget:get_children_by_id("previous-icon")[1]
	local play_button = player_widget:get_children_by_id("play-button")[1]
	local play_icon = player_widget:get_children_by_id("play-icon")[1]
	local next_button = player_widget:get_children_by_id("next-button")[1]
	local next_icon = player_widget:get_children_by_id("next-icon")[1]
	local position_label = player_widget:get_children_by_id("position-label")[1]
	local length_label = player_widget:get_children_by_id("length-label")[1]
	local timeline_slider = player_widget:get_children_by_id("timeline-slider")[1]

	wp.player_name = name

	wp.timeline_timer = gtimer {
		timeout = 1,
		autostart = false,
		single_shot = false,
		call_now = false,
		callback = function()
			local position = player:get_position() or 0
			local length = player:get_metadata():get_length() or 1

			position_label:set_label(us_to_hms(position))

			if not timeline_slider:get_is_dragging() then
				timeline_slider:set_value(position/length*100)
			end

			if wp.timeline_timer then
				wp.timeline_timer:again()
			end
		end
	}

	wp.on_previous_button_fg = function(_, fg)
		previous_icon:set_color(fg)
	end

	wp.on_play_button_fg = function(_, fg)
		play_icon:set_color(fg)
	end

	wp.on_next_button_fg = function(_, fg)
		next_icon:set_color(fg)
	end

	wp.on_metadata = function(_, metadata)
		local art_url = metadata:get_art_url()
		preview_image:set_image(art_url ~= nil and art_url ~= ""
			and string.gsub(art_url, "^file://", "") or icons.music)

		local position = player:get_position() or 0
		local length = metadata:get_length() or 1
		position_label:set_label(us_to_hms(position))
		length_label:set_label(us_to_hms(length))

		if not timeline_slider:get_is_dragging() then
			timeline_slider:set_value(position/length*100)
		end

		local title = metadata:get_title()
		title_label:set_label(title ~= nil and title ~= "" and title or "untitled")

		local artist = metadata:get_artist()
		local artist_string = artist ~= nil and artist ~= {} and tostring(table.unpack(artist)) or nil
		artist_label:set_label(artist_string ~= nil and artist_string ~= "" and artist_string or "unknown artist")
	end

	wp.on_playback_status = function(_, status)
		play_icon:set_icon(status == Media.PlaybackStatus.PLAYING and icons.pause or icons.play)

		if self.visible then
			wp.timeline_timer:stop()
			if status == Media.PlaybackStatus.PLAYING then
				wp.timeline_timer:start()
			end
		end
	end

	wp.on_seeked = function(_, pos)
		local position = pos or 0
		local length = player:get_metadata():get_length() or 1
		position_label:set_label(us_to_hms(position))
		length_label:set_label(us_to_hms(length))

		if not timeline_slider:get_is_dragging() then
			timeline_slider:set_value(position/length*100)
		end

		if self.visible then
			wp.timeline_timer:stop()
			if player:get_playback_status() == Media.PlaybackStatus.PLAYING then
				wp.timeline_timer:start()
			end
		end
	end

	wp.on_timeline_slider_dragging_stopped = function()
		player:set_position(
			player:get_metadata():get_track_id(),
			player:get_metadata():get_length() * timeline_slider:get_value()/100
		)
	end

	previous_button:connect_signal("property::fg", wp.on_previous_button_fg)
	play_button:connect_signal("property::fg", wp.on_play_button_fg)
	next_button:connect_signal("property::fg", wp.on_next_button_fg)

	player:connect_signal("property::metadata", wp.on_metadata)
	player:connect_signal("property::playback-status", wp.on_playback_status)
	player:connect_signal("seeked", wp.on_seeked)

	local art_url = player:get_metadata():get_art_url()
	preview_image:set_image(art_url ~= nil and art_url ~= ""
		and string.gsub(art_url, "^file://", "") or icons.music)

	local title = player:get_metadata():get_title()
	title_label:set_label(title ~= nil and title ~= "" and title or "untitled")

	local artist = player:get_metadata():get_artist()
	local artist_string = artist ~= nil and artist ~= {} and tostring(table.unpack(artist)) or nil
	artist_label:set_label(artist_string ~= nil and artist_string ~= "" and artist_string or "unknown artist")

	local position = player:get_position() or 0
	local length = player:get_metadata():get_length() or 1
	position_label:set_label(us_to_hms(position))
	length_label:set_label(us_to_hms(length))
	timeline_slider:set_value(position/length*100)

	play_icon:set_icon(player:get_playback_status() == Media.PlaybackStatus.PLAYING and icons.pause or icons.play)

	previous_button:buttons {
		awful.button({}, 1, nil, function()
			player:previous()
		end)
	}

	play_button:buttons {
		awful.button({}, 1, nil, function()
			player:play_pause()
		end)
	}

	next_button:buttons {
		awful.button({}, 1, nil, function()
			player:next()
		end)
	}

	timeline_slider:connect_signal("dragging-stopped", wp.on_timeline_slider_dragging_stopped)

	if self.visible then
		if player:get_playback_status() == Media.PlaybackStatus.PLAYING then
			wp.timeline_timer:start()
		end
	end

	return player_widget
end

function media_panel:show()
	if self.visible then return end
	local media = Media.get_default()
	local players_layout = self.widget:get_children_by_id("players-layout")[1]
	for _, player_widget in ipairs(players_layout.children) do
		local pp = player_widget._private
		if pp.player_name then
			local player = media:get_player(pp.player_name)
			local position_label = player_widget:get_children_by_id("position-label")[1]
			local length_label = player_widget:get_children_by_id("length-label")[1]
			local timeline_slider = player_widget:get_children_by_id("timeline-slider")[1]

			local position = player:get_position() or 0
			local length = player:get_metadata():get_length() or 1
			position_label:set_label(us_to_hms(position))
			length_label:set_label(us_to_hms(length))
			timeline_slider:set_value(position/length*100)

			if player:get_playback_status() == Media.PlaybackStatus.PLAYING then
				pp.timeline_timer:start()
			end
		end
	end
	self.visible = true
	self:emit_signal("property::visible", self.visible)
end

function media_panel:hide()
	if not self.visible then return end
	local players_layout = self.widget:get_children_by_id("players-layout")[1]
	for _, player_widget in ipairs(players_layout.children) do
		local pp = player_widget._private
		if pp.player_name then
			pp.timeline_timer:stop()
		end
	end
	self.visible = false
	self:emit_signal("property::visible", self.visible)
end

function media_panel:toggle()
	if not self.visible then
		self:show()
	else
		self:hide()
	end
end

local function new()
	local media = Media.get_default()

	local ret = awful.popup {
		visible = false,
		ontop = true,
		type = "dock",
		screen = capi.screen.primary,
		placement = function(d)
			awful.placement.bottom_right(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end,
		bg = "#00000000",
		widget = {
			widget = wibox.container.background,
			bg = beautiful.bg,
			border_width = beautiful.border_width,
			border_color = beautiful.border_color_normal,
			shape = shape.rrect(dpi(23)),
			{
				widget = wibox.container.margin,
				margins = dpi(10),
				{
					layout = wibox.layout.stack,
					{
						id = "players-layout",
						layout = wibox.layout.stack,
						top_only = true,
						{
							widget = widgets.label,
							forced_width = dpi(300),
							forced_height = dpi(100),
							fg = beautiful.fg_alt,
							align = "center",
							font_size = 17,
							label = "Nothing playing"
						}
					},
					{
						id = "players-switcher",
						widget = wibox.container.place,
						visible = false,
						halign = "right",
						valign = "top",
						{
							widget = wibox.container.margin,
							margins = dpi(6),
							{
								layout = wibox.layout.fixed.horizontal,
								spacing = dpi(3),
								{
									id = "previous-player-button",
									widget = widgets.button,
									forced_width = dpi(20),
									forced_height = dpi(20),
									shape = shape.rrect(6),
									bg_normal = beautiful.bg_urg,
									bg_hover = beautiful.ac,
									bg_active = beautiful.fg_alt,
									fg_normal = beautiful.fg,
									fg_hover = beautiful.bg,
									fg_active = beautiful.bg,
									{
										widget = wibox.container.place,
										halign = "center",
										valign = "center",
										{
											id = "previous-player-icon",
											widget = widgets.icon,
											size = dpi(14),
											icon = icons.chevron_left
										}
									}
								},
								{
									id = "next-player-button",
									widget = widgets.button,
									forced_width = dpi(20),
									forced_height = dpi(20),
									shape = shape.rrect(6),
									bg_normal = beautiful.bg_urg,
									bg_hover = beautiful.ac,
									bg_active = beautiful.fg_alt,
									fg_normal = beautiful.fg,
									fg_hover = beautiful.bg,
									fg_active = beautiful.bg,
									{
										widget = wibox.container.place,
										halign = "center",
										valign = "center",
										{
											id = "next-player-icon",
											widget = widgets.icon,
											size = dpi(14),
											icon = icons.chevron_right
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

	gtable.crush(ret, media_panel, true)
	local wp = ret._private
	local players_layout = ret.widget:get_children_by_id("players-layout")[1]
	local players_switcher = ret.widget:get_children_by_id("players-switcher")[1]
	local previous_player_button = ret.widget:get_children_by_id("previous-player-button")[1]
	local previous_player_icon = ret.widget:get_children_by_id("previous-player-icon")[1]
	local next_player_button = ret.widget:get_children_by_id("next-player-button")[1]
	local next_player_icon = ret.widget:get_children_by_id("next-player-icon")[1]

	wp.on_previous_player_button_fg = function(_, fg)
		previous_player_icon:set_color(fg)
	end

	wp.on_next_player_button_fg = function(_, fg)
		next_player_icon:set_color(fg)
	end

	wp.on_player_added = function(_, name, player)
		if not players_layout.children[1]._private.player_name then
			players_layout:remove(1)
		end

		players_layout:insert(1, create_player_widget(ret, name, player))

		if #players_layout.children > 1 then
			players_switcher:set_visible(true)
		end
	end

	wp.on_player_removed = function(_, name, player)
		for _, player_widget in ipairs(players_layout.children) do
			if player_widget._private.player_name == name then
				player:disconnect_signal("property::metadata", player_widget._private.on_metadata)
				player:disconnect_signal("property::playback-status", player_widget._private.on_playback_status)
				player:disconnect_signal("seeked", player_widget._private.on_seeked)
				player_widget._private.timeline_timer:stop()
				player_widget._private.timeline_timer = nil

				players_layout:remove_widgets(player_widget)

				if #players_layout.children == 1 then
					players_switcher:set_visible(false)
				elseif #players_layout.children == 0 then
					players_layout:add({
						widget = widgets.label,
						forced_width = dpi(300),
						forced_height = dpi(100),
						fg = beautiful.fg_alt,
						align = "center",
						font_size = 17,
						label = "Nothing playing"
					})
				end
			end
		end
	end

	previous_player_button:connect_signal("property::fg", wp.on_previous_player_button_fg)
	next_player_button:connect_signal("property::fg", wp.on_next_player_button_fg)

	media:connect_signal("player-added", wp.on_player_added)
	media:connect_signal("player-removed", wp.on_player_removed)

	for name, player in pairs(media:get_players()) do
		wp.on_player_added(nil, name, player)
	end

	previous_player_button:buttons {
		awful.button({}, 1, nil, function()
			if #players_layout.children > 1 then
				players_layout:add(players_layout.children[1])
				players_layout:remove(1)
			end
		end)
	}

	next_player_button:buttons {
		awful.button({}, 1, nil, function()
			if #players_layout.children > 1 then
				players_layout:raise(#players_layout.children)
			end
		end)
	}

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

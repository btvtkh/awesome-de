local beautiful = require("beautiful")
local gfs = require("gears.filesystem")
local dpi = beautiful.xresources.apply_dpi

local theme_name = "astel"
local theme_path = gfs.get_configuration_dir() .. "/themes/" .. theme_name .. "/"
local icons_path = theme_path .. "icons/"

local theme = {}

theme.font_name = "Geist"
theme.font_size = 9
theme.font = theme.font_name.. tostring(theme.font_size)

theme.icons = {
	power = icons_path .. "power.svg",
	refresh = icons_path .. "refresh-cw.svg",
	log_out = icons_path .. "log-out.svg",
	cross = icons_path .. "x.svg",
	menu = icons_path .. "menu.svg",
	chevron_down = icons_path .. "chevron-down.svg",
	chevron_left = icons_path .. "chevron-left.svg",
	chevron_right = icons_path .. "chevron-right.svg",
	chevron_up = icons_path .. "chevron-up.svg",
	search = icons_path .. "search.svg",
	settings = icons_path .. "settings.svg",
	message = icons_path .. "message-circle.svg",
	music = icons_path .. "music.svg",
	home = icons_path .. "home.svg",
	image = icons_path .. "image.svg",
	speaker = icons_path .. "volume-2.svg",
	speaker_mute = icons_path .. "volume-x.svg",
	microphone = icons_path .. "mic.svg",
	microphone_mute = icons_path .. "mic-off.svg",
	wifi = icons_path .. "wifi.svg",
	bluetooth = icons_path .. "bluetooth.svg",
	bell = icons_path .. "bell.svg",
	bell_off = icons_path .. "bell-off.svg",
	eye = icons_path .. "eye.svg",
	eye_off = icons_path .. "eye-off.svg",
	loader = icons_path .. "loader.svg",
	maximize = icons_path .. "maximize.svg",
	minimize = icons_path .. "minimize.svg",
	dash = icons_path .. "minus.svg",
	pause = icons_path .. "pause.svg",
	play = icons_path .. "play.svg",
	again = icons_path .. "repeat.svg",
	shuffle = icons_path .. "shuffle.svg",
	skip_back = icons_path .. "skip-back.svg",
	skip_forward = icons_path .. "skip-forward.svg",
	trash = icons_path .. "trash-2.svg",
	grid = icons_path .. "grid.svg"
}

theme.red = "#F9AEAE"
theme.green = "#B3F9B3"
theme.yellow = "#F9F7B1"
theme.blue = "#A8C7FA"
theme.magenta = "#DFB6F9"
theme.cyan = "#B6F4F9"
theme.orange = "#F9C9B1"
theme.bg = "#121212"
theme.bg_alt = "#212121"
theme.bg_urg = "#414141"
theme.fg_alt = "#767676"
theme.fg = "#E6E6E6"
theme.ac = theme.blue

theme.rounded = true

theme.border_width = dpi(1)
theme.separator_thickness = dpi(1)
theme.useless_gap = dpi(5)

theme.separator_color = theme.bg_urg
theme.bg_normal = theme.bg
theme.fg_normal = theme.fg
theme.border_color_normal = theme.bg_urg
theme.border_color_active = theme.ac

theme.titlebar_bg_normal = theme.bg
theme.titlebar_bg_focus = theme.bg
theme.titlebar_bg_urgent = theme.bg
theme.titlebar_fg_normal = theme.fg_alt
theme.titlebar_fg_focus = theme.fg
theme.titlebar_fg_urgent = theme.red

theme.notification_margins = dpi(30)
theme.notification_spacing = dpi(10)
theme.notification_timeout = 5

theme.menu_submenu = theme.icons.chevron_right
theme.menu_bg_normal = theme.bg
theme.menu_fg_normal = theme.fg
theme.menu_bg_focus = theme.ac
theme.menu_fg_focus = theme.bg
theme.menu_border_width = theme.border_width
theme.menu_border_color = theme.border_color

theme.systray_icon_spacing = dpi(6)
theme.bg_systray = theme.bg_alt

return theme

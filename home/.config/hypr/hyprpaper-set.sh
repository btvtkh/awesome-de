#!/bin/bash

selected_file=$(zenity --file-selection --title="Select Wallpaper" --file-filter='Image files (png jpg jpeg) | *.png *.jpg *.jpeg')

if [[ -n "$selected_file" ]]; then
	config_file="$HOME/.config/hypr/hyprpaper.conf"
	echo "preload = $selected_file" > "$config_file"
	echo "wallpaper = ,$selected_file" >> "$config_file"
	killall hyprpaper 2>/dev/null
	hyprpaper > /dev/null 2>&1 &
fi
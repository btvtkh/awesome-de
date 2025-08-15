#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# PS1='\[\e[96m\]\u\[\e[39m\]@\[\e[96m\]\H\[\e[39m\]: \[\e[95m\]\w\[\e[39m\] $ '
PS1=' \[\e[95m\]\w\[\e[39m\] $ '

if [ -z "$DISPLAY" ]; then
	mkdir -p ~/.cache

	if [ "$XDG_VTNR" -eq 1 ]; then
		exec startx
	elif [ "$XDG_VTNR" -eq 2 ]; then
		exec hyprland > ~/.cache/hyprland.log 2>&1
	fi
fi

alias ls='ls --color=auto'
#!/usr/bin/env bash
# Set resolution
xrandr -s 1920x1080 &

# Disable monitor powersaving
xset s off &
xset -dpms &

# Launch Statusbar
slstatus &

# polkit
/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &

# background
feh --randomize --bg-fill ~/.config/backgrounds/* &
#feh --randomize --bg-scale ~/.config/backgrounds/* &



# compositor
picom --animations -b &

# sxhkd
# (re)load sxhkd for keybinds
if hash sxhkd >/dev/null 2>&1; then
	pkill sxhkd
	sleep 0.5
	sxhkd -c "$HOME/.config/suckless/sxhkd/sxhkdrc" &
fi

# Notifications
dunst &



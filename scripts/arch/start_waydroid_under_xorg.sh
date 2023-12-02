#!/bin/bash
weston --xwayland &
export WAYLAND_DISPLAY=wayland-1              
sleep 2
waydroid show-full-ui &
exit 0

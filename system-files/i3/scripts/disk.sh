#!/bin/bash
killall espeak
if [ "$(neofetch disk)" = "" ]; then
   echo "Failed to obtain disk usage" | espeak -z 1>&2
exit 1
fi
neofetch disk | espeak -z
exit 0

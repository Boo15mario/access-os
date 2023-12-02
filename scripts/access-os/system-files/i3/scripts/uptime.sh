#!/bin/bash
killall espeak
if [ "$(neofetch uptime)" = "" ]; then
   echo "Failed to obtain system uptime." | espeak -z 1>&2
exit 1
fi
neofetch uptime | espeak -z
exit 0

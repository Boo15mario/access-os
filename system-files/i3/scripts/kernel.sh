#!/bin/bash
killall espeak
if [ "$(neofetch kernel)" = "" ]; then
   echo "Failed to obtain kernel version." | espeak -z 1>&2
exit 1
fi
neofetch kernel | espeak -z
exit 0

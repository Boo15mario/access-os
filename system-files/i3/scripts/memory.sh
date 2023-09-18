#!/bin/bash
killall espeak
if [ "$(neofetch memory)" = "" ]; then
   echo "Failed to obtain memory." | espeak -z 1>&2
exit 1
fi
neofetch memory | espeak -z
exit 0

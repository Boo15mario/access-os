#!/bin/bash
killall espeak
if [ "$(neofetch battery)" = "" ]; then
   echo "Failed to obtain battery." | espeak -z 1>&2
exit 1
fi
neofetch battery | espeak -z
exit 0

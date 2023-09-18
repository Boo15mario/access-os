#!/bin/bash
killall espeak
if [ "$(progress)" = "" ]; then
   echo "Failed to obtain file operations." | espeak -z 1>&2
exit 1
fi
progress | espeak -z
exit 0

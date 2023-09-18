#!/bin/bash
killall espeak
if [ "$(neofetch packages)" = "" ]; then
   echo "Failed to obtain number of installed packages." | espeak -z 1>&2
exit 1
fi
neofetch packages | espeak -z
exit 0

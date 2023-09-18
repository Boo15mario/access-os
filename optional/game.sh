#!/bin/bash
clear

if [ "$(id -u)" = "0" ]; then
   echo "Please run as non-root user" 1>&2
exit 1
fi
echo "This will install several games."
read -p "Press enter to continue, control+c to abort."
paru --noconfirm -S open-hexagon-git itch-bin 



exit 0

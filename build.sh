#!/bin/bash
if [ "$(id -u)" != "0" ];then
echo "Error: you must run this script as root" 1>&2
exit 1
fi
if [ "$SUDO_USER ];then
mkarchiso -v -w /tmp/builds/work -o $SUDO_HOME/builds/out ./iso/access-os/releng/
else
mkarchiso -v -w /tmp/builds/work -o $HOME/builds/out ./iso/access-os/releng/
fi


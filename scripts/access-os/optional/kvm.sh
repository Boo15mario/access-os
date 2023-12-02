#!/bin/bash
clear

if [ "$(id -u)" = "0" ]; then
   echo "Please run as non-root user" 1>&2
exit 1
fi

export NEWT_COLORS="
root=,red
window=,black
shadow=,blue
border=blue,blue
title=blue,black
textbox=white,black
radiolist=black,black
label=black,white
checkbox=black,white
compactbutton=black,white
button=black,blue"

whiptail --title "CONFIRMATION" --yesno "This is going to install virt manager with the virt win drivers to be used with Windows VMS." 40 80 
if [[ $? -eq 0 ]]; then 
  whiptail --title "MESSAGE" --msgbox "ENTER THE SUDO PASSWORD WHEN PROMPTED" 8 78 

paru --needed --noconfirm -S virtio-win qemu-full virt-manager

elif [[ $? -eq 1 ]]; then 
  whiptail --title "MESSAGE" --msgbox "Installation of VM system will not continue." 8 78 
fi
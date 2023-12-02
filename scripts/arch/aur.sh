#! /bin/bash
echo "enter your password and select yes to finish installing when prompted"
sudo pacman --noconfirm --needed -Sy rust git
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

exit 0














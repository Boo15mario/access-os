#!/bin/bash
clear
echo "Access OS 0.2 installer"
sleep 0.4
if [ "$(id -u)" = "0" ]; then
   echo "Error: you cannot run this script as root" 1>&2
exit 1
fi
echo "Welcome to the access-os installer. Please ensure that you have a working internet connection and that pacman is configured correctly. Here are a few things to keep in mind during the installation."
echo "First and formost, Access OS is still in early development stages, there are a few things that may still be broken that we still need to work out. With that being said, expect a lot of changes to the installation script, especially during the first year of development."
echo "In order for the installation to complete, you must be running this script as a regular user. Note that because the way this script is set up, sudo privileges will be required several times during this installation, so also make sure that you have installed the sudo package, added yourself to the wheel group and edit the sudoers file to allow wheel access to sudo."
echo "This script must replace your existing pacman configuration in /etc/pacman.conf. A backup will be made so you will not lose your changes, but they will need to be merged into the new pacman.conf file."
read -p "If your system is configured correctly for install, press enter to continue. To cancel and make changes to the configuration, press control+c."
echo "Checking for updates. Please enter sudo password if asked."
sudo pacman -Syyu --noconfirm
if [ $? -eq 0 ] 
then 
  echo "Installed all updates. Proceeding to next step." 
else 
  read -p "Errors occured. Failed to check for updates. Command returned exit code $?. You may still continue with the installation, but it is not recommended. Continue anyway. Press enter to continue, or control+c to abort."
  fi
echo "Installing curl, (required to pull down access-os files). The installation will be skipped if already installed. Please enter sudo password if asked."
sudo pacman -S --noconfirm --needed curl
echo "Replacing the pacman configuration"
cd /etc
sudo mv -v pacman.conf pacman.conf.old
sudo curl -O "https://boo15mario.boo/scripts/access-os/system-files/pacman.conf"
if [ "$?" != "0" ]; then
echo "Error: Server is down." 1>&2
exit 1
fi
sudo chmod 644 pacman.conf
echo "Another pacman sync is required to continue"
sudo pacman -Syy
echo "Downloading Access OS package list..."
cd ~
curl -O "https://boo15mario.boo/scripts/access-os/pkglist.txt"
if [ $? -eq 0 ] 
then 
  echo "Successfully created file" 
else 
  echo "The installation of access-os failed. Reason: Failed to retrieve package list. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
echo "Install graphics drivers for Nvidia hardware? \(y/n\)"
while true; do
read yn
case $yn in
[yY] )
export nvidia=true
break
;;
[nN] )
export nvidia=false
break
;;
*)
echo "Invalid option \"$yn\" type y or n"
;;
esac
done
echo "Installing packages..."
sudo pacman --ask 4 -S --noconfirm --needed - < pkglist.txt
if [ $? -eq 0 ] 
then 
  echo "Successfully installed all required packages." 
else 
  echo "The installation of access-os failed. Reason: Failed to install all required packages. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
if [ "$nvidia" = "true" ]; then
echo -e "Installing Nvidia graphics drivers\nThis may take some time\n"
sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils
if [ $? -eq 0 ] 
then 
  echo "Successfully installed Nvidia drivers." 
else 
  echo "The installation of access-os failed. Reason: Failed to install all required packages. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
fi
echo "Running fenrir script to allow espeakup and fenrir to work. This script will be ran twice, once as $USER, and a second time as root. Sudo privileges will be required to run as root. Please enter the sudo password if prompted."
/usr/share/fenrirscreenreader/tools/configure_pipewire.sh
sudo /usr/share/fenrirscreenreader/tools/configure_pipewire.sh
cd /etc
mkdir -p -v lightdm
cd lightdm
sudo curl -O "https://boo15mario.boo/scripts/access-os/system-files/lightdm.conf"
if [ $? -eq 0 ] 
then 
  echo "Successfully downloaded file" 
else 
  echo "The installation of access-os failed. Reason: Failed to download lightdm config. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
sudo chmod 644 lightdm.conf
echo "Enabling services. Sudo privileges are required to perform this action. Please enter the sudo password if prompted."
sudo systemctl enable NetworkManager.service
if [ $? -eq 0 ] 
then 
  echo "Successfully enabled service" 
else 
  echo "Failed to enable NetworkManager. It will need to be manually enabled later."
fi
sudo systemctl enable ntpd.service
if [ $? -eq 0 ] 
then 
  echo "Successfully enabled service" 
else 
  echo "Failed to enable ntpd. It will need to be manually enabled later."
fi
sudo systemctl enable cronie.service
if [ $? -eq 0 ] 
then 
  echo "Successfully enabled service" 
else 
  echo "Failed to enable chronie. It will need to be manually enabled later."
fi
sudo systemctl enable bluetooth.service
if [ $? -eq 0 ] 
then 
  echo "Successfully enabled service" 
else 
  echo "Failed to enable bluetooth. It will need to be manually enabled later."
fi
sudo systemctl enable cups.service
if [ $? -eq 0 ] 
then 
  echo "Successfully enabled service" 
else 
  echo "Failed to enable cups. It will need to be manually enabled later."
fi
sudo systemctl enable lightdm.service
if [ $? -eq 0 ] 
then 
  echo "Successfully enabled service" 
else 
  echo "Failed to enable lightdm. It will need to be manually enabled later."
fi
echo "Getting access-OS scripts"
cd
mkdir .access-os
cd .access-os
mkdir -p -v scripts
cd scripts
curl -O "https://boo15mario.boo/scripts/access-os/i3scripts.txt"
if [ $? -eq 0 ] 
then 
  echo "Successfully downloaded file" 
else 
  echo "The installation of access-os failed. Reason: Failed to download Access OS scripts. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
wget -i i3scripts.txt
if [ $? -eq 0 ] 
then 
  echo "Successfully downloaded file" 
else 
  echo "The installation of access-os failed. Reason: Failed to download Access-OS scripts. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
chmod +x *
if [ $? -eq 0 ] 
then 
  echo "Successfully downloaded file" 
else 
  echo "Failed to make files executable. The config should still work, but certain functionality will not be available until you use chmod on the files in $HOME/.access-os/scripts. Command returned exit code $?."
fi
cd ..
mkdir sounds
cd sounds
curl -O "https://boo15mario.boo/scripts/access-os/i3sounds.txt"
if [ $? -eq 0 ] 
then 
  echo "Successfully downloaded file" 
else 
  echo "The installation of access-os failed. Reason: Failed to download Access-OS scripts. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
wget -i i3sounds.txt
if [ $? -eq 0 ] 
then 
  echo "Successfully downloaded file" 
else 
  echo "The installation of access-os failed. Reason: Failed to download Access-OS scripts. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
cd
echo "Installing i3 config..."
mkdir -p -v .config
cd .config
rm -r i3
mkdir -p -v i3
cd i3
curl -O "https://boo15mario.boo/scripts/access-os/system-files/i3/config"
if [ $? -eq 0 ] 
then 
  echo "Successfully downloaded file" 
else 
  echo "The installation of access-os failed. Reason: Failed to download i3 config. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
cd
echo "Downloading .profile"
curl -O "https://boo15mario.boo/scripts/access-os/system-files/profile"
if [ $? -eq 0 ] 
then 
  echo "Successfully created file" 
else 
  echo "The installation of access-os failed. Reason: Failed to retrieve .profile. Command returned exit code $?. Please try the installation again." >&2
  exit 1
fi
mv -v profile .profile
echo "Making a few more directories..."
mkdir -p -v Desktop
mkdir -p -v Documents
mkdir -p -v Downloads
mkdir -p -v Music
mkdir -p -v mnt
mkdir -p -v Pictures
mkdir -p -v Screenshots
mkdir -p -v Videos
sleep 2
#echo "installing oh my bash"
#sleep 2
#bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
#sleep 4
echo "Cleaning up..."
rm -v ~/.access-os/sounds/i3sounds.txt
rm -v ~/access-os/scripts/i3scripts.txt
rm -v pkglist.txt
echo "The installation of Access OS 0.2 has completed successfully. You may now reboot."
echo "Exiting..."
exit 0

#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "Error: You must run this script as root." 1>&2
exit 1
fi
echo "Testing connection to boo15mario.boo"
curl -s -O "https://boo15mario.boo/index.html"
if [ $? != 0 ]; then
echo "Error: Failed to connect to boo15mario.boo. The server may be down. Please check your internet connection or try again in a few minutes"
exit 1
else
rm index.html
fi
function createmenu
{
if [ -z $tempdir ];then
export pathcomp=`mktemp -u --suffix a|tr / "\\n"`
export temppath=`echo $pathcomp|tr / "\\n"|grep -nw tmp.|cut -f 1 -d :`
export tempdir=`echo $pathcomp|head -n $(($temppath-1))|tr "\\n" /`
fi
export menudesc=`stty -a|grep rows|cut -f 2-6 -d \;|cut -f 3,5,8 -d \ |tr \; \ |sed s/"  "/" "/|sed s/"  "/" "/`
cat $1|tail -n 1 >$tempdir/itemlist
export numitems=`cat $tempdir/itemlist|wc -l`
export linecounter=1
while true;do
cat $tempdir/itemlist|head -n $linecounter|tail -n 1 >>$tempdir/items
export linecounter=$(($linecounter+1))
if [ $linecounter -gt $numitems ];then
break
else
continue
fi
done

echo whiptail --menu --nocancel `cat $1|head -n 1` `echo -n $menudesc` `cat $1|tail -n 1`>$tempdir/menu
chmod 755 $tempdir/menu
$tempdir/menu 2>$tempdir/choice
export choice=`cat $tempdir/choice|cut -f 2 -d \;`
cat $tempdir/itemlist|sed s/"\"\ /\\n/g"|sed "s/\"//g" > $tempdir/items
export testnum=`cat $tempdir/items|grep -nw $choice|cut -f 1 -d :|head -n 1`
export itemname=`cat $tempdir/items|head -n $(($testnum+1))|tail -n 1`
rm $tempdir/choice $tempdir/menu $tempdir/itemlist $tempdir/items $tempdir/dynmenu > /dev/null 2>/dev/null
clear
}
function createdynamicmenu
{
if [ -z $tempdir ];then
export pathcomp=`mktemp -u --suffix a|tr / "\\n"`
export temppath=`echo $pathcomp|tr / "\\n"|grep -nw tmp.|cut -f 1 -d :`
export tempdir=`echo $pathcomp|head -n $(($temppath-1))|tr "\\n" /`
fi
$@>$tempdir/itemlist
export numitems=`cat $tempdir/itemlist|wc -l`
export counter=1
if [ -f $tempdir/menutitle ];then
export title=`cat $tempdir/menutitle|head -n 1`
else
export title="$numitems items available"
fi
echo \"$title\" > $tempdir/dynmenu
while true;do
export ltr=`cat $tempdir/itemlist|head -n $counter|tail -n 1|cut -c 1`
export item=`cat $tempdir/itemlist|head -n $counter|tail -n 1`
echo -n \" >> $tempdir/dynmenu
if [ $ltr = \" ];then
export ltr="|"
fi
echo -n $ltr\;$counter >> $tempdir/dynmenu
echo -n \"\  >>$tempdir/dynmenu
echo -n \" >> $tempdir/dynmenu
if echo $item|grep -q \";then
export item=`echo $item|sed "s/\"/\|/g"`
fi
echo -n $item >> $tempdir/dynmenu
echo -n \"\  >>$tempdir/dynmenu
export counter=$(($counter+1))
if [ $counter -gt $numitems ];then
break
else
continue
fi
done
createmenu $tempdir/dynmenu
rm $tempdir/menutitle > /dev/null 2>/dev/null
}
clear
echo "Syncing package databases"
pacman -Sy
echo "Ensuring that the following packages are installed:"
echo "Reflector"
echo "whiptail"
echo "arch-install-scripts"
echo "curl"
while true; do
pacman -S --needed --noconfirm reflector libnewt arch-install-scripts curl
if [ $? = 0 ]; then
break
else
echo "Error: packages failed to install. Retrying. Press control+c to abort."
fi
done
clear
echo "Select the disk where archlinux should be installed" > $tempdir/menutitle
read -t 2
clear
touch /tmp/disks
chown $USER /tmp/disks
touch /tmp/disk
chown $USER /tmp/disk
sh -c 'echo -n "print devices"|parted|grep /dev|grep \(>/tmp/disk;cat /tmp/disk|tr \  \:>/tmp/disks;rm /tmp/disk'
echo "Cancel installation" >> /tmp/disks
createdynamicmenu cat /tmp/disks
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
sleep 0.1
export installdisk=`echo $itemname|cut -f 1 -d \:|cut -f 2 -d \"`
clear
echo "Disk $installdisk selected. Is this correct? (y/n) "
while true; do

read -s -n 1 yn
case $yn in 
	[yY] )
clear
echo "Confirm $installdisk"
sleep 1
break
;;
[nN] )
unset installdisk
echo "Select the disk where archlinux should be installed" > $tempdir/menutitle
	sh -c 'echo -n "print devices"|parted|grep /dev|grep \(>/tmp/disk;cat /tmp/disk|tr \  \:>/tmp/disks;rm /tmp/disk'
echo "Cancel installation" >> /tmp/disks
createdynamicmenu cat /tmp/disks
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
export installdisk=`echo $itemname|cut -f 1 -d \:|cut -f 2 -d \"`
unset choice
;;
* )
continue
;;
esac
done
unset itemname
export parttable=`lsblk -n -o PTTYPE $installdisk | cut -d "
" -f 2`
if [ "$parttable" != "gpt" ]; then
echo "The partition table on disk $installdisk is $parttable, not GPT. You must create a GPT partition table on the disk and repartition it."
else
echo "Make changes to partitions on $installdisk? (y/n)"
fi
while true; do
clear
if [ "$parttable" != "gpt" ]; then
export yn=y
else
read -s -n 1 yn
fi
case $yn in 
[yY] )
echo "Instructions for partitioning."
if [ "$parttable" != "gpt" ]; then
echo "Create a blank GPT disk label."
fi
echo "Create two partitions. The 1st partition should be at least 500MB, type should be 1 - EFI System. The second partition will be the root partition and should take up all remaining space on disk unless you are dual booting or createing a home partition, type should be 20 - Linux Filesystem. You should create at least a 6 GB root partition for successful installation. Partitioning the disk incorrectly may result in undefined behavior."
	echo "In fdisk, press m for a list of commands."
read -p "Press enter to make changes to $installdisk"
fdisk $installdisk
echo "Checking disk"
sleep 3
export parttable=`lsblk -n -o PTTYPE $installdisk | cut -d "
" -f 2`
clear
if [ "$parttable" != "gpt" ]; then
echo "Error: The partition table on disk $installdisk is $parttable, not GPT. Create a blank GPT disk label by typing \"g\", and partition it correctly."
else
echo "If partitioning is correct, type y. If you made a mistake or need to make further changes, type n. (y/n)"
fi
while true; do
if [ "$parttable" != "gpt" ]; then
export yn=n
else
read -s -n 1 yn
fi
case $yn in 
[yY] )
break
;;
	[nN] )
fdisk $installdisk
;;
* )
continue
;;
esac
done
break
;;
	[nN] )
break
;;
* )
continue
;;
esac
done
while true; do
if [ -z "$efisystem" ]; then
clear
echo "Select your EFI System partition" > $tempdir/menutitle
export entries=`lsblk -nro name,size $installdisk|wc -l`
lsblk -nro name,size $installdisk|head -n $entries|tail -n $(($entries-1)) > /tmp/vols
echo "Cancel installation" >> /tmp/vols
createdynamicmenu cat /tmp/vols
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
export efidev=`echo $itemname|cut -f 2 -d \"|cut -f 1 -d \  `
export efisystem=/dev/$efidev
fi
if [ -z "$root" ]; then
echo "Select your root partition" > $tempdir/menutitle
export entries=`lsblk -nro name,size $installdisk|wc -l`
lsblk -nro name,size $installdisk|head -n $entries|tail -n $(($entries-1)) > /tmp/vols
echo "Cancel installation"
createdynamicmenu cat /tmp/vols
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
export rootdev=`echo $itemname|cut -f 2 -d \"|cut -f 1 -d \  `
export root=/dev/$rootdev
fi
clear
if [ "$efisystem" = "$root" ]; then
echo "Error: Your Root partition cannot be the same as your EFI system partition."
unset efisystem
unset root
read -t 2
else
echo -e "EFI system partition: $efisystem\nRoot partition: $root\nDo you want to change this? (y/n)"
while true; do
read -s -n 1 yn
case $yn in
[yY] )
break
;;
[nN] )
break
;;
* )
continue
;;
esac
done
case $yn in
[yY] )
unset root
unset efisystem
continue
;;
[nN] )
break
;;
esac
fi
done
echo "If you have a second drive in your computer, or you have another partition on disk $installdisk, you can use it for your /home directory."
echo "Use a 2nd partition for /home? (y/n)"
while true; do
read -s -n 1 yn
case $yn in 
	[yY] ) 
echo "Select the disk to use for your home folder" > $tempdir/menutitle
sh -c 'echo -n "print devices"|parted|grep /dev|grep \(>/tmp/disk;cat /tmp/disk|tr \  \:>/tmp/disks;rm /tmp/disk'
echo "Cancel installation" >> /tmp/disks
createdynamicmenu cat /tmp/disks
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
sleep 0.1
export homedisk=`echo $itemname|cut -f 1 -d \:|cut -f 2 -d \"`
unset choice
sleep 0.3
echo "Disk $homedisk selected. Is this correct? (y/n)"
while true; do
read -s -n 1 yn
case $yn in 
	[yY] )
echo "Confirm $homedisk"
if [ "$installdisk" = "$homedisk" ]; then
echo "warning: Your second disk \"$homedisk\" is the same as the install disk."
fi
read -t 1
break
;;
[nN] )
unset homedisk
clear
echo "Select the disk to use for your home folder" > $tempdir/menutitle
sh -c 'echo -n "print devices"|parted|grep /dev|grep \(>/tmp/disk;cat /tmp/disk|tr \  \:>/tmp/disks;rm /tmp/disk'
echo "Cancel installation" >> /tmp/disks
createdynamicmenu cat /tmp/disks
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
export homedisk=`echo $itemname|cut -f 1 -d \:|cut -f 2 -d \"`
;;
* )
continue
;;
esac
done
echo "make changes to partitions on $homedisk? (y/n) "
while true; do
clear
read -s -n 1 yn
case $yn in 
[yY] )
clear
echo "Instructions for partitioning."
echo "Create 1 partition for /home, can take up as much space as you would like. Type should be Linux filesystem. Partitioning the disk incorrectly may result in undefined behavior."
echo "In fdisk, press m to see a list of commands."
	read -p "Press enter to make changes to $homedisk"
	fdisk $homedisk
echo "If partitioning is correct, type y. If you made a mistake or need to make further changes, type n. (y/n)"
while true; do
read -s -n 1 yn
case $yn in 
[yY] )
break
;;
	[nN] )
fdisk $homedisk
;;
* )
continue
;;
esac
done
break
;;
	[nN] )
break
;;
* )
continue
;;
esac
done
clear
while true; do
echo "Select the partition on $homedisk to mount in /home" > $tempdir/menutitle
export entries=`lsblk -nro name,size $homedisk|wc -l`
lsblk -nro name,size $homedisk|head -n $entries|tail -n $(($entries-1)) > /tmp/vols
echo "Cancel installation" >> /tmp/vols
createdynamicmenu cat /tmp/vols
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
export homedev=`echo $itemname|cut -f 2 -d \"|cut -f 1 -d \  `
if [ "$efidev" = "$homedev" ]; then
clear
echo "error: Your home partition cannot be the same as your EFI System partition."
unset homedev
read -t 2
else
break
fi
done
export homepart=/dev/$homedev
if [ "$root" = "$homepart" ]; then
clear
echo "The home partition is the same as the root partition. The home folder will be created on the root partition instead and a 2nd partition will not be used."
unset homepart
unset homedev
read -t 2
else
clear
fi
	break;;

	[nN] )
break;;
* ) 
continue
;;
esac
done
clear
if [ $homepart ]; then
echo "Format home partition as ext4? Note that you must already have a supported filesystem on the drive if you answer no. Not having this may result in undefined behavior. (y/n) "
while true; do
read -s -n 1 yn
case $yn in
[yY] )
export homeformat=true
break
;;
[nN] )
export homeformat=false
break
;;
* )
continue
;;
esac
done
fi
echo "Linux swap is a partition or a file on disk that the system can use as virtual memory. This is usefull on lower end computers that may not have a lot of ram. Create a swap file? (y/n)"
while true; do
read -s -n 1  yn
case $yn in
[yY] )
export swapfile=true
break
;;
[nN] )
export swapfile=false
break
;;
* )
continue
;;
esac
done
if [ "$swapfile" = "true" ]; then
while true; do
until [[ $mb == +([0-9]) ]] ; do
clear
sleep 0.05
    read -r -p "Enter size of swapfile in MB " mb
done
case $mb in
0*)
unset mb
;;
* )
break
;;
esac
done
export swapsize=`echo "$mb"000`
if [ $swapsize -gt 999999999 ]; then
export friendlysize=`echo "scale=1; $swapsize/1000000000"|bc -l`
export units="TB"
elif [ $swapsize -gt 999999 ]; then
export friendlysize=`echo "scale=1; $swapsize/1000000"|bc -l`
export units="GB"
elif [ $swapsize -gt 999 ]; then
export friendlysize=`echo $mb`
export units="MB"
fi
fi
clear
curl -o "/tmp/countries.tmp" "https://boo15mario.boo/scripts/arch/countries.txt"
echo "Select your mirror region" > $tempdir/menutitle
echo "Cancel installation" >> /tmp/countries.tmp
createdynamicmenu cat /tmp/countries.tmp
if [ "$itemname" = "Cancel installation" ]; then
exit 1
fi
export mirrorregion=`echo $itemname`
if [ -z "$mirrorregion" ];then
echo "Error: Failed to connect to \"https://boo15mario.boo\""
echo "The server may be down. Check your internet connection or try again in a few minutes."
exit 1
fi
echo "\"Choose a kernel to install\"" > /tmp/kerneltype
echo -n "\"n\" \"None  don't install a kernel\" \"s\" \"Standard  linux\" \"l\" \"LTS  linux-lts\" \"h\" \"Hardened  linux-hardened\" \"z\" \"Zen  linux-zen\" \"a\" \"All  Install all kernels\" \"c\" \"Cancel the installation\"" >> /tmp/kerneltype
createmenu /tmp/kerneltype
clear
case "$choice" in
a)
export kerneltype="linux linux-headers linux-hardened linux-hardened-headers linux-lts linux-lts-headers linux-zen linux-zen-headers"
;;
h)
export kerneltype="linux-hardened linux-hardened-headers"
;;
l)
export kerneltype="linux-lts linux-lts-headers"
;;
s)
export kerneltype="linux linux-headers"
;;
z)
export kerneltype="linux-zen linux-zen-headers"
;;
* )
echo "Warning: You will need to manually install a kernel."
;;
c )
exit 0
;;
esac
clear
echo "Set the root password"
echo "Enter password for user root"
while true;do
read -s newpasswd
export rootpasswd1=`echo $newpasswd|cut -d ' ' -f 1`
if [ -z "$rootpasswd1" ];then
clear
echo "Error: Password cannot be blank. Please try again."
read -t 2
continue
else
clear
echo "Retype new password"
read -s rootpasswd2
if [ " $rootpasswd1" != " $rootpasswd2" ]; then
    clear
    echo "Error: Passwords do not match. Please try again."
else
break
fi
fi
done
clear
echo "Set the host name. The host name will be used to identify your computer on the network and on the web."
echo "Enter system host name"
while true;do
read hname
export systemhostname=`echo $hname|cut -d ' ' -f 1`
if [ -z $systemhostname ];then
clear
echo "Error: Host name cannot be blank"
read -t 2
else
break
fi
done
cd /usr/share/zoneinfo
echo -e "Africa\nAmerica\nAntarctica\nArctic\nAsia\nAtlantic\nAustralia\nBrazil\nCanada\nChile\nEtc\nEurope\nIndian\nMexico\nPacific\nUS\nCancel installation" > /tmp/time.tmp
echo "Select your time zone region" > $tempdir/menutitle
createdynamicmenu cat /tmp/time.tmp
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
export region="`echo $itemname`"
clear
ls "/usr/share/zoneinfo/$region/" > /tmp/subzone.tmp
echo "Cancel installation" >> /tmp/subzone.tmp
echo "Select the time zone for the selected region $region" > $tempdir/menutitle
createdynamicmenu cat /tmp/subzone.tmp
if [ "$itemname" = "Cancel installation" ]; then
exit 0
fi
export subzone="`echo $itemname`"
clear
echo "Select your locale" > $tempdir/menutitle
curl -s -o "/tmp/locale" https://boo15mario.boo/scripts/arch/locales.txt
createdynamicmenu cat /tmp/locale 
sleep 0.1
export locale=`echo $itemname`
if [ -z "$locale" ]; then
exit 1
fi
clear
clear
echo "Create a user account"
echo "Enter user name"
while true; do
read usrname
export username=`echo $usrname|cut -d ' ' -f 1`
if [ -z $username ];then
clear
echo "Error: User name cannot be blank. Please try again"
else
break
fi
done
clear
echo "Set a password for user $username"
echo "Enter new password for user $username"
while true; do
read -s newpasswd
export usrpasswd1=`echo $newpasswd|cut -d ' ' -f 1`
if [ -z "$usrpasswd1" ];then
clear
echo "Error: Password cannot be blank. Please try again."
continue
else
clear
echo "Retype new password"
read -s usrpasswd2
if [ " $usrpasswd1" != " $usrpasswd2" ]; then
clear
echo "Error: Passwords do not match. Please try again."
else
break
fi
fi
done
clear
echo "Installation summary:"
echo "Mirror region: $mirrorregion"
if [ "$kerneltype" ]; then
if [ "$kerneltype" = "linux linux-headers linux-hardened linux-hardened-headers linux-lts linux-lts-headers linux-zen linux-zen-headers" ]; then
echo "Kernels: linux, linux-lts, linux,hardened, linux-zen"
else
echo "Kernel: `echo $kerneltype | cut -d ' ' -f 1`"
fi
else
echo "Kernel: none"
fi
if [ "$swapfile" = "true" ]; then
echo "Swap: true"
echo "Swap size: $friendlysize$units"
fi
echo "Host name: $systemhostname"
echo "Localization: $locale"
echo "Time zone: $region/$subzone"
echo "User: $username"
if [ "$homepart" ]; then
if [ "$installdisk" = "$homedisk" ]; then
echo "Disks: 1 disk"
else
echo "Disks: 2 disks"
fi
else
echo "Disks: 1 disk"
fi
echo "The following disk partitions are going to be formatted."
echo "$efisystem (as fat32)"
echo "$root (as ext4)"
if [ "$homeformat" = "true" ]; then
echo "$homepart (as ext4)"
fi
read -p "Press enter to continue."
clear
echo "installing arch linux to your system"
reflector -c "$mirrorregion" --save /etc/pacman.d/mirrorlist
if [ $? != 0 ];then
read -p "Error: Failed to set mirror region to $mirrorregion with reflector. The installation may be slow or faile completely. To continue, press enter. To cancel the install, press control+c."
else
echo "Mirror region set to $mirrorregion"
fi
if [ "$homeformat" = "true" ]; then
echo "Formatting 3 disk partitions in 10 seconds, press control+c to abort, press enter to format now"
else
echo "Formatting 2 disk partitions in 10 seconds, press control+c to abort, press enter to format now"
fi
read -t 10
clear
mkfs.vfat -F32 $efisystem
if [ "$?" != "0" ]; then 
  echo "Error: Failed to format EFI System partition"
  exit 1
  fi
mkfs.ext4 $root
if [ "$?" != "0" ]; then 
  echo "Error: Failed to format Root partition"
  exit 1
  fi
if [ "$homeformat" = "true" ]; then
mkfs.ext4 $homepart
if [ "$?" != "0" ] 
then 
  echo "Error: Failed to format Home partition"
  exit 1
  fi
fi
echo "Partitions were formatted successfully."
echo "Mounting partitions"
echo "Mounting root partition $root on /mnt"
mount -v $root /mnt
if [ $homepart ];then
mkdir -p -v /mnt/home
mount -v $homepart /mnt/home
fi
pacstrap /mnt alsa-firmware alsa-utils base base-devel curl espeakup speakup-utils ntp nano sudo vi vim networkmanager openssh libnewt $kerneltype linux-firmware efibootmgr grub mtools os-prober
if [ $? != 0 ]; then
echo "Error: Installation failed: Could not create installation with pacstrap"
exit 1
fi
mkdir -p -v /mnt/boot/efi
echo "Mounting $efidev on /mnt/boot/efi"
mount -v $efisystem /mnt/boot/efi
if [ "$swapfile" = "true" ]; then
echo Creating swap file with size "$swapsize"B
dd if=/dev/zero of=/mnt/swapfile bs=1000 count=$swapsize status=progress
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
arch-chroot /mnt swapon -v /swapfile
fi
echo "Generating filesystem table"
genfstab -U /mnt >> /mnt/etc/fstab
echo "`genfstab -U /mnt` to /mnt/etc/fstab"
echo '#!/bin/bash' > /mnt/install-arch2.sh
echo "export rootpasswd1=\"$rootpasswd1\"" >> /mnt/install-arch2.sh
echo "export region=\"$region\"" >> /mnt/install-arch2.sh
echo "export subzone=\"$subzone\"" >> /mnt/install-arch2.sh
echo "export systemhostname=\"$systemhostname\"" >> /mnt/install-arch2.sh
echo "export locale=\"$locale\"" >> /mnt/install-arch2.sh
echo "export username=\"$username\"" >> /mnt/install-arch2.sh
echo "export usrpasswd1=\"$usrpasswd1\"" >> /mnt/install-arch2.sh
curl -s "https://boo15mario.boo/scripts/arch/install-arch2.sh" >> /mnt/install-arch2.sh
if [ $? != 0 ];then
echo "Error: Failed to download file from \"https://boo15mario.boo\""
echo "The server may be down. Check your internet connection or try again in a few minutes."
exit 1
fi
arch-chroot /mnt chmod 755 install-arch2.sh
arch-chroot /mnt ./install-arch2.sh
if [ $? != 0 ]; then
echo "Something went wrong while in the chroot."
export chroot=failed
fi
arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
if [ $? != 0 ]; then
echo "Error: Failed to make system bootable with grub."
exit 1
fi
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
echo "Enabling services"
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable ntpd.service
arch-chroot /mnt systemctl enable espeakup.service
if [ "$chroot" = "failed" ]; then
echo "Errors occured while in chroot."
cat /mnt/errors.txt
else
echo -e "Installation finnished with no errors. \nCleaning up\n"
arch-chroot /mnt rm -v install-arch2.sh
fi
echo "Archlinux has been installed."
echo "$root is mounted on /mnt."
echo "$efisystem is mounted on /mnt/boot/efi"
if [ $homepart ];then
echo "$homedev is mounted on /mnt/home."
fi
if [ "$chroot" = "failed" ]; then
echo "Arch has been installed, but something went wrong while in the chroot environment. The following error occured: `cat /mnt/errors.txt` you should check what happened. Chrooting into /mnt with arch-chroot"
arch-chroot /mnt
exit 1
fi
read -p "Press enter for post installation options. Press control+c to exit."
echo "\"Select an option, then press enter\"" > /tmp/postinstall
echo -n "\"p\" \"Install additional packages in the new install\" \"c\" \"Chroot into the new install to make changes manually\" \"a\" \"Install Access Os under the created user account\" \"r\" \"Reboot\" \"s\" \"Shut down\" \"x\" \"Exit\" \"u\" \"Unmount filesystems and exit\"" >> /tmp/postinstall
while true; do
createmenu /tmp/postinstall
case $choice in
p )
clear
echo "Enter package names to install separated by a space."
read packages
if [ "$packages" ]; then
arch-chroot /mnt pacman -S --noconfirm --needed $packages
if [ "$?" != "0" ]; then
echo "Packages failed to install"
read -t 5
else
echo "Packages installed successfully"
read -t 5
fi
else
echo "No packages specified"
read -t 2
fi
;;
c )
echo Chrooting into /mnt using arch-chroot
arch-chroot /mnt
;;
r )
echo Rebooting 
reboot
;;
s )
echo Shutting down 
poweroff
;;
x )
echo Exiting
break
;;
a )
  curl -s -o "/mnt/home/$username/access.sh" "https://boo15mario.boo/scripts/access-os/access.sh"
if [ ! -f /mnt/home/$username/access.sh" ]; then
echo "Error: Access OS cannot be installed at this time
else
chmod 755 /mnt/home/$username/access.sh
arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/access.sh
echo "\"Select an option, then press enter\"" > /tmp/postinstall
echo -n "\"p\" \"Install additional packages in the new install\" \"c\" \"Chroot into the new install to make changes manually\" \"r\" \"Reboot\" \"s\" \"Shut down\" \"x\" \"Exit\" \"u\" \"Unmount filesystems and exit\"" >> /tmp/postinstall
fi
echo "Press enter to return to post installation options
;;
u )
umount $efisystem
if [ "$homepart" ]; then
umount $homepart
fi
umount $root
echo -e "Unmounted partitions\nExiting"
break
;;
esac
done
exit 0

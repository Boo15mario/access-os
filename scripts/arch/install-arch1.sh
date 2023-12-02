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
while true; do
clear
echo "Select the disk where archlinux should be installed"
read -t 2
clear
touch /tmp/disks
chown $USER /tmp/disks
touch /tmp/disk
chown $USER /tmp/disk
sh -c 'echo -n "print devices"|parted|grep /dev|grep \(>/tmp/disk;cat /tmp/disk|tr \  \:>/tmp/disks;rm /tmp/disk'
echo root_only:\(`df --output=size -h /mnt|tail -n 1|cut -f 2 -d \  `\) >> /tmp/disks
createdynamicmenu cat /tmp/disks
sleep 0.1
export installdisk=`echo $itemname|cut -f 1 -d \:|cut -f 2 -d \"`
if [ "$installdisk" = "root_only" ]; then
clear
echo "Error: Disk cannot be $installdisk. Please select a different disk"
unset installdisk
sleep 2
else
break
fi
done
while true; do
clear
read -p "Disk $installdisk selected. Is this correct? (y/n) " yn
case $yn in 
	[yY] )
clear
echo "Confirm $installdisk"
sleep 1
break
;;
[nN] )
unset installdisk
while true; do
clear
echo "Select the disk where archlinux should be installed"
read -t 2
	sh -c 'echo -n "print devices"|parted|grep /dev|grep \(>/tmp/disk;cat /tmp/disk|tr \  \:>/tmp/disks;rm /tmp/disk'
echo root_only:\(`df --output=size -h /mnt|tail -n 1|cut -f 2 -d \  `\) >> /tmp/disks
createdynamicmenu cat /tmp/disks
export installdisk=`echo $itemname|cut -f 1 -d \:|cut -f 2 -d \"`
if [ "$installdisk" = "root_only" ]; then
clear
echo "Error: Disk cannot be $installdisk. Please select a different disk"
unset installdisk
read -t 2
else
break
fi
done
unset choice
;;
* )
clear
echo "Error: Invalid option \"$yn\" type y or n"
read -t 2
;;
esac
done
unset itemname
unset choice

export parttable=`lsblk -n -o PTTYPE $installdisk | cut -d "
" -f 2`
while true; do
clear
if [ "$parttable" != "gpt" ]; then
echo "The partition table on disk $installdisk is $parttable, not GPT. You must create a GPT partition table on the disk and repartition it."
export yn=y
else
read -p "make changes to partitions on $installdisk? (y/n) " yn
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
sleep 5
export parttable=`lsblk -n -o PTTYPE $installdisk | cut -d "
" -f 2`
clear
while true; do
if [ "$parttable" != "gpt" ]; then
clear
echo "Error: The partition table on disk $installdisk is $parttable, not GPT. Create a blank GPT disk label by typing \"g\", and partition it correctly."
export yn=n
read -t 2
else
read -p "If partitioning is correct, type y. If you made a mistake or need to make further changes, type n. (y/n)" yn
fi
case $yn in 
[yY] )
break
;;
	[nN] )
fdisk $installdisk
;;
* )
clear
echo "Error: Invalid option \"$yn\" type y or n"
read -t 2
;;
esac
done
break
;;
	[nN] )
break
;;
* )
clear
echo "Error: Invalid option \"$yn\" type y or n"
read -t 2
;;
esac
done
while true; do
clear
echo "Select your EFI System partition"
read -t 2
export entries=`lsblk -nro name,size $installdisk|wc -l`
lsblk -nro name,size $installdisk|head -n $entries|tail -n $(($entries-1)) > /tmp/vols
createdynamicmenu cat /tmp/vols
export efidev=`echo $itemname|cut -f 2 -d \"|cut -f 1 -d \  `
export efisystem=/dev/$efidev
clear
echo "Confirm $efisystem"
read -t 2
clear
echo "Select your root partition"
read -t 2
export entries=`lsblk -nro name,size $installdisk|wc -l`
lsblk -nro name,size $installdisk|head -n $entries|tail -n $(($entries-1)) > /tmp/vols
createdynamicmenu cat /tmp/vols
export rootdev=`echo $itemname|cut -f 2 -d \"|cut -f 1 -d \  `
if [ "$efidev" = "$rootdev" ]; then
clear
echo "Error: Your Root partition cannot be the same as your EFI system partition."
read -t 2
else
export root=/dev/$rootdev
clear
echo "Confirm $root"
break
fi
done
read -t 1
clear
echo "If you have a second drive in your computer, or you have another partition on disk $installdisk, you can use it for your /home directory."
read -t 2
while true; do
clear
read -p "Use a 2nd partition for /home? (y/n) " yn

case $yn in 
	[yY] ) 
while true; do
clear
echo "Select the disk to use for your home folder"
read -t 2
sh -c 'echo -n "print devices"|parted|grep /dev|grep \(>/tmp/disk;cat /tmp/disk|tr \  \:>/tmp/disks;rm /tmp/disk'
echo root_only:\(`df --output=size -h /mnt|tail -n 1|cut -f 2 -d \  `\) >> /tmp/disks
createdynamicmenu cat /tmp/disks
sleep 0.1
export homedisk=`echo $itemname|cut -f 1 -d \:|cut -f 2 -d \"`
if [ "$homedisk" = "root_only" ]; then
clear
echo "Error: Disk cannot be $homedisk. Please select a different disk"
unset installdisk
read -t 2
else
break
fi
done
unset choice
sleep 0.3
while true; do
clear
read -p "Disk $homedisk selected. Is this correct? (y/n) " yn
case $yn in 
	[yY] )
if [ "$installdisk" = "$homedisk" ]; then
clear
echo "warning: Your second disk \"$homedisk\" is the same as the install disk."
read -t 2
else
clear
fi
echo "Confirm $homedisk"
read -t 1
break
;;
[nN] )
unset homedisk
while true; do
clear
echo "Select the disk to use for your home folder"

sh -c 'echo -n "print devices"|parted|grep /dev|grep \(>/tmp/disk;cat /tmp/disk|tr \  \:>/tmp/disks;rm /tmp/disk'
echo root_only:\(`df --output=size -h /mnt|tail -n 1|cut -f 2 -d \  `\) >> /tmp/disks
createdynamicmenu cat /tmp/disks
export homedisk=`echo $itemname|cut -f 1 -d \:|cut -f 2 -d \"`
if [ "$homedisk" = "root_only" ]; then
clear
echo "Error: Disk cannot be $homedisk. Please select a different disk"
unset homedisk
read -t 2
else
break
fi
done
;;
* )
clear
echo "Error: Invalid option \"$yn\" type y or n"
read -t 2
;;
esac
done
while true; do
clear
read -p "make changes to partitions on $homedisk? (y/n) " yn
case $yn in 
[yY] )
clear
echo "Instructions for partitioning."
echo "Create 1 partition for /home, can take up as much space as you would like. Type should be Linux filesystem. Partitioning the disk incorrectly may result in undefined behavior."
echo "In fdisk, press m to see a list of commands."
	read -p "Press enter to make changes to $homedisk"
	fdisk $homedisk
while true; do
read -p "If partitioning is correct, type y. If you made a mistake or need to make further changes, type n. (y/n)" yn
case $yn in 
[yY] )
break
;;
	[nN] )
fdisk $homedisk
;;
* )
clear
echo "Error: Invalid option \"$yn\" type y or n"
;;
esac
done
break
;;
	[nN] )
break
;;
* )
clear
echo "Error: Invalid option \"$yn\" type y or n"
read -t 2
;;
esac
done
clear
echo "Select the partition on $homedisk to mount in /home"
read -t 2
while true; do
export entries=`lsblk -nro name,size $homedisk|wc -l`
lsblk -nro name,size $homedisk|head -n $entries|tail -n $(($entries-1)) > /tmp/vols
createdynamicmenu cat /tmp/vols
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
echo "The home partition is the same as the root partition. A second partition will not be used."
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
clear
echo "Error: Invalid option \"$yn\" type y or n."
read -t 2
;;
esac
done
clear
if [ $homepart ]; then
while true; do
clear
read -p "Format home partition as ext4? Note that you must already have a supported filesystem on the drive if you answer no. Not having this may result in undefined behavior. (y/n) " yn
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
clear
echo "Error: Invalid option \"$yn\" type y or n"
read -t 2
;;
esac
done
fi
echo "Linux swap is a partition or a file on disk that the system can use as virtual memory. This is usefull on lower end computers that may not have a lot of ram."
while true; do
read -p "Create a swap file? (y/n) " yn
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
clear
echo "Error: Invalid option \"$yn\" type y or n"
read -t 2
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
echo "Select your mirror region"
echo "Press enter to confirm"
read -t 2
createdynamicmenu curl -s "https://boo15mario.boo/scripts/arch/countries.txt"
export mirrorregion=`echo $itemname`
if [ -z "$mirrorregion" ];then
echo "Error: Failed to connect to \"https://boo15mario.boo\""
echo "The server may be down. Check your internet connection or try again in a few minutes."
exit 1
fi
echo "\"Choose a kernel to install\"" > /tmp/kerneltype
echo -n "\"n\" \"None  don't install a kernel\" \"s\" \"Standard  linux\" \"l\" \"LTS  linux-lts\" \"h\" \"Hardened  linux-hardened\" \"z\" \"Zen  linux-zen\" \"a\" \"All  Install all kernels\"" >> /tmp/kerneltype
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
esac
clear
echo "Set the root password"
read -t 2
while true;do
clear
echo "Enter password for user root"
read -s newpasswd
export rootpasswd1=`echo $newpasswd|cut -d ' ' -f 1`
if [ -z "$rootpasswd1" ];then
clear
echo "Error: Password cannot be blank"
read -t 2
continue
else
clear
echo "Retype new password"
read -s rootpasswd2
if [ " $rootpasswd1" != " $rootpasswd2" ]; then
    clear
    echo "Error: Passwords do not match"
read -t 2
else
break
fi
fi
done
echo "Set the host name. The host name will be used to identify your computer on the network and on the web."
read -t 2
while true;do
clear
echo "Enter system host name"
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
echo -e "Africa\nAmerica\nAntarctica\nArctic\nAsia\nAtlantic\nAustralia\nBrazil\nCanada\nChile\nEtc\nEurope\nIndian\nMexico\nPacific\nUS" > /tmp/time.tmp
echo "Select your time zone"
sleep 0.2
echo "Select your region"
read -t 2
createdynamicmenu cat /tmp/time.tmp
export region="`echo $itemname`"
clear
echo "Select the subzone to use for the region \"$region\""
read -t 2
createdynamicmenu ls "/usr/share/zoneinfo/$region/"
export subzone="`echo $itemname`"
clear
echo "Select your locale"
read -t 2
createdynamicmenu curl -s https://boo15mario.boo/scripts/arch/locales.txt
sleep 0.1
export locale=`echo $itemname`
if [ -z "$locale" ]; then
exit 1
fi
clear
echo "Create a user account"
read -t 2
while true; do
clear
echo "Enter user name"
read usrname
export username=`echo $usrname|cut -d ' ' -f 1`
if [ -z $username ];then
clear
echo "Error: User name cannot be blank"
read -t 2
else
break
fi
done
clear
echo "Set a password for user $username"
read -t 2
while true; do
clear
echo "Enter new password for user $username"
read -s newpasswd
export usrpasswd1=`echo $newpasswd|cut -d ' ' -f 1`
if [ -z "$usrpasswd1" ];then
clear
echo "Error: Password cannot be blank"
read -t 2
continue
else
clear
echo "Retype new password"
echo "Press enter when done"
read -s usrpasswd2
if [ " $usrpasswd1" != " $usrpasswd2" ]; then
clear
echo "Error: Passwords do not match"
read -t 2
else
break
fi
fi
done
clear
echo "Installation summary:"
sleep 0.01
echo "Mirror region: $mirrorregion"
sleep 0.01
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
sleep 0.01
echo "Swap: true"
sleep 0.01
echo "Swap size: $friendlysize$units"
fi
sleep 0.01
echo "Host name: $systemhostname"
sleep 0.01
echo "Localization: $locale"
sleep 0.01
echo "Time zone: $region/$subzone"
sleep 0.01
echo "User: $username"
sleep 0.01
if [ "$homepart" ]; then
if [ "$installdisk" = "$homedisk" ]; then
echo "Disks: 1 disk"
else
echo "Disks: 2 disks"
fi
else
echo "Disks: 1 disk"
fi
sleep 0.01
echo "The following disk partitions are going to be formatted."
sleep 0.01
echo "$efisystem (as fat32)"
sleep 0.01
echo "$root (as ext4)"
if [ "$homeformat" = "true" ]; then
sleep 0.01
echo "$homepart (as ext4)"
fi
sleep 0.01
read -p "Press enter to continue, or control+c to cancel the installation."
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
echo "Mounting home partition $homepart on /home"
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
echo "$rootdev is mounted on /mnt."
echo "$efidev is mounted on /mnt/boot/efi"
if [ $homepart ];then
echo "$homedev is mounted on /mnt/home."
fi
if [ "$chroot" = "failed" ]; then
echo "Arch has been installed, but something went wrong while in the chroot environment. The following error occured: `cat /mnt/errors.txt` you should check what happened. Chrooting into /mnt with arch-chroot"
arch-chroot /mnt
exit 1
fi
read -p "Press enter for post installation options. Press control+c to exit."
while true; do
echo "\"Select an option, then press enter\"" > /tmp/postinstall
echo -n "\"p\" \"Install additional packages in the new install\" \"c\" \"Chroot into the new install to make changes manually\" \"r\" \"Reboot\" \"s\" \"Shut down\" \"x\" \"Exit\" \"u\" \"Unmount filesystems and exit\"" >> /tmp/postinstall
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

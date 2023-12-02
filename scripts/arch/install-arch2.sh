cd /etc
curl -s -o sudoers "https://boo15mario.boo/scripts/arch/sudoers"
if [ "$?" != "0" ]; then
echo "Failed to connect to boo15mario.boo" >> /errors.txt
exit 1
fi
chmod 440 sudoers
echo -e "$rootpasswd1\n$rootpasswd1" | passwd root
if [ "$?" != "0" ]; then
echo "Failed to set root password" > /errors.txt
exit 1
fi
sleep 0.2
echo $systemhostname>/etc/hostname
echo "$systemhostname to /etc/hostname"
touch /etc/hosts
echo -e "127.0.0.1      localhost\n::1            localhost\n127.0.1.1      $systemhostname" >>/etc/hosts
echo -e "127.0.0.1      localhost\n::1            localhost\n127.0.1.1      $systemhostname to /etc/hosts"
echo "Setting timezone to \"$region/$subzone\""
ln -sf "/usr/share/zoneinfo/$region/$subzone" "/etc/localtime"
echo "Created symlink for /usr/share/zoneinfo/$region/$subzone to /etc/localtime"
echo "Setting the hardware clock to match the system time"
hwclock --systohc
echo "Done setting time zone"
sleep 0.2
echo "Setting the locale to \"$locale\""
echo "$locale to /etc/locale.gen"
echo $locale > /etc/locale.gen
echo "LANG=`echo $locale|cut -d ' ' -f 1`" > /etc/locale.conf
export LANG=`echo $locale|cut -d ' ' -f 1`
sleep 0.3
echo `cat /etc/locale.conf` to /etc/locale.conf
locale-gen
if [ "$?" != "0" ]; then
echo "Failed to generate locales" > /errors.txt
exit 1
fi
sleep 0.2
echo "Creating user account"
useradd -m -G audio,video,storage,power,wheel $username
if [ "$?" != "0" ]; then
echo "Failed to create user \"$username\"" > /errors.txt
exit 1
fi
echo "done creating user account"
echo "Setting password for user $username"
echo -e "$usrpasswd1\n$usrpasswd1" | passwd $username
if [ "$?" != "0" ]; then
echo "Failed to set password for user $username" > /errors.txt
exit 1
fi
exit 0

#!/bin/bash
# Environment variables
export repo_name="accessOS"
export repo_dir="(path-to-repo)"
export working_dir="(path-to-workdir)"
export local_sources="(path-to-localsourcesdir)"
export pkglist="./a-list.txt"
export tempdir=$(mktemp -d)
export sync_script="./mirror-sync.sh"
export local_build=1
export remote_build=1
export mirror_sync=1
pending_reboot() {
for field in $(file /boot/vmlinuz*); do
if [ "$field" = "$(uname -r)" ];then
local rc=1
fi
    done
if [ -z "$rc" ];then
echo "Error: a kernel update was taken. Reboot to continue." 1>&2
exit 1
fi
}
if [ "$(id -u)" = "0" ];then
echo "Error: you cannot run this script as root" 1>&2
exit 1
fi
if [ ! -d "$repo_dir" ];then
echo "Error: $repo_dir: no such file or directory." 1>&2
exit 1
fi
if [ ! -f "$pkglist" ];then
echo "Error: "$pkglist": no such file or directory." 1>&2
exit 1
fi
if [ "$local_build" != "1" ]&&[ "$remote_build" != "1" ]&&[ "$mirror_sync" != "1" ];then
echo "Error: At least one build option must be enabled."
exit 1
fi
if [ "$mirror_sync" = "1" ];then
echo "Syncing archlinux mirror"
sudo $sync_script
fi
echo "Checking for updates"
paru -Syu --needed --noconfirm||exit 1
pending_reboot
mkdir -p "$working_dir"
cd "$working_dir"
mkdir -p "sources"||exit 1
cd sources
if [ "$local_build" = "1" ]&&[ -d "$local_sources" ];then
echo "Copying local sources to sources directory"
rsync -r --progress "$local_sources/" "$working_dir/sources"
fi
if [ "$remote_build" = "1" ];then
echo "Downloading pkgbuilds from the AUR"
paru -G - < "$pkglist"||exit 1
fi
for sources in *;do
(
cd "$sources"
PKGDEST="$repo_dir" makepkg -srcC --needed --noconfirm
exit_code="$?"
case "$exit_code" in
0 )
echo "The build completed successfully."
for packages in $(PKGDEST="$repo_dir" makepkg --packagelist);do
if [ -f "$packages" ];then
echo "Adding $packages to database"
repo-add "$repo_dir/$repo_name.db.tar.gz" "$packages"
fi
done
sudo pacman -Sy
;;
13 )
echo "Warning: package $sources is up-to-date -- skipping." 1>&2
echo "$sources">>$tempdir/up-to-date
;;
* )
echo "Error: package "$sources" failed to build."
echo "$sources">>$tempdir/failed
;;
esac
)
done
cd
echo "Cleaning up left over junk"
rm -rf "$working_dir"
if [ -f "$tempdir/up-to-date" ];then
echo "Info: skipped building $(cat $tempdir/up-to-date|wc -l) packages that were already up-to-date." 1>&2
fi
if [ -f "$tempdir/failed" ];then
echo "$(cat $tempdir/failed|wc -l) packages failed to build:"
cat $tempdir/failed
fi
echo "The $repo_name repository has been updated successfully. The packages are stored in $repo_dir."
exit 0

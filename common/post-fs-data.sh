#!/system/bin/sh
# Set Magisk SU's Mount Namespace to Global

ModPath=${0%/*}
export PATH=$PATH:/sbin/.core/busybox:/dev/magisk/bin
cd /data/data/com.topjohnwu.magisk/shared_prefs
target=com.topjohnwu.magisk_preferences.xml
if ! grep 'mnt_ns">1' $target; then
	sed -i '/mnt_ns/s/[0-9]/1/' $target
	chmod 660 $target
fi
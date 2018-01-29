#!/system/bin/sh
# fbind Early Bird
# VR25 @ XDA Developers


ModPath=${0%/*}
export PATH="/sbin/.core/busybox:/dev/magisk/bin:$PATH"
umask 022


rm /data/media/fbind/.no_restore 2>/dev/null
grep -v '#' /data/media/fbind/config.txt 2>/dev/null | grep -q 'setenforce 0' && setenforce 0


# Intelligently toggle SELinux mode
SEck="$(ls -1 $(echo "$PATH" | sed 's/:/ /g') 2>/dev/null | grep -E 'sestatus|getenforce' | head -n1)"

if [ -n "$SEck" ]; then
	if $SEck | grep -iq enforcing; then
		was_enforcing=true
		setenforce 0
	else
		was_enforcing=false
	fi
fi

exxit() {
	if [ -n "$SEck" ]; then
		$was_enforcing && setenforce 1
	fi
	[ -z "$1" ] && exit 0 || exit 1
}


# Reinforcement/fail-safe -- disable sdcardfs -- necessary for "mount -o bind" to work properly.
resetprop persist.sys.sdcardfs force_off
setprop persist.sys.sdcardfs force_off


# Set Magisk SU's Mount Namespace to Global
cd /data/data/com.topjohnwu.magisk/shared_prefs || exxit 1
target=com.topjohnwu.magisk_preferences.xml
target_owner="$(ls -l $target | awk '{print $3}')"
target_Scon="$(ls -Z $target | awk '{print $1}')"

if ! grep -q 'mnt_ns">0' $target; then
	sed -i '/mnt_ns/s/[0-9]/0/' $target
	chown $target_owner:$target_owner $target
	chcon $target_Scon $target
	chmod 660 $target
fi

exxit

#!/system/bin/sh

# fbind Boot Service (Auto-bind)
# VR25 @ XDA Developers

# Use Magisk's internal busybox
export PATH=/system/xbin:/sbin:/dev/magisk/bin

source /magisk/fbind/core.sh

if grep -v '#' $config_file | grep -q 'cryptsetup=true'; then
	log_start
	echo "cryptsetup enabled!"
	echo "Auto-bind cannot proceed."
	log_end
fi

log_start
update_cfg
apply_cfg
bkp_cfg
intsd_fbind
bind_folders
cleanupf
log_end
#!/system/bin/sh

# fbind Boot Service (Auto-bind)
# VR25 @ XDA Developers

# Environment prep
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
bind_folders
cleanupf
log_end
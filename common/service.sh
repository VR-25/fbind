#!/system/bin/sh

# fbind Boot Service (Auto-bind)
# VR25 @ XDA Developers

# Prepare Environment
export PATH=/dev/magisk/bin:$PATH
source /magisk/fbind/core.sh


# Abort auto-bind to open LUKS volume
if grep -v '#' $config_file | grep -q 'cryptsetup=true'; then
	log_start
	echo "(i) cryptsetup Enabled"
	echo "- Auto-bind aborted."
	log_end
fi


log_start

# Check/fix SD Card fs
if grep -v '#' $config_file | grep -q fsck; then
	echo "<Check/fix SD card fs>"
	until [ -b "$(grep -v '#' $config_file | grep fsck | cut -d' ' -f3)" ]; do sleep 1; done &>/dev/null
	$(grep -v '#' $config_file | grep fsck)
	echo
fi

update_cfg
apply_cfg
cfg_bkp
bind_folders
cleanupf
echo


# Grant storage permissions to all APKs
if grep -v "#" $config_file | grep -qw perms; then

	STORAGE_PERMISSIONS="WRITE_MEDIA_STORAGE WRITE_EXTERNAL_STORAGE"

	grantPerms() {
	  for perm in $2; do
		pm grant "$1" android.permission."$perm" 2>/dev/null
  	done
	}

	[ -f $config_path/storage_perms ] || touch $config_path/storage_perms
	echo "<Grant Storage Perms>"
	
	# Grant perms & take notes
	for pkg in $(cat /data/system/packages.list | cut -d' ' -f1); do
		if ! grep -q "$pkg" $config_path/storage_perms; then
			grantPerms "$pkg" "$STORAGE_PERMISSIONS"
			echo "$pkg" >> $config_path/storage_perms
			echo "- $pkg"
		fi
	done
	echo Done.
	
	# Remove absent system & user APKs from list
	for pkg in $(cat $config_path/storage_perms); do
		grep -q "$pkg" /data/system/packages.list && echo "$pkg" >> $config_path/storage_perms_tmp
	done
	mv -f $config_path/storage_perms_tmp $config_path/storage_perms
	
fi
log_end

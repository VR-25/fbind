#!/system/bin/sh
# fbind Boot Service (auto-bind)
# VR25 @ XDA Developers


# Environment
ModPath=${0%/*}
export PATH="/sbin/.core/busybox:/dev/magisk/bin:$PATH"

# Intelligently toggle SELinux mode
if sestatus | grep -q enforcing; then
	was_enforcing=true
	setenforce 0
else
	was_enforcing=false
fi


umask 022
. $ModPath/core.sh


# Abort auto-bind to open LUKS volume
if grep -v '#' $config_file | grep -q luks; then
	log_start
	echo "(i) LUKS in Use"
	echo "- Auto-bind aborted"
	log_end
fi


log_start


# Check/fix SD Card FS
if grep -Ev 'part|#' $config_file | grep -iq fsck; then
	echo "<FSCK>"
	until [ -b "$(grep -Ev 'part|#' $config_file | grep -i fsck | awk '{print $3}')" ]; do sleep 1; done
	$(grep -Ev 'part|#' $config_file | grep fsck)
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

	touch $config_path/storage_perms
	echo "<Grant Storage Perms>"
	
	# Grant perms & take notes
	while read pkg; do
		if ! grep -q "$pkg" $config_path/storage_perms; then
			grantPerms "$pkg" "$STORAGE_PERMISSIONS"
			echo "$pkg" >> $config_path/storage_perms
			echo "- $pkg"
		fi
	done <<< "$(cat /data/system/packages.list | cut -d' ' -f1)"
	echo Done.
	
	# Remove absent system & user APKs from list
	while read pkg; do
		grep -q "$pkg" /data/system/packages.list && echo "$pkg" >> $config_path/storage_perms_
	done <<< "$(cat $config_path/storage_perms)"
	mv -f $config_path/storage_perms_ $config_path/storage_perms
	
fi

log_end

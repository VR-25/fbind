#!/system/bin/sh
# fbind Boot Service (auto-bind)
# VR25 @ XDA Developers


# Environment
export ModPath=${0%/*}
export PATH="/sbin/.core/busybox:/dev/magisk/bin:$PATH"
fbind_dir=/data/media/fbind


[ -d "$fbind_dir" ] || mkdir -m 777 $fbind_dir
[ -f $fbind_dir/.no_restore ] && rm $fbind_dir/.no_restore


# Intelligently handle SELinux mode
grep -v '#' $fbind_dir/config.txt 2>/dev/null | grep -q 'setenforce 0' && setenforce 0
grep -v '#' $fbind_dir/config.txt 2>/dev/null | grep -q 'setenforce auto' \
	&& SELinuxAutoMode=true || SELinuxAutoMode=false
SEck="$(ls -1 $(echo "$PATH" | sed 's/:/ /g') 2>/dev/null | grep -E 'sestatus|getenforce' | head -n1)"

if [ -n "$SEck" ] && $SELinuxAutoMode; then
	if $SEck | grep -iq enforcing; then
		was_enforcing=true
		setenforce 0
	else
		was_enforcing=false
	fi
fi


# Default permissions
umask 000


. $ModPath/core.sh


# Abort auto-bind to open LUKS volume
if grep -v '#' $config_file | grep -q '\-\-L'; then
	log_start
	echo "(i) LUKS in Use"
	echo "- Auto-bind aborted"
	log_end
fi


log_start


BackgroundActions() {
	# Check/fix SD Card FS
	if grep -Ev 'part|#' $config_file | grep -iq fsck; then
		echo -e "\n\n<FSCK>\n"
		wait_until_true [ -b "$(grep -Ev 'part|#' $config_file | grep -i fsck | awk '{print $3}')" ]
		$(grep -Ev 'part|#' $config_file | grep fsck)
		echo
	fi

	echo
	echo
	apply_cfg
	echo
	echo
	
	if grep -v '#' $config_file | grep -Eq 'app_data |int_extf|bind_mnt |obb.*|from_to |target '; then
		bind_folders
	else
		echo -e "\n<Bind Folders>\n- Nothing to mount"
	fi
	
	echo
	echo
	
	if is f $fbind_dir/cleanup.sh || grep -v '#' $config_file | grep -q "cleanup "; then
		cleanupf
	else
		echo -e "\n<Cleanup>\n- Nothing to clean"
	fi

	log_end
}

(BackgroundActions) &

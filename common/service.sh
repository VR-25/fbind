#!/system/bin/sh
# fbind Boot Service (auto-bind)
# VR25 @ XDA Developers


# Environment
ModPath=${0%/*}
export PATH="/sbin/.core/busybox:/dev/magisk/bin:$PATH"


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


umask 022
. $ModPath/core.sh


# Abort auto-bind to open LUKS volume
if grep -v '#' $config_file | grep -q '\-\-L'; then
	log_start
	echo "(i) LUKS in Use"
	echo "- Auto-bind aborted"
	log_end
fi


log_start


# Check/fix SD Card FS
if grep -Ev 'part|#' $config_file | grep -iq fsck; then
	echo "<FSCK>"
	wait_until_true [ -b "$(grep -Ev 'part|#' $config_file | grep -i fsck | awk '{print $3}')" ]
	$(grep -Ev 'part|#' $config_file | grep fsck)
	echo
	echo
fi


apply_cfg
grep -v '#' $config_file | grep -Eq 'app_data |int_extf|bind_mnt |obb.*|from_to |target ' && bind_folders || echo "(i) Nothing set"
if is f $fbind_dir/cleanup.sh || grep -v '#' $config_file | grep -q "cleanup "; then cleanupf; else echo "(i) Nothing set"; fi
log_end

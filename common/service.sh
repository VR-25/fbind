#!/system/bin/sh
# fbind Boot Service (auto-bind)
# VR25 @ XDA Developers


# Verbose logging
logsDir=/data/media/fbind/logs
newLog=$logsDir/service.sh_verbose_log.txt
oldLog=$logsDir/service.sh_verbose_previous_log.txt
[[ -d $logsDir ]] || mkdir -p -m 777 $logsDir
[[ -f $newLog ]] && mv $newLog $oldLog
set -x 2>>$newLog


# Environment
export ModPath=${0%/*}
export PATH="$ModPath/bin:$ModPath/system/xbin:$ModPath/system/bin:/sbin/.core/busybox:/dev/magisk/bin:$PATH"
fbindDir=/data/media/fbind


[ -d "$fbindDir" ] || mkdir -m 777 $fbindDir
[ -f $fbindDir/.no_restore ] && rm $fbindDir/.no_restore


# Intelligently handle SELinux mode
grep -v '^#' $fbindDir/config.txt 2>/dev/null | grep -q 'setenforce 0' && setenforce 0
grep -v '^#' $fbindDir/config.txt 2>/dev/null | grep -q 'setenforce auto' \
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
log_start


BackgroundActions() {
	# Check/fix SD Card FS
	if grep -Ev '^#|^part ' $cfgFile | grep -iq fsck; then
		echo -e "\n\nFSCK\n"
		wait_until_true [ -b "$(grep -Ev '^#|^part ' $cfgFile | grep -i fsck | sed -n 's:^.*/dev/:/dev/:p')" ]
		[[ $? ]] && $(grep -Ev '^#|^part ' $cfgFile | grep fsck) || \
		  echo "(!) $(grep -Ev '^#|^part ' $cfgFile | grep -i fsck | sed -n 's:^.*/dev/:/dev/:p') not ready"
		echo
	fi

	echo
	echo
	apply_cfg
	echo
	echo
	
	if grep -v '^#' $cfgFile | grep -Eq '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target '; then
		bind_folders
	else
		echo -e "\n<Bind Folders>\n- Nothing to bind-mount"
	fi
	
	echo
	echo
	
	if is f $fbindDir/cleanup.sh || grep -v '^#' $cfgFile | grep -q '^cleanup '; then
		cleanupf
	else
		echo -e "\n<Cleanup>\n- Nothing to clean"
	fi

	log_end
}

(BackgroundActions) &

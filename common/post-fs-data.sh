#!/system/bin/sh
# fbind Early Bird
## (c) 2017-2018, VR25 @ xda-developers
### License: GPL v3+


# Verbose logging
logsDir=/data/media/fbind/logs
newLog=$logsDir/post-fs-data.sh_verbose_log.txt
oldLog=$logsDir/post-fs-data.sh_verbose_previous_log.txt
[[ -d $logsDir ]] || mkdir -p -m 777 $logsDir
[[ -f $newLog ]] && mv $newLog $oldLog
set -x 2>>$newLog


export ModPath=${0%/*}
export PATH="$ModPath/bin:$ModPath/system/xbin:$ModPath/system/bin:/sbin/.core/busybox:/dev/magisk/bin:$PATH"
fbindDir=/data/media/fbind
umask 000
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

exxit() {
	if [ -n "$SEck" ] && $SELinuxAutoMode; then
		$was_enforcing && setenforce 1
	fi
	if [ -z "$1" ]; then
    exit 0
  else
    echo "$1" && exit 1
  fi
}



# Disable ESDFS and SDCARDFS & enable FUSE (fail-safe)

resetprop persist.esdfs_sdcard false
setprop persist.esdfs_sdcard false

resetprop persist.sys.sdcardfs force_off
setprop persist.sys.sdcardfs force_off

resetprop persist.fuse_sdcard true
setprop persist.fuse_sdcard true



# Auto re-patch platform.xml -- storage permissions
XML_mod_dir=$ModPath/system/etc/permissions

XML_list="/sbin/.core/mirror/system/etc/permissions/platform.xml
/dev/magisk/mirror/system/etc/permissions/platform.xml"

rm -rf /dev/fbind_tmp 2>/dev/null
mkdir /dev/fbind_tmp

for f in $XML_list; do
  if [ -f "$f" ]; then
    cp "$f" /dev/fbind_tmp
    Mirror="$(echo $f | sed 's/\/etc.*//')"
    break
  fi
done

grep -q '_.*NAL_STO.*/>$' /dev/fbind_tmp/platform.xml && Patch=true || Patch=false

if $Patch && [ "$(cat $ModPath/.SystemSizeK)" -ne "$(du -s "$Mirror" | cut -f1)" ]; then
	sed -i '/<\/permissions>/d' /dev/fbind_tmp/platform.xml
	echo >>/dev/fbind_tmp/platform.xml
	
	Perms="READ_EXTERNAL_STORAGE
	WRITE_EXTERNAL_STORAGE"

	for Perm in $Perms; do
		if grep $Perm /dev/fbind_tmp/platform.xml | grep -q '/>'; then
			sed -i /$Perm/d /dev/fbind_tmp/platform.xml
			if echo $Perm | grep -q READ; then
				cat <<BLOCK >>/dev/fbind_tmp/platform.xml
    <permission name="android.permission.READ_EXTERNAL_STORAGE" >
        <group gid="sdcard_r" />
    </permission>"
BLOCK
			else
				cat <<BLOCK >>/dev/fbind_tmp/platform.xml
    <permission name="android.permission.WRITE_EXTERNAL_STORAGE" >
        <group gid="media_rw" />
        <group gid="sdcard_r" />
        <group gid="sdcard_rw" />
    </permission>"
BLOCK
			fi
		fi
	done

	echo -e "\n</permissions>" >>/dev/fbind_tmp/platform.xml

	mkdir -p $XML_mod_dir
	mv /dev/fbind_tmp/platform.xml $XML_mod_dir
  chmod -R 755 $XML_mod_dir
	
	# Export /system size for platform.xml automatic re-patching across ROM updates
    du -s "$(echo "$f" | sed 's/\/etc.*//')" | cut -f1 >$ModPath/.SystemSizeK
fi

rm -rf /dev/fbind_tmp 2>/dev/null
exxit

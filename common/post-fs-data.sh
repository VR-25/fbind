#!/system/bin/sh
# fbind Early Bird
# VR25 @ XDA Developers


ModPath=${0%/*}
export PATH="/sbin/.core/busybox:/dev/magisk/bin:$PATH"

# Intelligently toggle SELinux mode
SEck="$(ls -1 $(echo "$PATH" | sed 's/:/ /g') | grep -E 'sestatus|getenforce' | head -n1)"

if [ -n "$SEck" ]; then
	if $SEck | grep -iq enforcing; then
		was_enforcing=true
		setenforce 0
	else
		was_enforcing=false
	fi
fi


umask 022



# Set Magisk SU's Mount Namespace to Global
cd /data/data/com.topjohnwu.magisk/shared_prefs || exit 1
target=com.topjohnwu.magisk_preferences.xml
target_owner="$(ls -l $target | awk '{print $3}')"
target_Scon="$(ls -Z $target | awk '{print $1}')"

if ! grep -q 'mnt_ns">0' $target; then
	sed -i '/mnt_ns/s/[0-9]/0/' $target
	chown $target_owner:$target_owner $target
	chcon $target_Scon $target
	chmod 660 $target
fi



#Automaically re-patch platform.xml across ROM updates -- storage permissions

MirrorList="/sbin/.core/mirror/system
/dev/magisk/mirror/system"

for Mirror in $MirrorList; do
  if [ -d "$Mirror" ]; then
  	Mirror="$Mirror"
  	break
  fi
done

if [ "$(cat $ModPath/.SystemSizeK)" -ne "$(du -s "$Mirror" | cut -f1)" ]; then

	XML_orig="$Mirror/etc/permissions/platform.xml"
	XML_mod_dir="$ModPath/system/etc/permissions"
	XML_mod="$XML_mod_dir/platform.xml"

	[ -d $XML_mod_dir ] || mkdir -p -m 755 $XML_mod_dir
	cp $XML_orig $XML_mod

	PERMS="WRITE_EXTERNAL_STORAGE"

	sed -i '/<\/permissions>/d; /WRITE_EXTERNAL_STORAGE/d' $XML_mod
	echo >>$XML_mod

	sed '/<group gid="media_.*" \/>/d; /<group gid="sdcard_.*" \/>/d' $XML_mod

	sed '/WRITE_MEDIA_STORAGE/a\
        <group gid="media_rw" />\
        <group gid="sdcard_rw" />' $XML_mod
	    
	for PERM in $PERMS; do
	  cat <<BLOCK
    <permission name="android.permission.$PERM" >
        <group gid="media_rw" />
        <group gid="sdcard_rw" />
    </permission>"

BLOCK
	done >>$XML_mod

	echo "</permissions>" >>$XML_mod

	chown -R 0:0 $XML_mod_dir
	chcon -R u:object_r:system_file:s0 $XML_mod_dir
	chmod 644 $XML_mod
	
	# Export /system size for future re-patching
	du -s "$(echo "$Mirror" | sed 's/\/etc.*//')" | cut -f1 >$ModPath/.SystemSizeK
fi



if [ -n "$SEck" ]; then
	$was_enforcing && setenforce 1
fi
	
exit 0

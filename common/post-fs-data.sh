#!/system/bin/sh

# fbind Early Bird Service
# VR25 @ XDA Developers

# Prepare Environment
export PATH=/dev/magisk/bin:$PATH
MODPATH=${0%/*}


# Auto-update platform.xml (to fix storage access permissions) across ROM updates
if [ "$(cat $MODPATH/.InstallSystemSizeK)" -ne "$(du -s /dev/magisk/mirror/system | cut -f1)" ]; then
	XML_orig=/dev/magisk/mirror/system/etc/permissions/platform.xml
	XML_mod_dir=$MODPATH/system/etc/permissions
	XML_mod=$XML_mod_dir/platform.xml

	[ -d $XML_mod_dir ] || mkdir -p -m 755 $XML_mod_dir
	cp $XML_orig $XML_mod

	
	sed -i '/WRITE_MEDIA_STORAGE\" >/a\
			<group gid="media_rw" \/>\
			<group gid="sdcard_rw" \/>' $XML_mod
	
	sed -i '/WRITE_MEDIA_STORAGE\" \/>/a\
			<group gid="media_rw" \/>\
			<group gid="sdcard_rw" \/>\
		<\/permission>' $XML_mod
	sed -i '/WRITE_MEDIA_STORAGE\" \/>/s/\/>/>/' $XML_mod

	sed -i '/WRITE_EXTERNAL_STORAGE\" >/a\
			<group gid="media_rw" \/>\
			<group gid="sdcard_rw" \/>' $XML_mod
	
	sed -i '/WRITE_EXTERNAL_STORAGE\" \/>/a\
			<group gid="media_rw" \/>\
			<group gid="sdcard_rw" \/>\
		<\/permission>' $XML_mod
	sed -i '/WRITE_EXTERNAL_STORAGE\" \/>/s/\/>/>/' $XML_mod


	chmod 644 $XML_mod
	echo "$(du -s /dev/magisk/mirror/system | cut -f1)" > $MODPATH/.InstallSystemSizeK
fi


# data/data cleanup
list=/data/.fbind_cleanup_list
if [ -f $list ]; then
	exec &>/data/_fbind/app_data_cleanup.log
	echo "$(date)"
	echo
	source $list
	rm -f $list
fi
exit 0

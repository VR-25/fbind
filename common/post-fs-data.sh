#!/system/bin/sh

# fbind Early Bird Service
# VR25 @ XDA Developers


# Use Magisk's internal busybox
export PATH=/system/xbin:/sbin:/dev/magisk/bin

source /magisk/fbind/core.sh

# Fix storage access (MM)
if grep -v '#' $config_file | grep -q 'perm '; then
	pkg_list="$(grep -v '#' $config_file | grep 'perm ' | sed 's/perm //')"
	until [ -f /data/system/packages.xml ]; do sleep 0.1; done
	for name in $pkg_list; do
		: #awk_script
	done
	mount -o bind /data/_fbind/.packages.xml /data/system/packages.xml
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
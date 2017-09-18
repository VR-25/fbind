#!/system/bin/sh

# fbind Early Bird Service
# VR25 @ XDA Developers


# Environment prep
export PATH=/system/xbin:/sbin:/dev/magisk/bin
source /magisk/fbind/core.sh


# Add storage access permissions to /data/system/packages.xml
modXML=/data/_fbind/.packages.xml
origXML=/data/system/packages.xml
TMP_XML=/data/_fbind/.packages.tmp

if [ "$modXML" -ot "$config_file" ]; then # To avoid unnecessary repetition
	if grep -v '#' $config_file | grep -q 'perm '; then
		pkg_list="$(grep -v '#' $config_file | grep 'perm ' | sed 's/perm //')"
		until [ -f $origXML ]; do sleep 0.1; done
		for pkg_name in $pkg_list; do
			if [ ! -f $modXML ]; do # Process the modified xml if it already exists. Otherwise, work with the original file.
				awk -v prog="^""$pkg_name" 'BEGIN { RS = "<package name=\"" ; FS = "</perms>" } ; NR == 1 ; $1 ~ prog { print RS $1 "<item name=\"android.permission.WRITE_MEDIA_STORAGE\" granted=\"true\" flags=\"0\" />\n" FS $2 } ; NR != 1 && $1 !~ prog && $2 == "" { print RS $1 } ; NR != 1 && $1 !~ prog && $2 != "" { print RS $1 ; for (i = 2; i <= NF; i++) print FS $i }' $origXML > $modXML
			else	
				awk -v prog="^""$pkg_name" 'BEGIN { RS = "<package name=\"" ; FS = "</perms>" } ; NR == 1 ; $1 ~ prog { print RS $1 "<item name=\"android.permission.WRITE_MEDIA_STORAGE\" granted=\"true\" flags=\"0\" />\n" FS $2 } ; NR != 1 && $1 !~ prog && $2 == "" { print RS $1 } ; NR != 1 && $1 !~ prog && $2 != "" { print RS $1 ; for (i = 2; i <= NF; i++) print FS $i }' $modXML > $TMP_XML
				mv -f $TMP_XML $modXML
			fi
		done
		chmod 660 $modXML
		mount --bind $modXML $origXML
		#rm -f $origXML
		#ln -s $modXML $origXML
		#chmod 660 $modXML $origXML
	fi
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
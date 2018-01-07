rm $info_dir/* $fbind_dir/.config/* 2>/dev/null
rmdir $fbind_dir/.config 2>/dev/null

if grep '#' $config_file | grep -q 'part ' && ! grep '#' $config_file | grep -q '\-\-L'; then
	sed "/part /a\
		extsd_path `grep 'part ' $config_file | awk '{print $3}'`" $config_file
	if grep '#' $config_file | grep -q luks; then
		sed -i "s/luks/ /; /`grep 'part ' $config_file | awk '{print $3}'`/a\-\-L" $config_file
	fi
fi 2>/dev/null

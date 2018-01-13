rm $info_dir/* $fbind_dir/.config/* 2>/dev/null
rmdir $fbind_dir/.config 2>/dev/null

if grep -q luks $config_file; then
	sed -i "s/luks/ /; /`grep 'part ' $config_file | awk '{print $3}'`/a\-\-L" $config_file
	sed -i "/part /a\
		extsd_path `grep 'part ' $config_file | awk '{print $3}'`" $config_file
fi 2>/dev/null

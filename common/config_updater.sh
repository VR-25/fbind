{ [ -d $fbind_dir ] || mv /data/_fbind $fbind_dir
rm $info_dir/changelog*
sed -i 's/cryptsetup=true/luks' $config_file
sed -i 's/cryptsetup=true/luks' $fbind_dir/.config/misc; } 2>/dev/null
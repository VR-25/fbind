{ #rm -rf $fbind_dir && mkdir $fbind_dir
rm -f $fbind_dir/.config/Uvars
rm -f $info_dir/config_sample.txt
sed -i '/perm/d' $config_file
} 2>/dev/null

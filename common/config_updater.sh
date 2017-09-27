{ #rm -rf $fbind_dir && mkdir $fbind_dir
rm -rf $fbind_dir/.config
rm -f $info_dir/config_sample.txt
sed -i '/extsd_path \/mnt/d' $config_file
} 2>/dev/null

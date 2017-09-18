{ # Migrate old config file to new location
old_fbind_dir=/data/media/0/fbind
[ -d $fbind_dir ] || mkdir $fbind_dir

[ -f /data/media/0/fbind_list.txt ] && mv /data/media/0/fbind_list.txt $config_file
[ -f /data/media/0/fbind_config.txt ] && mv /data/media/0/fbind_config.txt $config_file
[ -f $old_fbind_dir/fbind_list.txt ] && mv $old_fbind_dir/fbind_list.txt $config_file
[ -f $old_fbind_dir/fbind_config.txt ] && mv $old_fbind_dir/fbind_config.txt $config_file

mv $config_file $INSTALLER
rm -rf $old_fbind_dir
#rm -rf $fbind_dir
#mkdir $fbind_dir
mv $INSTALLER/config.txt $config_file


# Remove obsolete config
sed -i /internal_storage_path/d $config_file
sed -i /obb_path/d $config_file


# Change "kill *" to "cleanup"
grep 'kill ' $config_file > $INSTALLER/tmp
sed -i '/kill /d' $config_file

kill() {
	if ! grep -q 'cleanup ' $INSTALLER/tmp2; then echo -n "cleanup \"$2\" " > $INSTALLER/tmp2
	else echo -n " \"$2\"" >> $INSTALLER/tmp2
	fi
}
source $INSTALLER/tmp
cat $INSTALLER/tmp2 >> $config_file


# Undo cleanup array
grep 'cleanup ' $config_file > $INSTALLER/tmp
sed -i '/cleanup /d' $config_file
: > $INSTALLER/tmp2
list=$(sed 's/cleanup //' $INSTALLER/tmp)
for f in $list; do
	[ "$f" ] && echo "cleanup $f" >> $INSTALLER/tmp2
done
cat $INSTALLER/tmp2 >> $config_file


# Change "from_to -e" to "bind_mnt"
grep 'from_to -e ' $config_file > $INSTALLER/tmp
sed -i '/from_to -e /d' $config_file
: > $INSTALLER/tmp2
from_to() {
	echo "bind_mnt \"$3\" \"$2\"" >> $INSTALLER/tmp2
}
source $INSTALLER/tmp
cat $INSTALLER/tmp2 >> $config_file


# Bind-mount /data/_fbind /data/media/0/_fbind
mkdir -m 777 /data/media/0/_fbind
} 2>/dev/null

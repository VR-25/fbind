set_perm $MODPATH/system/bin/fbind 0 2000 0755
rm $MODPATH/TODO.txt $MODPATH/License.md

dataDir=/data/adb/vr25/fbind
mkdir -p $dataDir
unzip -o "$ZIPFILE" README.md -d $dataDir/ >&2

# Preserve FUSE state
if [ -f $dataDir/.FUSE ] || [ /data/adb/modules/fbind/system.prop ]; then
  mv $MODPATH/FUSE.prop $MODPATH/system.prop
fi

# Migrate old config and remove legacy fbind
[ -f $dataDir/config.txt ] || cp /data/adb/fbind*/config.txt $dataDir/ 2>/dev/null
rm -rf /data/adb/fbind* /data/adb/modules/fbind /sdcard/Download/fbind /sdcard/*fbind*.txt 2>/dev/null

# Print links and changelog
printf '\n\n'
sed -En "\|## LINKS|,\$p" $dataDir/README.md \
  | grep -v '^---' | sed 's/^## //'
printf '\n\n'

# Make executable readily available
executable=$MODPATH/system/bin/fbind
tmpd=/dev/.vr25/fbind
mkdir -p $tmpd
ln -fs $executable $tmpd/
ln -fs $executable /sbin/ 2>/dev/null

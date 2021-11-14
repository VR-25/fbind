dataDir=/data/adb/vr25/fbind-data
[ -d ${dataDir%-*} ] && [ ! -d $dataDir ] && mv ${dataDir%-*} $dataDir ###
mkdir -p $dataDir
unzip -o "$ZIPFILE" README.md -d $dataDir/ >&2

# Preserve FUSE state
if [ -f $dataDir/.FUSE ] || [ -f /data/adb/modules/fbind/system.prop ]; then
  mv $MODPATH/FUSE.prop $MODPATH/system.prop
fi

# Migrate old config and remove legacy fbind
[ -f $dataDir/config.txt ] || cp /data/adb/fbind*/config.txt $dataDir/ 2>/dev/null
rm -rf ${dataDir%-*} /data/adb/fbind* /sdcard/Download/fbind /sdcard/*fbind*.txt 2>/dev/null

# Make executable readily available
executable=$MODPATH/system/bin/fbind
tmpd=/dev/.vr25/fbind
mkdir -p $tmpd
ln -fs $executable $tmpd/
ln -fs $executable /sbin/ 2>/dev/null

# Install bindfs binary
oPWD="$PWD"
cd $MODPATH/bin/bindfs-* && {
  case $ARCH in
    arm) mv bindfs-armeabi-v7a ../bindfs;;
    arm64) mv bindfs-arm64-v8a ../bindfs;;
    x86) mv bindfs-x86 ../bindfs;;
    x64) mv bindfs-x86_64 ../bindfs;;
  esac
  chmod +x ../bindfs
  rm -rf $MODPATH/bin/bindfs-*
  # workaround for bindfs < 1.14.2
  for i in /system/etc/group /system/etc/passwd; do
    [ -f $i ] || {
      mkdir -p $MODPATH${i%/*}
      touch $MODPATH$i
    }
  done
}

cd $MODPATH
rm -rf TODO.txt License.md README.html "android 11 test" zip.sh
cd "$oPWD"

set_perm $MODPATH/system/bin/fbind 0 2000 0755

# Print links and changelog
printf '\n\n'
sed -En "\|## LINKS|,\$p" $dataDir/README.md \
  | grep -v '^---' | sed 's/^## //'
printf '\n\n'

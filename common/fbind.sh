#!/system/bin/sh
# fbind persist props reverter
# Copyright (C) 2018, VR25 @ xda-developers
# License: GPL v3+


set -u

modID=fbind
modData=/data/media/$modID
config=$modData/config.txt
logsDir=$modData/logs
newLog=$logsDir/revert_props.log
oldLog=$logsDir/revert_props_old.log

modPath=/sbin/.core/img/$modID
[ -f $modPath/module.prop ] || modPath=/magisk/$modID

revert_props() {
  for prop in persist.esdfs_sdcard \
    persist.sys.sdcardfs \
    persist.fuse_sdcard
  do
    (rm /data/property/$prop 2</dev/null) &
  done
  wait
}

# verbose generator
mkdir -p $logsDir 2>/dev/null
[ -f "$newLog" ] && mv $newLog $oldLog
set -x 2>>$newLog

# if $modID is not installed, revert persist props, then cleanup & self-destruct
if [ ! -f $modPath/module.prop ]; then
  revert_props
  mv -f $newLog /sdcard/$modID.log
  { mv -f $config /sdcard/${modID}_config_bkp.log
  rm -rf $modData; } 2>/dev/null
  rm $0
  exit 0
fi

# revert persist props if $modID is disabled
[ -f $modPath/disable ] && revert_props

exit 0

#!/system/bin/sh
# fbind Early Bird
# Copyright (C) 2017-2018, VR25 @ xda-developers
# License: GPL v3+


modID=fbind
modPath=${0%/*}
modData=/data/media/$modID
config=$modData/config.txt
logsDir=$modData/logs
newLog=$logsDir/post-fs-data.sh.log
oldLog=$logsDir/post-fs-data.sh_old.log


# verbosity engine
mkdir -p $logsDir 2>/dev/null
[[ -f $newLog ]] && mv $newLog $oldLog
set -x 2>>$newLog


# disable ESDFS & SDCARDFS and enable FUSE (aggressive mode, fail-safe)
# this is necessary for bind-mounts to sdcard and storage permissions fix
while read prop; do
  resetprop $prop
  setprop $prop
done <<PROPS
persist.esdfs_sdcard false
persist.sys.sdcardfs force_off
persist.fuse_sdcard true
ro.sys.sdcardfs false
PROPS


# intelligently handle SELinux mode
grep -q '^setenforce 0' $config 2>/dev/null \
  && setenforce 0
grep -q '^setenforce auto' $config 2>/dev/null \
  && SELinuxAutoMode=true || SELinuxAutoMode=false
SEck="$(echo -e "$(which sestatus)\n$(which getenforce)" | grep . | head -n1)"

if [ -n "$SEck" ] && $SELinuxAutoMode; then
  if $SEck | grep -iq enforcing; then
    wasEnforcing=true
    setenforce 0
  else
    wasEnforcing=false
  fi
fi



# patch platform.xml -- storage permissions
xmlModDir=$modPath/system/etc/permissions
TMPDIR=/dev/fbind_tmp

sysMirror="$(dirname "$(find /sbin/.core/mirror/system \
  /dev/magisk/mirror/system -type f -name build.prop \
  2>/dev/null | head -n1)")"

if [ -f "$sysMirror/build.prop" ]; then

  mkdir $TMPDIR
  cp -f $sysMirror/etc/permissions/platform.xml $TMPDIR/

  grep -q '_.*NAL_STO.*/>$' $TMPDIR/platform.xml \
    && unpatched=true \
    || unpatched=false

  if $unpatched; then
    if [ "$(cat $modPath/.systemSizeK 2>/dev/null)" != "$(du -s "$sysMirror" | cut -f1)" ]; then
      sed -i '/<\/permissions>/d' $TMPDIR/platform.xml
      echo >>$TMPDIR/platform.xml

      Perms="READ_EXTERNAL_STORAGE
      WRITE_EXTERNAL_STORAGE"

      for Perm in $Perms; do
        if grep $Perm $TMPDIR/platform.xml | grep -q '/>'; then
          sed -i /$Perm/d $TMPDIR/platform.xml
          if echo $Perm | grep -q READ; then
            cat <<BLOCK >>$TMPDIR/platform.xml
    <permission name="android.permission.READ_EXTERNAL_STORAGE" >
        <group gid="sdcard_r" />
    </permission>"
BLOCK
          else
            cat <<BLOCK >>$TMPDIR/platform.xml
    <permission name="android.permission.WRITE_EXTERNAL_STORAGE" >
        <group gid="media_rw" />
        <group gid="sdcard_r" />
        <group gid="sdcard_rw" />
    </permission>"
BLOCK
          fi
        fi
      done

      echo -e "\n</permissions>" >>$TMPDIR/platform.xml

      mkdir -p $xmlModDir 2>/dev/null
      mv -f $TMPDIR/platform.xml $xmlModDir
      chmod -R 755 $xmlModDir
      chmod 644 $xmlModDir/platform.xml
      chcon 'u:object_r:system_file:s0' $xmlModDir/platform.xml

      # export /system size for automatic re-patching across ROM updates
      du -s $sysMirror | cut -f1 >$modPath/.systemSizeK
    fi
  fi
else
  echo -e "\n(!) sysMirror not found"
  echo -e "ls: $(ls $sysMirror)\n"
fi



rm -rf $TMPDIR
rm $modData/.no_restore 2>/dev/null


if [ -n "$SEck" ] && $SELinuxAutoMode; then
  $wasEnforcing && setenforce 1
fi

exit 0

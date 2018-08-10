#!/system/bin/sh
# fbind Early Bird
# Copyright (C) 2017-2018, VR25 @ xda-developers
# License: GPL v3+


modID=fbind
modPath=${0%/*}
modData=/data/media/$modID
logsDir=$modData/logs
newLog=$logsDir/post-fs-data.sh_verbose_log.txt
oldLog=$logsDir/post-fs-data.sh_verbose_previous_log.txt


# verbosity engine
mkdir -p $logsDir 2>/dev/null
[[ -f $newLog ]] && mv $newLog $oldLog
set -x 2>>$newLog


# intelligently handle SELinux mode
grep -v '^#' $modData/config.txt 2>/dev/null | grep -q 'setenforce 0' && setenforce 0
grep -v '^#' $modData/config.txt 2>/dev/null | grep -q 'setenforce auto' \
  && SELinuxAutoMode=true || SELinuxAutoMode=false
SEck="$(ls -1 $(echo "$PATH" | sed 's/:/ /g') 2>/dev/null | grep -E 'sestatus|getenforce' | head -n1)"

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

xmlList="/sbin/.core/mirror/system/etc/permissions/platform.xml
/dev/magisk/mirror/system/etc/permissions/platform.xml"

mkdir /dev/fbind_tmp

for f in $xmlList; do
  if [ -f "$f" ]; then
    cp "$f" /dev/fbind_tmp
    Mirror="$(echo $f | sed 's/\/etc.*//')"
    break
  fi
done

grep -q '_.*NAL_STO.*/>$' /dev/fbind_tmp/platform.xml && Patch=true || Patch=false

if $Patch && [ "$(cat $modPath/.systemSizeK)" -ne "$(du -s "$Mirror" | cut -f1)" ]; then
  sed -i '/<\/permissions>/d' /dev/fbind_tmp/platform.xml
  echo >>/dev/fbind_tmp/platform.xml

  Perms="READ_EXTERNAL_STORAGE
  WRITE_EXTERNAL_STORAGE"

  for Perm in $Perms; do
    if grep $Perm /dev/fbind_tmp/platform.xml | grep -q '/>'; then
      sed -i /$Perm/d /dev/fbind_tmp/platform.xml
      if echo $Perm | grep -q READ; then
        cat <<BLOCK >>/dev/fbind_tmp/platform.xml
    <permission name="android.permission.READ_EXTERNAL_STORAGE" >
        <group gid="sdcard_r" />
    </permission>"
BLOCK
      else
        cat <<BLOCK >>/dev/fbind_tmp/platform.xml
    <permission name="android.permission.WRITE_EXTERNAL_STORAGE" >
        <group gid="media_rw" />
        <group gid="sdcard_r" />
        <group gid="sdcard_rw" />
    </permission>"
BLOCK
      fi
    fi
  done

  echo -e "\n</permissions>" >>/dev/fbind_tmp/platform.xml

  mkdir -p $xmlModDir 2>/dev/null
  mv -f /dev/fbind_tmp/platform.xml $xmlModDir
  chmod -R 755 $xmlModDir
  chmod 644 $xmlModDir/platform.xml
  chcon 'u:object_r:system_file:s0' $xmlModDir/platform.xml

  # export /system size for automatic re-patching across ROM updates
    du -s "$(echo "$f" | sed 's/\/etc.*//')" | cut -f1 >$modPath/.systemSizeK
fi

rm -rf /dev/fbind_tmp
rm $modData/.no_restore 2>/dev/null

if [ -n "$SEck" ] && $SELinuxAutoMode; then
  $wasEnforcing && setenforce 1
fi

exit 0

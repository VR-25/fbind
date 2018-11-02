#!/system/bin/sh
# service.sh (fbind auto-bind script)
# Copyright (C) 2017-2018, VR25 @ xda-developers
# License: GPL v3+


# if service.sh already ran, exit
[ -f /dev/fbind/service.sh.ran ] && rm /dev/fbind/service.sh.ran && exit 0

modPath=$(sed -n 's/^.*MOUNTPATH=//p' /data/adb/magisk/util_functions.sh)/fbind
log=/data/media/fbind/logs/service.sh.log

if [ -d $modPath ]; then
  [ -f $modPath/disable ] && exit 0
else
  rm $0
  exit 0
fi

# default perms
umask 000

# log
mkdir -p ${log%/*}
[ -f $log ] && mv $log $log.old
exec 1>$log 2>&2

# exit trap (debugging tool)
debug_exit() {
  local e=$?
  echo -e "\n"
  echo -e "\n***EXIT $e***\n"
  set
  echo
  echo "SELinux status: $(getenforce 2>/dev/null || sestatus 2>/dev/null)" \
    | sed 's/En/en/;s/Pe/pe/'
  mkdir -p /dev/fbind
  touch /dev/fbind/service.sh.ran
  exit $e
}
trap debug_exit EXIT

source $modPath/core.sh

apply_config
echo -e '\n'

if grep -Eq '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target ' $config; then
  bind_folders
else
  echo -e "\nFOLDER BONDS>\n- Nothing to bind-mount"
fi

echo -e '\n'

if [ -f $modData/cleanup.sh ] || grep -q '^cleanup ' $config; then
  cleanupf
else
  echo -e "\nCLEANUP\n- Nothing to clean"
fi

sed -i "s:intsd:$intsd:g; s:extsd:$extsd:g; s:obb:$obb:g; s:extobb:$extobb:g" $log
exit 0

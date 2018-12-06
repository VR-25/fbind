#!/system/bin/sh
# fbind init
# Copyright (C) 2017-2018, VR25 @ xda-developers
# License: GPL V3+


(umask 000
modPath=/system/etc/fbind
log=/data/media/fbind/logs/fbind-boot-$(getprop ro.product.device | grep . || getprop ro.build.product).log
[ -e $modPath/module.prop ] || modPath=/sbin/.core/img/fbind
[ -e $modPath/module.prop ] || modPath=/sbin/.magisk/img/fbind

# log
mkdir -p ${log%/*}
[ -f $log ] && mv $log $log.old
exec 1>$log 2>&1
date
grep versionCode $modPath/module.prop
echo "Device=$(getprop ro.product.device | grep . || getprop ro.build.product)"
echo
set -x
 
. $modPath/core.sh
apply_config # and mount partitions & loop devices
grep -Eq '^int_extf|^bind_mount |^obb.*|^from_to |^target ' $config && bind_mount_wrapper
grep -q '^remove ' $config && remove_wrapper
exit 0 &) &

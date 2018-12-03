#!/sbin/sh
# fbind Config Patcher
# Copyright (C) 2018, VR25 @ xda-developers
# License: GPL V3+


# backup
cp $config ${config/./_backup.}

# remove filesystem arguments
grep -q '^part ' $config && sed -i '/^part .*/s/ f2fs//g; /s/ ext.//g; \
  /s/ fat32//g; /s/ vfat//g; /s/ exfat//g; /s/ fat//g' $config

# remove <setenforce x> lines
grep -q '^setenforce ' $config && sed -i '/^setenforce/d' $config

# remove fsck lines
grep -Eq '^fsck|^e2fsck' $config && sed -i '/^fsck/d; /^e2fsck/d' $config

# rename "cleanup " to "remove "
grep -q '^cleanup ' && sed -i 's/^cleanup /remove /g' $config

# rename bind_mnt to bind_mount
grep -q '^bind_mnt ' && sed -i 's/^bind_mnt /bind_mount /g' $config

# rename LOOP to loop
grep -q '^LOOP ' && sed -i 's/^LOOP /loop /g' $config

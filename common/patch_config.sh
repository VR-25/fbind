#!/sbin/sh
# patch_config.sh (fbind config patcher)
# Copyright (C) 2018, VR25 @ xda-developers

if [ -f $config ] && [ $curVer -lt 201811020 ] && grep -q 'part ' $config; then
  cp -f $config $config.$(date +%Y%m%d%H%M%S) # backup

  # remove filesystem arguments
  sed -i '/part .*/s/ f2fs /g; /s/ ext2 /g; /s/ ext3 /g; /s/ ext3 /g; \
    /s/ ext4 /g; /s/ fat /g; /s/ vfat /g; /s/ exfat /g' $config

  # remove <setenforce x> lines
  sed -i /setenforce/d $config

  # remove fsck lines
  sed -i '/^fsck/d; /^e2fsck/d' $config
fi

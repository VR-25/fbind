#!/sbin/sh
# patch config & remove obsolete data


# restore config
[ -e $config ] || cp -af /sdcard/fbind_config_backup.txt $config 2>/dev/null


# backup
[ $curVer -lt 201812140 ] && [ -e $config ] \
  && cp -f $config ${config/./_backup.}


if [ $curVer -lt 201812030 ]; then

  cd /data/property/

  # remove obsolete files
  rm -rf *esdfs_sdcard *fuse_sdcard *sys.sdcardfs \
    ${config%/*}/logs/ /storage/*/.fbind_bkp/ /external_sd/.fbind_bkp/ \
    $MOUNTPATH0/.core/*/fbind.sh ${config%/*}/*tmp* 2>/dev/null

  if   [ -e $config ]; then
    # remove filesystem arguments
    sed -i '/^part .*/s/ f2fs//g; /s/ ext.//g; \
      /s/ fat32//g; /s/ vfat//g; /s/ exfat//g; /s/ fat//g' $config

    # remove <setenforce x> lines
    sed -i '/^setenforce/d' $config

    # remove fsck lines
    sed -i '/^fsck/d; /^e2fsck/d' $config

    # rename "cleanup " to "remove "
    sed -i 's/^cleanup /remove /g' $config

    # rename bind_mnt to bind_mount
    sed -i 's/^bind_mnt /bind_mount /g' $config

    # rename LOOP to loop
    sed -i 's/^LOOP /loop /g' $config
  fi
fi


# remove obsolete config backups
[ $curVer -lt 201812040 ] && rm $config.2018* 2>/dev/null

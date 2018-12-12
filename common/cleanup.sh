#!/sbin/sh
# patch config & remove obsolete data


if [ $curVer -lt 201812120 ] && [ -e $config ]; then
  # backup
  cp -f $config ${config/./_backup.}
fi


if [ $curVer -lt 201812030 ]; then

  cd /data/property/

  rm -rf *esdfs_sdcard *fuse_sdcard *sys.sdcardfs \
    ${config%/*}/logs/ /storage/*/.fbind_bkp/ /external_sd/.fbind_bkp/ \
    $MOUNTPATH0/.core/*/fbind.sh ${config%/*}/*tmp* 2>/dev/null

  if   [ -e $config ]; then
    # remove filesystem arguments
    grep -q '^part ' $config && sed -i '/^part .*/s/ f2fs//g; /s/ ext.//g; \
      /s/ fat32//g; /s/ vfat//g; /s/ exfat//g; /s/ fat//g' $config

    # remove <setenforce x> lines
    grep -q '^setenforce ' $config && sed -i '/^setenforce/d' $config

    # remove fsck lines
    grep -Eq '^fsck|^e2fsck' $config && sed -i '/^fsck/d; /^e2fsck/d' $config

    # rename "cleanup " to "remove "
    grep -q '^cleanup ' $config && sed -i 's/^cleanup /remove /g' $config

    # rename bind_mnt to bind_mount
    grep -q '^bind_mnt ' $config && sed -i 's/^bind_mnt /bind_mount /g' $config

    # rename LOOP to loop
    grep -q '^LOOP ' $config && sed -i 's/^LOOP /loop /g' $config
  fi
fi


[ $curVer -lt 201812040 ] && rm $config.2018* 2>/dev/null


if [ $curVer -lt 201812120 ] && [ -e $config ]; then
  # rename "$defaultRuntime/emulated" to "$prefix"
  grep -q '$defaultRuntime/emulated' $config \
    && sed -i 's|$defaultRuntime/emulated|$prefix|g' $config
fi

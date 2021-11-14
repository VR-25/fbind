#!/system/bin/sh
# this is a bind mount test script
# vr25

: ${sd_partition:=/dev/block/mmcblk1p1}
: ${mnt_opts_fat:=nosuid,nodev,noexec,noatime,context=u:object_r:sdcardfs:s0,uid=0,gid=9997,fmask=0117,dmask=0006}
: ${prefix:=/mnt/runtime/write}
#: ${prefix:=/mnt/runtime/full}
#: ${prefix:=/mnt/pass_through/0}
: ${internal:=$prefix/emulated/0}
: ${external:=/mnt/extsd}

# replace "each" space character with --
: ${bonds:=#$external/.WhatsApp==$internal/WhatsApp
#$external/.random--dir==$internal/random--dir}

bind() {
  mkdir -p "$@"
  mount -o bind "$@"
}

mount() {
  su -Mc /system/bin/mount "$@"
}

while [ ! -b $sd_partition ]; do sleep 2; done
fs=$(blkid $sd_partition | sed 's/.*TYPE=\"\(.*\)\".*/\1/')
echo "$fs" | grep -q 'fat$' || exit

mkdir -p $external
! mountpoint -q $external && mount -t $fs -o $mnt_opts_fat $sd_partition $external || exit

bonds="$(echo "$bonds" | grep -Ev '^$|^#')"
for i in $external==$internal/.extsd $bonds; do
  i1="$(echo $i | sed -e 's/==.*//' -e 's/--/ /g')"
  i2="$(echo $i | sed -e 's/.*==//' -e 's/--/ /g')"
  umount -f "$i2" 2>/dev/null
  bind "$i1" "$i2"
done

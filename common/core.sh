# fbind core
# Copyright (C) 2017-2019, VR25 @ xda-developers
# License: GPL V3+


altExtsd=false
tmpf=/dev/fbind/tmpf
intsd=/data/media/0
obb=/data/media/obb
modData=/data/adb/fbind
config=$modData/config.txt
alias mount="/sbin/su -Mc mount -o rw,noatime"
[ -z "$interactiveMode" ] && interactiveMode=false


is_mounted() { mountpoint -q "$1" 2>/dev/null; }


wait_until_true() {
  local count=0
  until [ $count -ge 1800 ]; do
    count=$((count + 2))
    if [ -n "$1" ]; then
      $@ && break || sleep 2
    else
      is_mounted /storage/emulated && break || sleep 2
    fi
  done
  grep /storage/emulated /proc/mounts | grep -Eiq ' sdcardfs | fuse ' || exit 1
  if [ -n "$1" ]; then
    $@ || return 1
  else
    is_mounted /storage/emulated || return 1
  fi
}


wait_storage() {
  if echo "$@" | grep -Eq '/data/media/[1-9]|/storage/emulated|/mnt/runtime/default/'; then
    wait_until_true || return 1
  fi
  if echo "$@" | grep -q /mnt/media_rw/; then
    wait_until_true grep -q /mnt/media_rw/ /proc/mounts || return 1
  fi
  :
}


bind_mount() {
  if ! is_mounted "$2"; then
    if $interactiveMode; then
      echo
      echo "<$1> <$2>"
    else
      wait_storage $@
      [ $? -ne 0 ] && return 1
    fi
    mkdir -p "$1" "$2"
    mount -o rbind \""$1"\" \""$2"\"
    if grep -iq '/storage/emulated sdcardfs' /proc/mounts && echo "$@" | grep -q $prefix; then
      if echo "$extsd" | grep -q $prefix; then
        $interactiveMode && echo "<${1/default/read}>" "<${2/default/read}>"
        if ! mount -o remount,gid=9997,mask=6 \""${2/default/read}"\" 2>/dev/null; then
          mount -o rbind,gid=9997,mask=6 \""${1/default/read}"\" \""${2/default/read}"\" \
            && mount -o remount,gid=9997,mask=6 \""${2/default/read}"\"
        fi
        if ! grep -iq noWriteRemount $config && ! [ -e $modData/.noWriteRemount ]; then # some systems lock and reboot if this is remounted
          touch $modData/.noWriteRemount
          $interactiveMode && echo "<${1/default/write}>" "<${2/default/write}>"
          if ! mount -o remount,gid=9997,mask=6 \""${2/default/write}"\" 2>/dev/null; then
            mount -o rbind,gid=9997,mask=6 \""${1/default/write}"\" \""${2/default/write}"\" \
              && mount -o remount,gid=9997,mask=6 \""${2/default/write}"\"
          fi
          rm $modData/.noWriteRemount
        fi
      else
        $interactiveMode && echo "<$1>" "<${2/default/read}>"
        mount -o rbind \""$1"\" \""${2/default/read}"\"
        if ! grep -iq noWriteRemount $config && ! [ -e $modData/.noWriteRemount ]; then # some systems lock and reboot if this is remounted
          touch $modData/.noWriteRemount
          $interactiveMode && echo "<$1>" "<${2/default/write}>"
          mount -o rbind \""$1"\" \""${2/default/write}"\"
          rm $modData/.noWriteRemount
        fi
      fi
      if [ -e $modData/.noWriteRemount ]; then
        grep -q noWriteRemount $config || echo noWriteRemount >>$config
        rm $modData/.noWriteRemount
      fi
    fi
    if is_mounted "$2"; then
      [ -z "$3" ] && rm -rf "$1/Android" 2>/dev/null
    else
      rmdir "$2" 2>/dev/null
    fi
  fi
}


# set alternate intsd path
intsd_path() {
  intsd="$1"
}


# partition mounter
# $1: <block device>, $2: <mount point>, $3: "fsck [OPTION(s)]" (filesystem specific, optional)
part() {
  if echo "$1 $2" | grep -q '^\-o '; then # using extra mount options
    local extraOpts="$1 $2"
    shift 2
  fi
  local pPath=${1%--L*}
  local luksPass="${1#*--L,}"
  [ "$luksPass" = "$1" ] && luksPass=""
  local pName=$(echo ${1##*/} | sed 's/--L.*//')

  if ! is_mounted "$2"; then
    wait_storage $@
    [ $? -ne 0 ] && return 1
    mkdir -p "$2"
    wait_until_true [ -e $pPath ]

    if echo "$1" | grep -q '\-\-L'; then
      if $interactiveMode || [ -n "$luksPass" ]; then
        # open LUKS volume
        if [ -n "$luksPass" ]; then
          echo -n "$luksPass" | $modPath/bin/cryptsetup luksOpen $pPath $pName
        else
          $modPath/bin/cryptsetup luksOpen $pPath $pName
        fi
        [ -n "$3" ] && $3 /dev/mapper/$pName
        mount -t $($modPath/bin/fstype /dev/mapper/$pName) $(echo -n $extraOpts) /dev/mapper/$pName "$2"
      fi
    else
      # mount regular partition
      [ -n "$3" ] && $3 $pPath
      mount -t $($modPath/bin/fstype $pPath) $(echo -n $extraOpts) $pPath "$2"
    fi

    is_mounted "$2" || rmdir "$2" 2>/dev/null
  fi
}


# fallback sdcard path
default_extsd() {
  local dir="" size=0 newSize=0
  $interactiveMode || wait_until_true grep -q /mnt/media_rw /proc/mounts
  if grep -q /mnt/media_rw /proc/mounts; then
    for dir in /mnt/media_rw/* /mnt/media_rw/.*; do
      if [ -e "$dir" ]; then
        newSize=$(df $dir | tail -n1 | awk '{print $2}')
        if [ $newSize -gt $size ]; then
          size=$newSize
          extsd=$dir
        fi
      fi
    done
  fi
  is_mounted $extsd && extobb=$extsd/Android/obb || exit 1
}


# alternate extsd path
extsd_path() {
  altExtsd=true
  if [ $1 = $intsd ]; then
    extsd=$intsd
    extobb=$obb
  else
    extsd=$1
    extobb=$extsd/Android/obb
  fi
}


# mount loop device (loop <.img file> <mount point>)
loop() {
  wait_storage $@
  [ $? -ne 0 ] && return 1
  if ! is_mounted "$2"; then
    e2fsck -fy "$1"
    mkdir -p "$2"
    /sbin/su -Mc /sbin/imgtool mount "$1" "$2"
  fi
}


apply_config() {
  [ -e $config ] || cp -af /data/media/0/.fbind_config_backup.txt $config 2>/dev/null || touch $config
  grep -iq '^permissive' $config && setenforce 0
  # fsck sdcard
  if grep -v 'part ' $config | grep -q 'fsck.*mmcblk1' && ! $interactiveMode; then
    (until [ -e $(grep -v 'part ' $config | grep 'fsck.*mmcblk1' | awk '{print $3}') ]; do sleep 1; done
    fsck=$(grep -v 'part ' $config | grep 'fsck.*mmcblk1')
    $fsck) &
  fi
  # wait until data is decrypted
  set +x
  until [ -e /data/media/0/?ndroid ]; do sleep 2; done
  $interactiveMode || set -x
  [ $config -nt /data/media/0/.fbind_config_backup.txt ] \
    && cp -af $config /data/media/0/.fbind_config_backup.txt
  mkdir -p ${tmpf%/*}
  grep -E '^extsd_path |^intsd_path |^part |^loop ' $config >$tmpf
  . $tmpf
  rm $tmpf
  $altExtsd || default_extsd

  # SDcardFS mode
  if grep -iq '/storage/emulated sdcardfs' /proc/mounts; then
    prefix=/mnt/runtime/default
    intsd=$prefix/emulated/0
    obb=$intsd/Android/obb
    if echo "$extsd" | grep -q /mnt/media_rw/; then
      extsd0=$extsd
      extobb0=$extobb
      extsd=$prefix/${extsd##*/}
      extobb=$extsd/Android/obb
    fi
  fi
}


bind_mount_wrapper() {
  $interactiveMode && echo "Bind-mounting..."

  # $extobb <--> $obb
  obb() { bind_mount $extobb $obb; }

  # $extobb/$1 <--> $obb/$1
  obbf() { bind_mount $extobb/$1 $obb/$1; }

  # $extsd/<path> <--> $intsd/<same path>
  target() { bind_mount "$extsd/$1" "$intsd/$1" $2; }

  # $extsd/<path> <--> $intsd/<path>
  from_to() { bind_mount "$extsd/$2" "$intsd/$1" $3; }

  # $extsd/$1 <--> $intsd
  int_extf() {
    if [ -z "$1" ]; then
      bind_mount $extsd/.fbind $intsd
    else
      bind_mount "$extsd/$1" $intsd
    fi
    target Android
    target data
    obb
  }

  if [ -n "$1" ]; then
    grep -E '^int_extf|^bind_mount |^obb|^from_to |^target ' $config | grep -E "$1" >$tmpf
  else
    grep -E '^int_extf|^bind_mount |^obb|^from_to |^target ' $config >$tmpf
  fi
  . $tmpf
  rm $tmpf
  if $interactiveMode; then
    echo
    echo "- End"
  fi
}


# remove stubborn files/folders
remove_wrapper() {
  remove() {
    if [ -e "$intsd/$1" ] || [ -e "$extsd/$1" ]; then
      $interactiveMode && echo "- $1"
      rm -rf "$intsd/$1" "$extsd/$1" 2>/dev/null
    fi
  }
  [ -n "$1" ] && echo "remove \"$1\"" >$tmpf
  grep '^remove ' $config >>$tmpf
  . $tmpf
  rm $tmpf
}

# fbind core
# Copyright (C) 2017-2018, VR25 @ xda-developers
# License: GPL V3+


altExtsd=false
tmp=/dev/fbind/tmp
intsd=/data/media/0
obb=/data/media/obb
modData=/data/media/0/fbind
config=$modData/config.txt
alias mount="/sbin/su -Mc mount -o rw,noatime"
[ -z "$interactiveMode" ] && interactiveMode=false


is_mounted() { mountpoint -q "$1" 2>/dev/null; }


wait_until_true() {
  local count=0
  until [ $count -ge 1800 ]; do
    count=$((count + 1))
    if [ -n "$1" ]; then
      $@ && break || sleep 1
    else
      is_mounted /storage/emulated && break || sleep 1
    fi
  done
  grep -Eiq 'sdcardfs|fuse' /proc/mounts || exit 1
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
    if grep -iq sdcardfs /proc/mounts && echo "$@" | grep -q $prefix; then
      if echo "$extsd" | grep -q $prefix; then
        $interactiveMode && echo "<${1/default/read}>" "<${2/default/read}>"
        if ! mount -o remount,gid=9997,mask=6 \""${2/default/read}"\" 2>/dev/null; then
          mount -o rbind,gid=9997,mask=6 \""${1/default/read}"\" \""${2/default/read}"\" \
            && mount -o remount,gid=9997,mask=6 \""${2/default/read}"\"
        fi
        if ! grep -iq noWriteRemount $config; then # some systems lock and reboot if this is remounted
          $interactiveMode && echo "<${1/default/write}>" "<${2/default/write}>"
          if ! mount -o remount,gid=9997,mask=6 \""${2/default/write}"\" 2>/dev/null; then
            mount -o rbind,gid=9997,mask=6 \""${1/default/write}"\" \""${2/default/write}"\" \
              && mount -o remount,gid=9997,mask=6 \""${2/default/write}"\"
          fi
        fi
      else
        $interactiveMode && echo "<$1>" "<${2/default/read}>"
        mount -o rbind \""$1"\" \""${2/default/read}"\"
        if ! grep -iq noWriteRemount $config; then # some systems lock and reboot if this is remounted
          $interactiveMode && echo "<$1>" "<${2/default/write}>"
          mount -o rbind \""$1"\" \""${2/default/write}"\"
        fi
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


# mount partition
# $1: <block device>, $2: <mount point>, $3: "fsck [OPTION(s)]" (filesystem specific, optional)
part() {
  local pPath=${1%--L}
  local pName=$(echo ${1##*/} | sed 's/--L//')

  if ! is_mounted "$2"; then
    wait_storage $@
    [ $? -ne 0 ] && return 1
    mkdir -p "$2"
    wait_until_true [ -b $pPath ]

    if echo "$1" | grep -q '\-\-L'; then
      if $interactiveMode; then
        # open LUKS volume
        $modPath/bin/cryptsetup luksOpen $pPath $pName
        [ -n "$3" ] && $3 /dev/mapper/$pName
        mount -t $($modPath/bin/fstype /dev/mapper/$pName) /dev/mapper/$pName "$2"
      fi
    else
      # mount regular partition
      [ -n "$3" ] && $3 $pPath
      mount -t $($modPath/bin/fstype $pPath) $pPath "$2"
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
    /sbin/imgtool mount "$1" "$2"
  fi
}


apply_config() {
  mkdir -p ${tmp%/*}
  grep -E '^extsd_path |^intsd_path |^part |^loop ' $config >$tmp.3
  . $tmp.3
  $altExtsd || default_extsd

  # SDcardFS mode
  if grep -iq sdcardfs /proc/mounts; then
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
    grep -E '^int_extf|^bind_mount |^obb|^from_to |^target ' $config | grep -E "$1" >$tmp.3
  else
    grep -E '^int_extf|^bind_mount |^obb|^from_to |^target ' $config >$tmp.3
  fi
  . $tmp.3
  if $interactiveMode; then
    echo
    echo "- End"
  fi
}


# remove stubborn files/folders
remove_wrapper() {
  remove() {
    if [ -e "$intsd/$1" ] || [ -e "$extsd/$1" ]; then
      rm -rf "$intsd/$1" "$extsd/$1" 2>/dev/null
    fi
  }
  grep '^remove ' $config >$tmp.3
  . $tmp.3
}

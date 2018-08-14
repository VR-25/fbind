# fbind Core
# Copyright (C) 2017-2018, VR25 @ xda-developers
# License: GPL v3+


altExtsd=false
linuxFS=false
intsd=/data/media/0
obb=/data/media/obb
modData=/data/media/fbind
config=$modData/config.txt
newLog=$modData/logs/main.log
oldLog=$modData/logs/main_old.log
[ -z "$interactiveMode" ] && interactiveMode=false


ECHO() { $interactiveMode && echo; }

is_mounted() { mountpoint -q "$1" 2>/dev/null; }

wait_until_true() {
  Count=0
  until [ "$Count" -ge "90" ]; do
    ((Count++))
    if [ -n "$1" ]; then
      $@ && break || sleep 1
    else
      is_mounted /storage/emulated && break || sleep 1
    fi
  done
  if [ -n "$1" ]; then
    $@ || return 1
  else
    is_mounted /storage/emulated || return 1
  fi
}


# a "better" mount -o bind
bind_mnt() {
  if ! is_mounted "$2"; then
    ECHO
    [ -n "$3" ] && echo "$3" || echo "bind_mount [$1] [$2]"

    echo "$1 $2" | grep -Eq '/data/media/[1-9]|/storage/emulated/[1-9]' && (wait_until_true) &
    echo "$1 $2" | grep -Eq '/mnt/media_rw/' && (wait_until_true grep -q '/mnt/media_rw/' /proc/mounts) &
    wait

    mkdir -p -m 777 "$1" 2>/dev/null
    mkdir -p -m 777 "$2" 2>/dev/null
    mount -o bind "$1" "$2"
  fi
}


# set alternate intsd path
intsd_path() {
  intsd="$1"
}


# log engine
log_start() {
  [[ -f $newLog ]] && mv $newLog $oldLog
  exec &>$newLog
  echo -e "$(date)\n"
}
log_end() {
  sed -i "s:intsd:$intsd:g; s:extsd:$extsd:g; s:obb:$obb:g; s:extobb:$extobb:g" $newLog
  if [ -n "$SEck" ] && $SELinuxAutoMode; then
    $was_enforcing && setenforce 1
  fi
  rm $modData/.tmp 2>/dev/null
  exit 0
}


# mount partition
# $1=/block/device, $2=/mount/point, $3=filesystem, $4="fsck [OPTION(s)]" (filesystem specific, optional)
part() {
  if [ -z "$3" ]; then
    echo "(!) [part $1 $2 $3 $4]: missing/invalid argument(s)" && return 1
  else
    PARTITION="$(echo $1 | sed 's/.*\///; s/--L//')"
    PPath="$(echo $1 | sed 's/--L//')"

    if ! is_mounted "$2"; then
      echo "$1 $2" | grep -Eq '/data/media/[1-9]|/storage/emulated/[1-9]' && (wait_until_true) &
      echo "$1 $2" | grep -Eq '/mnt/media_rw/' && (wait_until_true grep -q '/mnt/media_rw/' /proc/mounts) &
      wait

      mkdir -p -m 777 "$2" 2>/dev/null
      wait_until_true [ -b "$PPath" ]

      if echo "$1" | grep -q '\-\-L' && $interactiveMode; then
        # open LUKS volume (manually)
        $modPath/bin/cryptsetup luksOpen $PPath $PARTITION
        [ -n "$4" ] && $4 /dev/mapper/$PARTITION
        mount -t $3 -o noatime,rw /dev/mapper/$PARTITION "$2"

      else
        # mount regular partition
        [ -n "$4" ] && $4 $PPath
        mount -t $3 -o noatime,rw $PPath "$2"
      fi

      if ! is_mounted "$2"; then
        echo "(!) Failed to mount $PARTITION" && rmdir "$2" 2>/dev/null
        return 1
      fi
    fi
  fi
}


# fallback sdcard path
default_extsd() {
  $interactiveMode || wait_until_true grep -q '/mnt/media_rw' /proc/mounts
  extsd="$(ls -1d /mnt/media_rw/* | head -n1)"
  if ! is_mounted "$extsd"; then
    extsd="$intsd"
    linuxFS=true
    extobb="$obb"
  else
    extobb="$extsd/Android/obb"
  fi
}


# set alternate extsd path
# extsd_path [/mount/point]
# extsd_path [/path/to/partition] [/auto/mount/point] [filesystem] ["fsck [options]"]
extsd_path() {
  altExtsd=true
  if [ "$1" = "$intsd" ]; then
    linuxFS=true
    extsd="$intsd"
    extobb="$obb"

  elif echo "$1" | grep -q mmcblk; then
    # EXPERIMENTAL -- mount user storage the old-school way
    # Unmount all FUSE mount points
    wait_until_true grep -q '/mnt/media_rw/' /proc/mounts

    if [ "$?" -eq "0" ]; then
      for m in $(grep -E '/storage/|/mnt/' /proc/mounts | awk '{print $2}'); do
        if [ "$?" -eq "0" ] && is_mounted $m; then umount -f $m; fi
      done

      for m in $(grep -E '/storage/|/mnt/' /proc/mounts | awk '{print $2}'); do
        if [ "$?" -eq "0" ] && is_mounted $m; then umount -f $m; fi
      done

      if [ "$?" -eq "0" ]; then
        # internal
        bind_mnt /data/media /mnt/runtime/default/emulated
        bind_mnt /data/media /storage/emulated
        bind_mnt /data/media /mnt/runtime/read/emulated
        bind_mnt /data/media /mnt/runtime/write/emulated

        # external
        [ -n "$4" ] && $4 "$1"
        mount -t $3 -o noatime,rw $1 $2
        bind_mnt $2/.android_secure /mnt/secure/asec
        ###
        bind_mnt $2 /mnt/runtime/default/$2
        bind_mnt $2 /storage/$2
        bind_mnt $2 /mnt/runtime/read/$2
        bind_mnt $2 /mnt/runtime/write/$2
        ###
      fi
    fi

  else
    extsd="$1"
    extobb="$extsd/Android/obb"
  fi
}


# mount loop device
# $1=/path/to/.img, $2=/mount/point
LOOP() {
  echo "$1 $2" | grep -Eq '/data/media/[1-9]|/storage/emulated/[1-9]' && (wait_until_true) &
  echo "$1 $2" | grep -Eq '/mnt/media_rw/' && (wait_until_true grep -q '/mnt/media_rw/' /proc/mounts) &
  wait
  is_mounted "$2" || { echo && e2fsck -fy "$1"; }
  mkdir -p -m 777 "$2" 2>/dev/null

  if ! is_mounted "$2"; then
    for Loop in 0 1 2 3 4 5 6 7; do
      loopDevice=/dev/block/loop$Loop
      [ -b "$loopDevice" ] || mknod $loopDevice b 7 $Loop 2>/dev/null
      losetup $loopDevice "$1" && mount -t ext4 -o loop $loopDevice "$2"
      is_mounted "$2" && break
    done
  fi

  if ! is_mounted "$2"; then
    echo -e "\n(!) Failed to mount $1\n"; return 1
  fi
}


apply_config() {
  echo "STORAGE INFORMATION"
  grep -E '^extsd_path |^intsd_path |^part |^LOOP ' $config >$modData/.tmp
  . $modData/.tmp
  $altExtsd || default_extsd

  grep -E '^part |^LOOP ' $config | \
  while read line; do
    target="$(echo "$line" | awk '{print $3}' | sed 's/"//g' | sed "s/'//g")"
    if is_mounted "$target"; then
      echo
      df -h "$target"
    fi
  done

  target() { grep -E '^part |^LOOP ' $config | awk '{print $3}' | sed 's/"//g' | sed "s/'//g"; }
  target | grep -q "$intsd" || { echo; df -h "$intsd"; }
  if ! target | grep -q "$extsd" && is_mounted "$extsd"; then
    echo
    df -h "$extsd"
  fi
  grep "$extsd" /proc/mounts | grep -Eiq 'ext[0-9]{1}|f2fs' 2>/dev/null && linuxFS=true

  # auto-backup config.txt
  configBkp=$extsd/.fbind_bkp/config.txt
  if [ "$configBkp" -ot "$config" ] \
    && grep -q '[a-z]' $config \
    && ! grep -q '^no_bkp' $config \
    && is_mounted "$extsd"
  then
      mkdir $extsd/.fbind_bkp 2>/dev/null
      mv $configBkp $extsd/.fbind_bkp/previous_config.txt
      rm $extsd/.fbind_bkp/last_config.txt 2>/dev/null ###
      $modPath/bin/rsync $config $configBkp
  fi
  echo
}


bind_folders() {
  $interactiveMode && echo "Bind-mounting..." || echo "BIND-MOUNT"

  # entire obb folder
  obb() { bind_mnt $extobb $obb "[obb] <--> [extobb]"; }

  # game/app obb folder
  obbf() { bind_mnt $extobb/$1 $obb/$1 "[obbf $1]"; }

  # target folder
  target() { bind_mnt "$extsd/$1" "$intsd/$1" "[intsd/$1] <--> [extsd/$1]"; }

  # source <--> destination
  from_to() { bind_mnt "$extsd/$2" "$intsd/$1" "[intsd/$1] <--> [extsd/$2]"; }

  # data/data/pkgName <--> $appData/pkgName
  app_data() {
    if [ -n "$2" ] && ! echo "$2" | grep '\-u'; then
      linuxFS=true
      appData="$2"
    else
      appData="$extsd/.app_data"
    fi
    if ! $linuxFS; then
      ECHO
      echo -e "(!) app_data() won't work without a Linux filesystem.\n"
    else
      ls /data/app 2>/dev/null | grep -q "$1" && bind_mnt "$appData/$1" /data/data/$1 "[/data/data/$1] <--> [\$appData/$1]"
    fi
  }

  # intsd <--> extsd/.fbind
  int_extf() {
    bind_mnt $extsd/.fbind $intsd "[int_extf]"
    { target Android
    target data
    obb; } &>/dev/null
  }
  if [ -n "$1" ]; then
    grep -E '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target ' $config | grep -E "$1" >$modData/.tmp
  else
    grep -E '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target ' $config >$modData/.tmp
  fi
  . $modData/.tmp
  ECHO
  echo -e "- End\n"
}


cleanupf() {
  echo "CLEANUP"
  cleanup() {
    ECHO
    if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ] || [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then echo "$1"; fi
    if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ]; then rm -rf "$intsd/$1"; fi
    if [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then rm -rf "$extsd/$1"; fi
  }
  grep '^cleanup ' $config >$modData/.tmp
  . $modData/.tmp

  # unwanted "Android" directories

  obb() { if is_mounted $obb && [ -z "$1" ]; then rm -rf $extobb/Android; fi; }

  obbf() { if is_mounted $obb/$1 && [ -z "$2" ]; then rm -rf $extobb/$1/Android; fi; }

  target() { if is_mounted "$intsd/$1" && [ -z "$2" ]; then rm -rf "$extsd/$1/Android"; fi; }

  from_to() { if is_mounted "$intsd/$1" && [ -z "$3" ]; then rm -rf "$extsd/$2/Android"; fi; }

  bind_mnt() { if is_mounted "$2" && [ -z "$3" ]; then rm -rf "$1/Android"; fi; }

  app_data() { is_mounted /data/data/$1 && rm -rf "$appData/$1/Android"; }

  grep -E '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target ' $config >$modData/.tmp
  . $modData/.tmp

  # source optional cleanup script
  if [ -f $modData/cleanup.sh ]; then
    echo "$modData/cleanup.sh"
    . $modData/cleanup.sh
    ECHO
  fi

  echo "- End"
  ECHO
} 2>/dev/null


# restore config backup
if ! grep -qs '[a-z]' "$config" && [ ! -f $modData/.no_restore ]; then
  echo "(i) Searching for config backup"
  BkpDir="$(find /mnt/media_rw -type d -name ".fbind_bkp" 2>/dev/null | head -n1)"
  if [ -f "$BkpDir/config.txt" ]; then
    echo "- Restoring config.txt"
    $modPath/bin/rsync "$BkpDir/config.txt" "$config"
  else
    echo "- Creating dummy config.txt"
    touch "$config"
    $interactiveMode || { echo "(!) No config found"; exit 1; }
  fi
  echo
fi

# fbind Core
# VR25 @ xda-developers


# ENVIRONMENT
altExtsd=false
linuxFS=false
intsd=/data/media/0
obb=/data/media/obb
fbindDir=/data/media/fbind
cfgFile=$fbindDir/config.txt
logFile=$fbindDir/logs/service.sh_main_log.txt
previousLogFile=$fbindDir/logs/service.sh_main_previous_log.txt
[[ -z $interactiveMode ]] && interactiveMode=false


is() { [ -$1 "$2" ]; }
n() { [ -n "$1" ]; }
z() { [ -z "$1" ]; }


get_prop() {
	FILE="$2"
	z "$FILE" && FILE="$config"
	sed -n "s|^$1=||p" "$FILE" 2>/dev/null
}


set_prop() { sed -i "s|^$1=.*|$1=$2|g" "$config"; }


set_perms() {
	if is f "$1"; then
		chown media_rw:media_rw "$1"
		chmod 777 "$1"
	elif is d "$1"; then
		chown -R media_rw:media_rw "$1"
		chmod -R 777 "$1"
	fi
}


ECHO() { $interactiveMode && echo; }

is_mounted() { mountpoint -q "$1" 2>/dev/null; }

wait_until_true() {
	Count=0
	until [ "$Count" -ge "90" ]; do
		((Count++))
		if n "$1"; then
			$($@) && break || sleep 1
		else
			is_mounted /storage/emulated && break || sleep 1
		fi
	done
  if n "$1"; then
		$($@) || return 1
	else
		is_mounted /storage/emulated || return 1
	fi
}


# A "better" mount -o bind
bind_mnt() {
	if ! is_mounted "$2"; then
		ECHO
    [ "$3" ] && echo "$3" || echo "bind_mount [$1] [$2]"
 
		echo "$1 $2" | grep -Eq '/data/media/[1-9]|/storage/emulated/[1-9]' && (wait_until_true) &
    echo "$1 $2" | grep -Eq '/mnt/media_rw/' && (wait_until_true grep -q '/mnt/media_rw/' /proc/mounts) &
    wait
 
    [ -d "$1" ] || mkdir -p -m 777 "$1"
    [ -d "$2" ] || mkdir -p -m 777 "$2"   
    mount -o bind "$1" "$2"
	fi
}


# Set Alternate intsd Path
intsd_path() {
	intsd="$1"
}


# Log Engine
log_start() {
  is f $logFile && mv $logFile $previousLogFile
	exec &> $logFile
	echo -e "$(date)\n"
}
log_end() {
	sed -i "s:intsd:$intsd:g; s:extsd:$extsd:g; s:obb:$obb:g; s:extobb:$extobb:g" $logFile
	set_perms $logFile
	if [ -n "$SEck" ] && $SELinuxAutoMode; then
		$was_enforcing && setenforce 1
	fi
	rm $fbindDir/.tmp 2>/dev/null
	exit 0
}


# Mount partition
# $1=block_device, $2=mount_point, $3=filesystem, $4="fsck OPTION(s)" (filesystem specific, optional)
part() {
	if z "$3"; then
		echo "(!) [part $1 $2 $3 $4]: missing/invalid argument(s)" && return 1
	else
	  PARTITION="$(echo $1 | sed 's/.*\///; s/--L//')"
	  PPath="$(echo $1 | sed 's/--L//')"
	
	  if ! is_mounted "$2"; then
      echo "$1 $2" | grep -Eq '/data/media/[1-9]|/storage/emulated/[1-9]' && (wait_until_true) &
      echo "$1 $2" | grep -Eq '/mnt/media_rw/' && (wait_until_true grep -q '/mnt/media_rw/' /proc/mounts) &
      wait
      
      [ -d "$2" ] || mkdir -p -m 777 "$2"
      wait_until_true [ -b "$PPath" ]
 
      # open LUKS volume (manually)
      if echo "$1" | grep -q '\-\-L' && $interactiveMode; then
        cryptsetup luksOpen $PPath $PARTITION
        n "$4" && $($4 /dev/mapper/$PARTITION)
        mount -t $3 -o noatime,rw /dev/mapper/$PARTITION "$2"
        
      # mount regular partition
      else
        n "$4" && $($4 $PPath)
        mount -t $3 -o noatime,rw $PPath "$2"
      fi

      if ! is_mounted "$2"; then
        echo "(!) Failed to mount $PARTITION" && rmdir "$2" 2>/dev/null
        return 1
      fi
	  fi
  fi
}


# Fallback sdcard path
default_extsd() {
	wait_until_true grep -q '/mnt/media_rw' /proc/mounts
  extsd="$(ls -1d /mnt/media_rw/* | head -n1)"
  extobb="$extsd/Android/obb"
}


# Set Alternate extsd Path
# extsd_path [/path/to/partition or /alternate/path] [/default/extsd/path (if arg1 is /path/to/partition)] [filesystem (if arg1 is /path/to/partition)] ["fsck [options]" (if arg1 is /path/to/partition)] -- arguments 2-4 are optional if no partition is specified.
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
    
    if [[ $? ]]; then
      for m in $(grep -E '/storage/|/mnt/' /proc/mounts | awk '{print $2}'); do
        if [[ $? ]] && is_mounted $m; then umount -f $m; fi
      done
      
      for m in $(grep -E '/storage/|/mnt/' /proc/mounts | awk '{print $2}'); do
        if [[ $? ]] && is_mounted $m; then umount -f $m; fi
      done
      
      if [[ $? ]]; then
        # Internal
        bind_mnt /data/media /mnt/runtime/default/emulated
        bind_mnt /data/media /storage/emulated
        bind_mnt /data/media /mnt/runtime/read/emulated
        bind_mnt /data/media /mnt/runtime/write/emulated

        # External
        n "$4" && $4 "$1"
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


# Mount loop device
# $1=/path/to/.img_file, $2=mount_point
LOOP() {
	echo "$1 $2" | grep -Eq '/data/media/[1-9]|/storage/emulated/[1-9]' && (wait_until_true) &
  echo "$1 $2" | grep -Eq '/mnt/media_rw/' && (wait_until_true grep -q '/mnt/media_rw/' /proc/mounts) &
  wait
  is_mounted "$2" || { echo && e2fsck -fy "$1"; }
  is d "$2" || mkdir -p -m 777 "$2"

	if ! is_mounted "$2"; then
		for Loop in 0 1 2 3 4 5 6 7; do
      loopDevice=/dev/block/loop$Loop
      [ -b "$loopDevice" ] || mknod $loopDevice b 7 $Loop 2>/dev/null
      losetup $loopDevice "$1" && mount -t ext4 -o loop $loopDevice "$2"
      is_mounted "$2" && break
		done
    fi

  if ! is_mounted "$2"; then
    echo -n "\n(!) Failed to mount $1" && return 1
  fi
}


apply_cfg() {
  echo "STORAGE INFORMATION"
	grep -v '^#' $cfgFile | grep -E '^extsd_path |^intsd_path |^part |^LOOP ' >$fbindDir/.tmp
	. $fbindDir/.tmp
	$altExtsd || default_extsd
  
  grep -v '^#' $cfgFile | grep -E '^part |^LOOP ' | while read line
  do
    target="$(echo "$line" | awk '{print $3}' | sed 's/"//g' | sed "s/'//g")"
    if is_mounted "$target"; then
      echo
      df -h "$target"
    fi
  done
  
  target() { grep -v '^#' $cfgFile | grep -E '^part |^LOOP ' | awk '{print $3}' | sed 's/"//g' | sed "s/'//g"; }
  target | grep -q "$intsd" || echo && df -h "$intsd"
  if ! target | grep -q "$extsd" && is_mounted "$extsd"; then
    echo
    df -h "$extsd"
  fi
  grep "$extsd" /proc/mounts | grep -Eiq 'ext[0-9]{1}|f2fs' && linuxFS=true
 
  # Auto-backup config.txt
	ConfigBkp=$extsd/.fbind_bkp/config.txt
	if [ "$ConfigBkp" -ot "$cfgFile" ] \
    && grep -q '[a-z]' $cfgFile \
    && ! grep -v '^#' $cfgFile | grep -q no_bkp \
    && is_mounted "$extsd"
  then
      mkdir -p $extsd/.fbind_bkp 2>/dev/null
      mv $ConfigBkp $extsd/.fbind_bkp/last_config.txt
      rsync -a $cfgFile $ConfigBkp 2>/dev/null
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
	
	# data/data/pkgName <--> $appDataRoot/pkgName
	app_data() {
	  if n "$2" && ! echo "$2" | grep '\-u'; then
	    linuxFS=true
	    appDataRoot="$2"
	  else
	    appDataRoot="$extsd/.app_data"
	  fi
		if ! $linuxFS; then
			ECHO
			echo -e "(!) app_data() won't work without a Linux filesystem.\n"
		else
	  	ls /data/app 2>/dev/null | grep -q "$1" && bind_mnt "$appDataRoot/$1" /data/data/$1 "[/data/data/$1] <--> [\$appDataRoot/$1]"
	  fi
	}

	# intsd <--> extsd/.fbind
	int_extf() {
		bind_mnt $extsd/.fbind $intsd "[int_extf]"
		{ target Android
		target data
		obb; } &>/dev/null
	}
	if n "$1"; then
		grep -v '^#' $cfgFile | grep -E '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target ' | grep -E "$1" >$fbindDir/.tmp
	else
		grep -v '^#' $cfgFile | grep -E '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target ' >$fbindDir/.tmp
	fi
	. $fbindDir/.tmp
	ECHO
	echo -e "- Ok\n"
}


cleanupf() {
	echo "CLEANUP"
	cleanup() {
		ECHO
		if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ] || [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then echo "$1"; fi
		if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ]; then rm -rf "$intsd/$1"; fi
		if [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then rm -rf "$extsd/$1"; fi
	}
	grep -v '^#' $cfgFile | grep '^cleanup ' >$fbindDir/.tmp
	. $fbindDir/.tmp
	
	# Unwanted "Android" directories
	
	obb() { if is_mounted $obb && [ -z "$1" ]; then rm -rf $extobb/Android; fi; }
	
	obbf() { if is_mounted $obb/$1 && [ -z "$2" ]; then rm -rf $extobb/$1/Android; fi; }
	
	target() { if is_mounted "$intsd/$1" && [ -z "$2" ]; then rm -rf "$extsd/$1/Android"; fi; }
	
	from_to() { if is_mounted "$intsd/$1" && [ -z "$3" ]; then rm -rf "$extsd/$2/Android"; fi; }
		
	bind_mnt() { if is_mounted "$2" && [ -z "$3" ]; then rm -rf "$1/Android"; fi; }
			
	app_data() { is_mounted /data/data/$1 && rm -rf "$appDataRoot/$1/Android"; }

	grep -v '^#' $cfgFile | grep -E '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target ' >$fbindDir/.tmp
	. $fbindDir/.tmp
	
	# Source optional cleanup script
	if [ -f $fbindDir/cleanup.sh ]; then
		echo "$fbindDir/cleanup.sh"
		. $fbindDir/cleanup.sh
		ECHO
	fi
	
	echo "- Ok"
	ECHO
} 2>/dev/null


# Restore config backup
if ! grep -qs '[a-z]' "$cfgFile" && ! is f $fbindDir/.no_restore; then
	echo "(i) Searching for config backup"
	BkpDir="$(find /mnt/media_rw -type d -name ".fbind_bkp" 2>/dev/null | head -n1)"
	if [ -f "$BkpDir/config.txt" ]; then
		echo "- Restoring config.txt"
		rsync -a "$BkpDir/config.txt" "$cfgFile" 2>/dev/null
	else
		echo "- Creating dummy config.txt"
		touch "$cfgFile"
		$interactiveMode || { echo "(!) No config found" && exit 1; }
	fi
	echo
fi

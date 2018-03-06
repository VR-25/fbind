# fbind Core
# VR25 @ xda-developers


# ENVIRONMENT
intsd=/data/media/0
intobb=/data/media/obb
fbind_dir=/data/media/fbind
config_file=$fbind_dir/config.txt
config_path=$fbind_dir/.config
bind_list=$config_path/bind
debug_config=$config_path/debug
debug=$config_file
logfile=$fbind_dir/debug.log
cleanup_list=$config_file
cleanup_config=$config_path/cleanup
alt_extsd=false
[ -z "$tk" ] && tk=false
LinuxFS=false
OwnInfo=false


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


ECHO() { $tk && echo; }

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
}

# A "better" mount -o bind
bind_mnt() {
	if ! is_mounted "$2"; then
		ECHO
		[ -d "$1" ] || mkdir -p -m 777 "$1"
		[ -d "$2" ] || mkdir -p -m 777 "$2"
		echo "$1 $2" | grep -Eq "$extsd|$intsd" && wait_until_true
		[ "$3" ] && echo "$3" || echo "bind_mount [$1] [$2]"
		mount -o bind "$1" "$2"
	fi
}


# Set Alternate intsd Path
intsd_path() {
	intsd="$1"
}


# Log Engine
log_start() {
	exec &> $logfile
	echo -e "$(date)\n"
}
log_end() {
	sed -i "s:intsd:$intsd:g; s:extsd:$extsd:g; s:intobb:$intobb:g; s:extobb:$extobb:g" $logfile
	set_perms $logfile
	if [ -n "$SEck" ] && $SELinuxAutoMode; then
		$was_enforcing && setenforce 1
	fi
	rm $fbind_dir/.tmp 2>/dev/null
	exit 0
}


# Mount partition
# $1=block_device, $2=mount_point, $3=filesystem, $4="fsck OPTION(s)" (filesystem specific, optional)
part() {
	if z "$3"; then
		echo "(!) part(): missing argument(s)"
		exit 1
	fi
	
	echo -e "<Storage Information>\n"
	OwnInfo=true
	PARTITION="$(echo $1 | sed 's/.*\///; s/--.*//')"
	PPath="$(echo $1 | sed 's/--.*//')"
	MountPoint="$2"
	
	if is_mounted "$MountPoint"; then
		echo "(i) $PARTITION already mounted"
	else
		is d "$MountPoint" || mkdir -p -m 777 "$MountPoint"
		wait_until_true [ -b "$PPath" ]
		
		# Open LUKS volume
		if grep -v '#' $config_file | grep -q '\-\-L'; then
			cryptsetup luksOpen $PPath $PARTITION
			[ "$?" ] && echo '***'
			[ -n "$4" ] && $($4 /dev/mapper/$PARTITION)
			mount -t $3 -o noatime,rw /dev/mapper/$PARTITION "$MountPoint"
		else
			[ -n "$4" ] && $($4 $PPath)
			mount -t $3 -o noatime,rw $PPath "$MountPoint"
		fi
		
		echo "***"
		if is_mounted "$MountPoint"; then
			df -h "$MountPoint"
			echo $3
		else
			echo "(!) $PARTITION mount failed"
			rmdir "$MountPoint" 2>/dev/null
			exit 1
		fi
	fi
	echo
}


default_extsd() {
	echo -e "<Storage Information>\n"
	wait_until_true grep -q "/mnt/media_rw" /proc/mounts
	grep "$(ls /mnt/media_rw)" /proc/mounts
	grep "$(ls /mnt/media_rw)" /proc/mounts | grep -Eiq 'ext[0-9]{1}|f2fs' && LinuxFS=true
	extsd="$(ls -1d /mnt/media_rw/* | head -n1)"
	extobb="$extsd/Android/obb"
	echo
	df -h "$extsd"
	echo
}


# Set Alternate extsd Path
extsd_path() {
	$OwnInfo || echo -e "<Storage Information>\n"
	alt_extsd=true
	if [ "$1" = "$intsd" ]; then
		LinuxFS=true
		extsd="$intsd"
		extobb="$intobb"
	else
		if n "$3"; then
			###
			# EXPERIMENTAL -- mount user storage the old school way
			# Unmount all FUSE mount points
			(wait_until_true) &
			(wait_until_true is_mounted "$2") &
			wait
			for m in $(grep -E '/storage/|/mnt/' /proc/mounts | awk '{print $2}'); do
				umount -f $m
			done
			
			# Internal
			bind_mnt /data/media /mnt/runtime/default/emulated
			bind_mnt /data/media /storage/emulated
			bind_mnt /data/media /mnt/runtime/read/emulated
			bind_mnt /data/media /mnt/runtime/write/emulated

			# External
			mount -t $3 -o noatime,rw /dev/block/$1 /mnt/media_rw/$2
			bind_mnt /mnt/media_rw/$2/.android_secure /mnt/secure/asec
			bind_mnt /mnt/media_rw/$2 /mnt/runtime/default/$2
			bind_mnt /mnt/media_rw/$2 /storage/$2
			bind_mnt /mnt/media_rw/$2 /mnt/runtime/read/$2
			bind_mnt /mnt/media_rw/$2 /mnt/runtime/write/$2
			###
		else
			wait_until_true grep -q "$1" /proc/mounts
		fi
		echo "$1" | grep -iq mmcblk && extsd="/mnt/media_rw/$2" || extsd="$1"
		grep "$extsd" /proc/mounts | grep -Eiq 'ext[0-9]{1}|f2fs' && LinuxFS=true
		extobb="$extsd/Android/obb"
		echo
		[ "$MountPoint" != "$extsd" ] && df -h "$extsd"
		echo
	fi
}


# Mount loop device
# $1=/path/to/.img_file, $2=mount_point, $3="e2fsck -OPTION(s)" (optional)
LOOP() {
	OwnInfo=true
	echo -e "<Storage Information>\n"
	IMG="$1"
	MountPoint="$2"
	echo "$IMG $MountPoint" | grep -Eq "$extsd|$intsd" && wait_until_true
	n "$3" && $($3 "$1")
	is d "$MountPoint" || mkdir -p -m 777 "$MountPoint"
	mount "$IMG" "$MountPoint"
	df -h "$MountPoint"
	echo
}


apply_cfg() {
	df_int="$(df -h /data/media/0)"
	grep -v '#' $config_file | grep -E 'part |LOOP |extsd_path |intsd_path ' >$fbind_dir/.tmp
	. $fbind_dir/.tmp
	$alt_extsd || default_extsd
	if [ "$MountPoint" != "/data/media/0" ] && [ "$extsd" != "$intsd" ]; then
		echo -e "${df_int}\n"
	fi
	
	ConfigBkp=$extsd/.fbind_bkp/config.txt
	if [ "$ConfigBkp" -ot "$config_file" ] \
	&& grep -q '[a-z]' $config_file \
	&& ! grep -v '#' $config_file | grep -q no_bkp; then
		mkdir -p $extsd/.fbind_bkp 2>/dev/null
		mv $ConfigBkp $extsd/.fbind_bkp/last_config.txt
		cp -a $config_file $ConfigBkp 2>/dev/null
	fi
}


bind_folders() {
	$tk && echo "Bind-mounting..." || echo "<Bind-mount>"
	
	# entire obb folder
	obb() { bind_mnt $extobb $intobb "[intobb] <--> [extobb]"; }
	
	# game/app obb folder
	obbf() { bind_mnt $extobb/$1 $intobb/$1 "[obbf $1]"; }
	
	# target folder
	target() { bind_mnt "$extsd/$1" "$intsd/$1" "[intsd/$1] <--> [extsd/$1]"; }
	
	# source <--> destination
	from_to() { bind_mnt "$extsd/$2" "$intsd/$1" "[intsd/$1] <--> [extsd/$2]"; }
	
	# data/data/app <--> extsd/.app_data/app
	app_data() {
		if ! $LinuxFS; then
			ECHO
			echo -e "(!) app_data() won't work without a Linux filesystem.\n"
			exit 1
		fi
		bind_mnt $extsd/.app_data/$1 /data/data/$1 "[/data/data/$1] <--> [extsd/.app_data/$1]"
	}
			
	# intsd <--> extsd/.fbind
	int_extf() {
		bind_mnt $extsd/.fbind $intsd "[int_extf]"
		{ target Android
		target data
		obb; } &>/dev/null
	}
	if n "$1"; then
		grep -v '#' $config_file | grep -E "$1" >$fbind_dir/.tmp
	else
		grep -v '#' $config_file | grep -E 'app_data |int_extf|bind_mnt |^obb.*|from_to |target ' >$fbind_dir/.tmp
	fi
	. $fbind_dir/.tmp
	ECHO
	echo -e "- Done.\n"
}


cleanupf() {
	echo '<Cleanup>'
	cleanup() {
		ECHO
		if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ] || [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then echo "$1"; fi
		if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ]; then rm -rf "$intsd/$1"; fi
		if [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then rm -rf "$extsd/$1"; fi
	}
	grep -v '#' $config_file | grep 'cleanup ' >$fbind_dir/.tmp
	. $fbind_dir/.tmp
	
	# Unwanted "Android" directories
	
	obb() { if is_mounted $intobb && [ -z "$1" ]; then rm -rf $extobb/Android; fi; }
	
	obbf() { if is_mounted $intobb/$1 && [ -z "$2" ]; then rm -rf $extobb/$1/Android; fi; }
	
	target() { if is_mounted "$intsd/$1" && [ -z "$2" ]; then rm -rf "$extsd/$1/Android"; fi; }
	
	from_to() { if is_mounted "$intsd/$1" && [ -z "$3" ]; then rm -rf "$extsd/$2/Android"; fi; }
		
	bind_mnt() { if is_mounted "$2" && [ -z "$3" ]; then rm -rf "$1/Android"; fi; }
			
	app_data() { if is_mounted /data/data/$1 && [ -z "$2" ]; then rm -rf $extsd/.app_data/$1/Android; fi; }

	grep -v '#' $config_file | grep -E 'app_data |int_extf|bind_mnt |^obb.*|from_to |target ' >$fbind_dir/.tmp
	. $fbind_dir/.tmp
	
	# Source optional cleanup script
	if [ -f $fbind_dir/cleanup.sh ]; then
		echo "$fbind_dir/cleanup.sh"
		. $fbind_dir/cleanup.sh
		ECHO
	fi
	
	echo "- Done."
	ECHO
} 2>/dev/null


# Restore config backup
if ! grep -qs '[a-z]' "$config_file" && ! is f $fbind_dir/.no_restore; then
	echo "(i) Searching for config backup"
	BkpDir="$(find /mnt/media_rw -type d -name ".fbind_bkp" 2>/dev/null | head -n1)"
	if [ -f "$BkpDir/config.txt" ]; then
		echo "- Restoring config.txt"
		cp -a "$BkpDir/config.txt" "$config_file" 2>/dev/null
	else
		echo "- Creating dummy config.txt"
		touch "$config_file"
		$tk || exit 1
	fi
	echo
fi

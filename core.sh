# fbind Core
# VR25 @ XDA Developers


# ENVIRONMENT
[ -z "$intsd" ] && intsd=/data/media/0
intobb="$(echo $intsd | sed "s/$(basename $intsd)/obb/")"
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
	until [ "$Count" -ge "120" ]; do
		Count=$(($Count+1))
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
	intobb="$(echo $intsd | sed "s/$(basename $intsd)/obb/")"
	#echo $intsd | grep -q '/emulated' && setenforce 0 && was_enforcing=false
}


# Log Engine
log_start() {
	exec &> $logfile
	echo -e "$(date)\n"
}
log_end() {
	sed -i "s:intsd:$intsd:g; s:extsd:$extsd:g" $logfile
	set_perms $logfile
	if [ -n "$SEck" ]; then
		$was_enforcing && setenforce 1
	fi
	rm $fbind_dir/.tmp 2>/dev/null
	exit 0
}


# Mount partition
# $1=block_device, $2=mount_point, $3=file_system, $4="fsck OPTION(s)" (file system specific, optional)
part() {
	if z "$3"; then
		echo "(!) part(): missing argument(s)"
		exit 1
	fi
	
	echo "<Partition Information>"
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
		else [ -n "$4" ] && $($4 $PPath)
			mount -t $3 -o noatime,rw $PPath "$MountPoint"
		fi
		
		if is_mounted "$MountPoint"; then
			echo "***"
			df -h "$MountPoint" | sed "s/Filesystem/   Partition ($3)/"
		else
			echo '***'
			echo "(!) $PARTITION mount failed"
			rmdir "$MountPoint" 2>/dev/null
			exit 1
		fi
	fi
	echo
}


default_extsd() {
	echo "<SD Card Information>"
	wait_until_true grep -q "/mnt/media_rw" /proc/mounts
	grep "$(ls /mnt/media_rw)" /proc/mounts
	grep "$(ls /mnt/media_rw)" /proc/mounts | grep -Eq 'ext2|ext3|ext4|f2fs' && LinuxFS=true
	extsd="$(ls -1d /mnt/media_rw/* | head -n1)"
	extobb="$extsd/Android/obb"
	echo
}


# Set Alternate extsd Path
extsd_path() {
	if [ "$1" = "$intsd" ]; then
		LinuxFS=true
		alt_extsd=true
		extsd="$intsd"
		extobb="$intobb"
	else
		echo "<SD Card Information>"
		wait_until_true grep -q "$1" /proc/mounts
		grep "$1" /proc/mounts | grep -Eq 'ext2|ext3|ext4|f2fs' && LinuxFS=true
		alt_extsd=true
		extsd="$1"
		extobb="$extsd/Android/obb"
		echo
	fi
}


# Mount loop device
# For safety reasons, the mount point can't be "/FOLDER"
# $1=/path/to/.img_file, $2=mount_point, $3="e2fsck -OPTION(s)" (optional)
LOOP() {
	IMG="$1"
	MountPoint="$2"
	echo "$IMG $MountPoint" | grep -Eq "$extsd|$intsd" && wait_until_true
	n "$3" && $($3 "$1")
	is d "$MountPoint" || mkdir -p -m 777 "$MountPoint"
	mount "$IMG" "$MountPoint"
}


apply_cfg() {
	: >$fbind_dir/.tmp
	grep -v '#' $config_file | grep -E 'part |LOOP |extsd_path |intsd_path ' >$fbind_dir/.tmp
	. $fbind_dir/.tmp
	$alt_extsd || default_extsd
	
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
	$tk && echo "Binding folders..." || echo "<Bind Folders>"
	
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
			echo -e "(!) app_data() won't work without a Linux FS.\n"
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
	: >$fbind_dir/.tmp
	grep -v '#' $config_file | grep -E 'app_data |int_extf|bind_mnt |obb.*|from_to |target ' >$fbind_dir/.tmp
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
	
	: >$fbind_dir/.tmp
	grep -v '#' $config_file | grep -E 'app_data |int_extf|bind_mnt |obb.*|from_to |target ' >$fbind_dir/.tmp
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

# fbind Core
# VR25 @ XDA Developers


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
part=false
bind_only=false
alt_extsd=false
tk=false
LinuxFS=false
mk_cfg=false



is() { [ -$1 "$2" ]; }

n() { [ -n "$1" ]; }

z() { [ -z "$1" ]; }


# Debugging switches (shell strict mode)
#IFS=$'\n\t'
#set -exuo pipefail
#set -eo pipefail


get_prop() {
	FILE="$2"
	z "$FILE" && FILE="$config"
	sed -n "s|^$1=||p" "$FILE" 2>/dev/null
}


set_prop() { sed -i "s|^$1=.*|$1=$2|g" "$config"; }


sown() {
	if is f "$1"; then
		chown media_rw:media_rw "$1"
	elif is d "$1"; then
		chown -R media_rw:media_rw "$1"
	fi
}



# Generate config file from current settings
if [ ! -f "$config_file" ]; then
	mk_cfg=true
	mkdir -p $fbind_dir 2>/dev/null && sown $fbind_dir
	if [ "$(ls "$fbind_dir")" ]; then
		cat $config_path/* >$config_file && sown $config_file
	else
		echo -e "(!) No settings found\n"
		exit 1
	fi
fi



ECHO() { $tk && echo; }

is_mnt() { mountpoint -q "$1" 2>/dev/null; }

wait_emulated() { until is_mnt /storage/emulated; do sleep 1; done; }

# A "better" mount -o bind
bind_mnt() {
	if ! is_mnt "$2"; then
		ECHO
		[ -d "$1" ] || mkdir -p -m 777 "$1"
		[ -d "$2" ] || mkdir -p -m 777 "$2"
		echo "$1 $2" | grep -Eq "$extsd|$intsd" && wait_emulated
		[ "$3" ] && echo "$3" || echo "bind_mount [$1] [$2]"
		mount -o bind "$1" "$2"
	fi
}



# Set Alternate intsd & intobb Paths
intsd_path() { intsd="$1"; }
intobb_path() { intobb="$1"; }

# Log Engine
log_start() {
	exec &> $logfile
	echo -e "$(date)\n"
}

log_end() {
	sown $logfile
	$was_enforcing && setenforce 1
	exit 0
}


# Auto-mount a partition & use it as extsd
# For safety reasons, the mount point can't be "/FOLDER"
# $1=block_device, $2=mount_point, $3=file_system, $4="fsck OPTION(s)" (filesystem specific, optional)
part() {
	if z "$3"; then
		echo "(!) part(): missing argument(s)"
		exit 1
	fi
	
	echo "<Partition Information>" 
	PARTITION=$(echo $1 | sed 's/.*\///')
	part=true
	extsd="$2"
	extobb="$extsd/Android/obb"
	
	if is_mnt "$2"; then
		echo "(i) $PARTITION already mounted"
	else
		is d "$2" || mkdir -p -m 777 "$2"
		until [ -b "$1" ]; do sleep 1; done
		
		# Open LUKS volume
		if grep -v '#' $config_file | grep -q 'luks'; then
			cryptsetup luksOpen $1 $PARTITION
			[ "$?" ] && echo '***'
			[ -n "$4" ] && $4 /dev/mapper/$PARTITION
			mount -t $3 -o noatime,rw /dev/mapper/$PARTITION "$2"
		else [ -n "$4" ] && $4 $1
			mount -t $3 -o noatime,rw $1 "$2"
		fi
		
		if ! is_mnt "$2"; then
			echo '***'
			echo "(!) $PARTITION mount failed"
			rmdir "$2" 2>/dev/null
			exit 1
		fi
		
		[ "$?" ] && echo '***' \
			&& df -h "$2" | sed "s/Filesystem/   Partition ($3)/"
	fi
	echo
}

default_extsd() {
	echo "<SD Card Information>"
	
	until grep -q "/mnt/media_rw" /proc/mounts; do sleep 1; done

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
		extsd="$1"
		extobb="$intobb"
	else
		echo "<SD Card Information>"

		until grep -q "$1" /proc/mounts; do slee 1; done

		grep "$1" /proc/mounts | grep -Eq 'ext2|ext3|ext4|f2fs' && LinuxFS=true
		alt_extsd=true
		extsd="$1"
		extobb="$extsd/Android/obb"
		echo
	fi
}



update_cfg() {
	echo "<Config Update>"
	if [ "$config_file" -ot "$config_path" ]; then
		echo "- No updates found."
	else
		if $mk_cfg; then
			echo "- No updates found."
		else
			mkdir $config_path 2>/dev/null
			grep -v '#' $config_file | grep -E 'Permissive_SELinux|part |extsd_path |intsd_path |intobb_path ' >$debug_config
			grep -vE '#|intobb_path ' $config_file | grep -E 'app_data |int_extf|bind_mnt |obb|obbf |from_to |target ' >$bind_list
			grep -v '#' $config_file | grep 'cleanup' > $cleanup_config
			
			# Misc config lines
			grep -Ev '#|part ' $config_file | grep -E 'u[0-9]{1}=|u[0-9]{2}=|perms|luks|fsck|no_bkp' >$config_path/misc
			
			# Enable additional intsd paths for multi-user support
			grep '#' $config_file | grep -E 'u[0-9]{1}=|u[0-9]{2}=' >$config_path/uvars
		
			sown $config_path
			echo "- Done."
		fi
	fi
	echo
}

apply_cfg() {
	. $config_path/uvars
	. $debug_config
	if ! $part && ! $alt_extsd; then default_extsd; fi
}


cfg_bkp() {
	ConfigBkp=$extsd/.fbind_bkp/config.txt
	if [ "$ConfigBkp" -ot "$config_file" ] \
	&& ! $mk_cfg && grep -q '[a-z]' $config_file \
	&& ! grep -v '#' $config_file | grep -q no_bkp; then
		mkdir $extsd/.fbind_bkp 2>/dev/null
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
		if ! $part && ! $LinuxFS; then ECHO
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

	. $bind_list
	ECHO
	echo "- Done."
	echo
}


cleanupf() {
	echo '<Cleanup>'
	cleanup() {
		ECHO
		if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ] || [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then echo "$1"; fi
		if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ]; then rm -rf "$intsd/$1"; fi
		if [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then rm -rf "$extsd/$1"; fi
	}
	. $cleanup_config
	
	# Unwanted "Android" directories
	
	obb() { if is_mnt $intobb && [ -z "$1" ]; then rm -rf $extobb/Android; fi; }
	
	obbf() { if is_mnt $intobb/$1 && [ -z "$2" ]; then rm -rf $extobb/$1/Android; fi; }
	
	target() { if is_mnt "$intsd/$1" && [ -z "$2" ]; then rm -rf "$extsd/$1/Android"; fi; }
	
	from_to() { if is_mnt "$intsd/$1" && [ -z "$3" ]; then rm -rf "$extsd/$2/Android"; fi; }
		
	bind_mnt() { if is_mnt "$2" && [ -z "$3" ]; then rm -rf "$1/Android"; fi; }
			
	app_data() { if is_mnt /data/data/$1 && [ -z "$2" ]; then rm -rf $extsd/.app_data/$1/Android; fi; }

	. $bind_list
	
	# . optional cleanup script
	if [ -f $fbind_dir/cleanup.sh ]; then
		echo ". $fbind_dir/cleanup.sh"
		. $fbind_dir/cleanup.sh
		ECHO
	fi
	
	echo "- Done."
	ECHO
} 2>/dev/null

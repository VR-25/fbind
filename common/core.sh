# fbind Core
# VR25 @ XDA Developers


###CONSTANTS & VARIABLES###
intsd=/data/media/0
intobb=/data/media/obb
module_path=/magisk/fbind
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


###TOOLBOX###

# Auto-recreate config file (fbind won't work without it)
if [ ! -f "$config_file" ]; then
	mk_cfg=true
	[ -d "$fbind_dir" ] || mkdir -p -m 777 $fbind_dir
	cd $config_path
	cat bind cleanup debug misc uvars > $config_file
	chmod 777 $config_file
fi

toolkit() { tk=true; }

ECHO() { $tk && echo; }

mntpt() { mountpoint -q "$1" 2>/dev/null; }

wait_emulated() { until mntpt /storage/emulated; do sleep 1; done; }

# A "better" mount -o bind
bind_mnt() {
	if ! mntpt "$2"; then
		ECHO
		[ -d "$1" ] || mkdir -p -m 777 "$1"
		[ -d "$2" ] || mkdir -p -m 777 "$2"
		echo "$1 $2" | grep -Eq "$extsd|$intsd" && wait_emulated
		[ "$3" ] && echo "$3" || echo "bind_mount [$1] [$2]"
		mount -o bind "$1" "$2"
	fi
}


###DEBUGGING FUNCTIONS###

# Set SELinux Mode to Permissive
Permissive_SELinux() {
	if [ -z "$1" ]; then
		setenforce 0
	elif [ "$1" = "-bind_only" ]; then
		bind_only=true
	fi; }
SetEnforce_1() { $bind_only && setenforce 1; }
SetEnforce_0() { $bind_only && setenforce 0; }

# Set Alternate intsd & intobb Paths
intsd_path() { intsd="$1"; }
intobb_path() { intobb="$1"; }

# Log Engine
log_start() {
	exec &> $logfile
	echo "$(date)"
	echo; }
log_end() {
	chmod 777 $logfile
	exit 0; }

# Auto-mount a partition & use it as extsd
# For safety reasons, the mount point can't be "/FOLDER"
# $1=block_device, $2=mount_point, $3=file_system, $4="fsck OPTION(s)" (filesystem specific, optional)
part() {
	if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
		echo "(!) part(): missing argument(s)"
		exit 1
	fi
	
	echo "<Partition Information>" 
	PARTITION=$(echo $1 | sed 's/.*\///')
	part=true
	extsd=$2
	extobb=$extsd/Android/obb
	
	if mntpt $2; then
		echo "(i) $PARTITION already mounted"
	else until [ -b $1 ]; do sleep 1; done

		# Open LUKS volume
		if grep -v '#' $config_file | grep -q 'cryptsetup=true'; then
			cryptsetup luksOpen $1 $PARTITION
			[ $? ] && echo '***'
			[ "$4" ] && $4 /dev/mapper/$PARTITION
			mount -t $3 -o noatime,rw /dev/mapper/$PARTITION $2
		else [ "$4" ] && $4 $1
			mount -t $3 -o noatime,rw $1 $2
		fi
		
		if ! mntpt $2; then
			echo '***'
			echo "(!) part(): $PARTITION mount failed"
			rmdir $extsd 2>/dev/null
			exit 1
		fi
		
		[ $? ] && echo '***' \
			&& df -h $2 | sed "s/Filesystem/   Partition ($3)/"
	fi
	echo
}

# Set Default extsd Path
default_extsd() {
	echo "<SD Card Information>"
	until grep -q "/mnt/media_rw" /proc/mounts; do sleep 1; done
	grep "$(ls /mnt/media_rw)" /proc/mounts
	grep "$(ls /mnt/media_rw)" /proc/mounts | grep -Eq 'ext2|ext3|ext4|f2fs' && LinuxFS=true
	extsd="/mnt/media_rw/$(ls /mnt/media_rw)"
	extobb=$extsd/Android/obb
	echo
}

# Set Alternate extsd Path
# $1=/path/to/alternate/storage
extsd_path() {
	if [ "$1" = "$intsd" ]; then
		LinuxFS=true
		alt_extsd=true
		extsd="$1"
		extobb="$intobb"
	else
		echo "<SD Card Information>"
		until grep "$1" /proc/mounts; do sleep 1; done
		grep "$1" /proc/mounts | grep -Eq 'ext2|ext3|ext4|f2fs' && LinuxFS=true
		alt_extsd=true
		extsd="$1"
		extobb="$extsd/Android/obb"
		echo
	fi
}


###UPDATE & APPLY CONFIG###
update_cfg() {
	echo "<Config Update>"
	if [ "$config_file" -ot "$config_path" ]; then
		echo "- No updates found."
	else
		if $mk_cfg; then echo "- No updates found."
		else
			[ -d $config_path ] || mkdir $config_path
			grep -v '#' $config_file | grep -E 'Permissive_SELinux|part |extsd_path |intsd_path |intobb_path ' > $debug_config
			grep -vE '#|intobb_path ' $config_file | grep -E 'app_data |int_extf|bind_mnt |obb|obbf |from_to |target ' > $bind_list
			grep -v '#' $config_file | grep 'cleanup' > $cleanup_config
			
			# Misc config lines
			grep -Ev '#|part ' $config_file | grep -E 'u[0-9]{1}=|u[0-9]{2}=|perms|cryptsetup=|fsck' > $config_path/misc
			
			# Enable additional intsd paths for multi-user support
			grep '#' $config_file | grep -E 'u[0-9]{1}=|u[0-9]{2}=' > $config_path/uvars
			
			#sed -Ei "/bind_mnt/s/ u/ $(echo "$intsd" | sed 's/\/0//')" $bind_list
			
			chmod -R 777 $config_path
			echo "- Done."
		fi
	fi
	echo
}
apply_cfg() {
	source $config_path/uvars
	source $debug_config
	if ! $part && ! $alt_extsd; then default_extsd; fi
}


###BACKUP & RESTORE CONFIG###
cfg_bkp() {
	bkp_file=$extsd/.fbind_bkp/config.txt
	if ! grep -q '[a-z]' $config_file; then
		[ -f $bkp_file ] && cp $bkp_file $config_file
		chmod 777 $config_file
	fi
	
	if [ "$bkp_file" -ot "$config_file" ] && ! $mk_cfg && grep -q '[a-z]' $config_file; then
		[ -d "$extsd/.fbind_bkp" ] || mkdir -m 777 $extsd/.fbind_bkp
		cp $config_file $bkp_file
		chmod 777 $bkp_file
	fi
}


###BINDING FUNCTION###
bind_folders() {
	$tk && echo "Binding folders..." || echo "<Bind Folders>"
	SetEnforce_0
	
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
			echo "(!) fbind: app_data() won't work without part() or extsd_path() (LinuxFS)!"
			echo
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

	source $bind_list
	SetEnforce_1
	ECHO
	echo "- Done."
	echo
}


###CLEANUP FUNCTION###
cleanupf() {
	echo '<Cleanup>'
	cleanup() {
		ECHO
		if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ] || [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then echo "$1"; fi
		if [ -f "$intsd/$1" ] || [ -d "$intsd/$1" ]; then rm -rf "$intsd/$1"; fi
		if [ -f "$extsd/$1" ] || [ -d "$extsd/$1" ]; then rm -rf "$extsd/$1"; fi
	}
	source $cleanup_config
	
	# Unwanted Android directories
	
	obb() { if mntpt $intobb && [ -z "$1" ]; then rm -rf $extobb/Android; fi; }
	
	obbf() { if mntpt $intobb/$1 && [ -z "$2" ]; then rm -rf $extobb/$1/Android; fi; }
	
	target() { if mntpt "$intsd/$1" && [ -z "$2" ]; then rm -rf "$extsd/$1/Android"; fi; }
	
	from_to() { if mntpt "$intsd/$1" && [ -z "$3" ]; then rm -rf "$extsd/$2/Android"; fi; }
		
	bind_mnt() { if mntpt "$2" && [ -z "$3" ]; then rm -rf "$1/Android"; fi; }
			
	app_data() { if mntpt /data/data/$1 && [ -z "$2" ]; then rm -rf $extsd/.app_data/$1/Android; fi; }

	source $bind_list
	
	# Source optional cleanup script
	if [ -f $fbind_dir/cleanup.sh ]; then
		echo ". $fbind_dir/cleanup.sh"
		source $fbind_dir/cleanup.sh
		ECHO
	fi
	
	echo "- Done."
	ECHO
} 2>/dev/null

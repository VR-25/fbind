# fbind Core
# VR25 @ XDA Developers              


###CONSTANTS & VARIABLES###
intsd=/data/media/0
intobb=/data/media/obb
module_path=/magisk/fbind
fbind_dir=/data/_fbind
config_file=$fbind_dir/config.txt
config_path=$fbind_dir/.config
bind_list=$config_path/bind
debug_config=$config_path/debug
debug=$config_file
logfile=$fbind_dir/debug.log
cleanup_list=$config_file
cleanup_config=$config_path/cleanup
service_enabled=$module_path/service.sh
service_disabled=$module_path/service.disabled
altpart=false
bind_only=false
alt_extsd=false
tk=false
LinuxFS=false
tmp=/data/_tmp
tmp2=/data/_tmp2
mk_cfg=false


###TOOLBOX###

# Auto-recreate config file (fbind won't work without it)
if [ ! -f "$config_file" ]; then
	mk_cfg=true
	[ -d "$fbind_dir" ] || mkdir -p -m 777 $fbind_dir
	cat "$bind_list" "$cleanup_config" "$debug_config" > $config_file
	chmod 777 $config_file
fi

bind() { mount -o bind "$1" "$2"; }

toolkit() { tk=true; }

ECHO() { $tk && echo; }

mntpt() { mountpoint -q "$1"; } 2>/dev/null

wait_emulated() { until mntpt /storage/emulated; do sleep 1; done; }


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

# Set Alternate Partition
# For safety reasons, the mount point can't be "/FOLDER"
# $1=block_device, $2=mount_point $3=filesystem, $4="fsck OPTION(s)" (filesystem specific, optional)
altpart() {
	if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then echo "(!) altpart(): missing argument(s)!"; exit 2; fi
	echo "<Partition Information>"
	PARTITION=$(echo $1 | sed 's|.*/||')
	altpart=true
	extsd=$2
	extobb=$extsd/Android/obb
	if mntpt $2; then echo "$PARTITION already mounted!"
	else
		[ -d $2 ] || mkdir -p -m 777 $extobb
		until [ -b $1 ]; do sleep 1; done
		
		# cryptsetup (LUKS) support ( BinPath: $module_path/system/xbin/cryptsetup)
		if grep -v '#' $config_file | grep -q 'cryptsetup=true'; then
			cryptsetup luksOpen $1 $PARTITION
			[ $? ] && echo '***'
			[ "$4" ] && $4 /dev/mapper/$PARTITION
			mount -t $3 -o noatime,rw /dev/mapper/$PARTITION $2
		else
			[ "$4" ] && $4 $1
			mount -t $3 -o noatime,rw $1 $2
		fi
		
		if ! mntpt $2; then echo '***'; echo "(!) altpart(): $PARTITION mount failed!"; rmdir $extsd; exit 1; fi
		[ $? ] && echo '***' && df -h $2 | sed "s/Filesystem/   Partition ($3)/"
	fi
	echo
}

# Set Default extsd Path
default_extsd() {
	echo "<SD Card Information>"
	until grep -E '[0-9A-F]{4}-[0-9A-F]{4}' /proc/mounts; do sleep 1; done
	extsd="/mnt/media_rw/$(ls -1 /mnt/media_rw | grep -E '[0-9A-F]{4}-[0-9A-F]{4}')"
	extobb=$extsd/Android/obb
	echo
}

# Set Alternate extsd Path
# $1=PATH (i.e., /mnt/media_rw/NAME)
extsd_path() {
	echo "<SD Card Information>"
	until grep "$1" /proc/mounts; do sleep 1; done
	grep "$1" /proc/mounts | grep -Eq 'ext2|ext3|ext4|f2fs' && LinuxFS=true
	alt_extsd=true
	extsd="$1"
	extobb=$extsd/Android/obb
	echo
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
			grep -v '#' $config_file | grep -E 'Permissive_SELinux|altpart |extsd_path |intsd_path |intobb_path ' > $debug_config
			grep -vE '#|intobb_path ' $config_file | grep -E 'bind_mnt |app_data |obb|obbf |from_to |target ' > $bind_list
			grep -v '#' $config_file | grep 'cleanup' > $cleanup_config
			
			# Enable additional intsd paths for multi-user support
			grep '#' $config_file | grep -Eq 'u[0-9]{1}=|u[0-9]{2}=' > $config_path/uvars
			
			chmod -R 777 $config_path
			echo "- Done."
		fi
	fi
	echo
}
apply_cfg() {
	source $config_path/uvars
	source $debug_config
	if ! $altpart && ! $alt_extsd; then default_extsd; fi
}


###BACKUP CONFIG###
bkp_cfg() {
	if [ "$extsd/.fbind_bkp/config.txt" -ot "$config_file" ] && ! $mk_cfg; then
		[ -d "$extsd/.fbind_bkp" ] || mkdir -m 777 $extsd/.fbind_bkp
		cp $config_file $extsd/.fbind_bkp
		chmod 777 $extsd/.fbind_bkp/config.txt
	fi
}


###BINDING FUNCTION###
bind_folders() {
	ECHO
	echo "<Bind Folders>"
	SetEnforce_0
	# entire obb folder
	obb() {
		wait_emulated
		if ! mntpt $intobb; then
			ECHO
			[ -d $extobb ] || mkdir -p -m 777 $extobb
			[ -d $intobb ] || mkdir -p -m 777 $intobb
			echo "[$intobb] <--> [$extobb]"
			bind $extobb $intobb
		fi
	}
	# game/app obb folder
	obbf() {
		wait_emulated
		if ! mntpt $intobb/$1; then
			ECHO
			[ -d $extobb/$1 ] || mkdir -p -m 777 $extobb/$1
			[ -d $intobb/$1 ] || mkdir -p -m 777 $intobb/$1
			echo "[$intobb/$1] <--> [$extobb/$1]"
			bind $extobb/$1 $intobb/$1
		fi
	}
	# target folder
	target() {
		wait_emulated
		if ! mntpt "$intsd/$1"; then
			ECHO
			[ -d "$extsd/$1" ] || mkdir -p -m 777 "$extsd/$1"
			[ -d "$intsd/$1" ] || mkdir -p -m 777 "$intsd/$1"
			echo "[$intsd/$1] <--> [$extsd/$1]"
			bind "$extsd/$1" "$intsd/$1"
		fi
	}
	# source <--> destination
	from_to() {
			wait_emulated
			if ! mntpt "$intsd/$1"; then
				ECHO
				[ -d "$extsd/$2" ] || mkdir -p -m 777 "$extsd/$2"
				[ -d "$intsd/$1" ] || mkdir -p -m 777 "$intsd/$1"
				echo "[$intsd/$1] <--> [$extsd/$2]"
				bind "$extsd/$2" "$intsd/$1"
			fi
	}
	# data/data/folder <--> $extsd/.app_data/folder
	# $1=/data/data/folder
	app_data() {
		if ! $altpart && ! $LinuxFS; then ECHO; echo "(!) fbind: app_data() won't work without altpart() or extsd_path() (LinuxFS)!"; exit 2; fi
		if ! mntpt /data/.app_data/$1; then
			ECHO
			[ -d "$extsd/.app_data/$1" ] || mkdir -p -m 751 $extsd/.app_data/$1
			[ -d /data/data/$1 ] || mkdir -p -m 751 /data/data/$1
			echo "[/data/data/$1] <--> [$extsd/.app_data/$1]"
			bind $extsd/.app_data/$1 /data/data/$1
		fi
	}
	# other
	bind_mnt() {
		ECHO
		[ -d "$1" ] || mkdir -p -m 777 "$1"
		[ -d "$2" ] || mkdir -p -m 777 "$2"
		echo "$1 $2" | grep -Eq '$extsd|$intsd' && wait_emulated
		echo "bind_mnt [$1] [$2]"
		bind "$1" "$2"
	}
	source $bind_list
	SetEnforce_1
	ECHO
	echo "- Done."
	echo
	ECHO
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
		source $fbind_dir/cleanup.sh
		echo "Run optional cleanup.sh script"
	fi
	
	ECHO
	echo "- Done."
	ECHO
} 2>/dev/null

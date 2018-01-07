# Magic Folder Binder (fbind)     
## VR25 @ XDA Developers


### DESCRIPTION
- Forces Android to save select files/folders to the external_sd (or to a partition) by default, & clean up the user's storage (select unwanted files/folders) automatically.


### DISCLAIMER
- ALWAYS read the reference prior to installing/updating fbind. While no cats have been harmed in any way, shape or form, I assume no responsibility under anything that might go wrong due to the use/misuse of this module. 


### QUICK SETUP
1. Install the module.
2. Reboot.
3. Read `Config Syntax` below &/or `/data/media/fbind/info/config_samples.txt.`
4. Add lines to /data/media/fbind/config.txt with `fbind -a`, `fbind -ad` and/or `fbind -as`.
5. Run `fbind -mb` as root to move data & bind corresponding folders all at once.
6. Forget.


### CONFIG SYNTAX

- part [block device] [mount_point (any path except "/folder")] [file_system] ["fsck OPTION(s)" (filesystem specific, optional) --> auto-mount a partition -- to use as extsd, add the line extsd_path [mount_point]
- part [block device] [mount_point--M (any path except "/folder")] [file_system] ["fsck OPTION(s)" (filesystem specific, optional) --> auto-mount multiple partitions -- notice mount_point has a `--M` flag -- add extsd_path [mount_point] to use the target partition as extsd
- part [block device] [mount_point--L (any path except "/folder")] [file_system] ["fsck OPTION(s)" (filesystem specific, optional) --> open a LUKS volume -- disables auto-bind service -- fbind must be ran manually after boot to handle the process -- notice mount_point has a `--L` flag
- part [block device] [mount_point--ML (any path except "/folder")] [file_system] ["fsck OPTION(s)" (filesystem specific, optional) --> open multiple LUKS volumes -- notice mount_point has a `--ML` flag -- fbind must be ran manually after boot to handle the process
- LOOP [/path/to/.img/file] [mount_point] ["e2fsck -OPTION(s)" (optional)] --> mount a loopback device -- set it as extsd with "extsd_path [mount_point]"

- app_data [folder] --> data/data <--> extsd/.data (needs part or LinuxFS formated SD card), to use with intsd instead, include the config line "extsd_path $intsd"
- bind_mnt [TARGET mount_point] --> same as "mount -o bind [TARGET mount_point]"
- cleanup [file/folder] --> auto-remove unwanted files/folders from intsd & extsd -- including by default, unwanted "Android" directories
- extsd_path [/path/to/alternate/storage]) --> ignore for default -- /mnt/media_rw/*, include the line `extsd_path $intsd` in your config file if your device hasn't or doesn't support SD card
- from_to [intsd folder] [extsd folder] --> great for media folders & better organization
- intobb_path [path] --> i.e., /storage/emulated/0 (ignore for default -- /data/media/0)
- int_extf --> bind-mount the entire intsd to extsd/.fbind (includes obb)
- intsd_path [path] --> i.e., /storage/emulated/0/Android/obb (ignore for default -- /data/media/obb)
- obb --> bind-mount the entire /data/media/obb folder to extsd/Android/obb
- obbf [app/game folder] --> individual obb
- perms --> "pm grant" storage permissions to all apps (including future installations)
- target [target folder] --> great for standard paths (i.e., Android/data, TWRP/BACKUPS)
- no_bkp --> don't backup config

An additional argument (any string) to any of the binding functions above excludes additional "Android" folders from being deleted. For bind_mnt(), if the additional argument is `-mv`, then fbind -m affects that line too -- which is otherwise ignored by default for safety concerns. For app_data, "-u" allows fbind -u to "see" the specified line (also otherwise ignored by default).

You can add user variables to the config file. These must be in the format `u# or u##` -- i.e., u9=/data/media/9, u11=YouGetThePoint.

`fsck -OPTION(s) /path/to/partition` (i.e., `fsck.f2fs -f /dev/block/mmcblk1`) -- this will check for and/or fix SD card file system errors before system gets a chance to mount the target partition.


### TERMINAL

Usage: fbind OPTION(s) ARGUMENT(s)

-a		Add line(s) to config.txt (interactive)
-b		Bind all
-c		Storage cleanup
-d		Disable auto-bind service
-e		Re-enable auto-bind service
-f		Disable this toolkit
-l		Show config.txt
-m		Move data to the SD card
-r		Remove lines(s) from config.txt (interactive)
-u		Unmount all folders
-x		Disable fbind
-mb		Move data & bind corresponding folders
ref		Display README
log		Display debug.log

-ad		Add "app_data" line(s) to config.txt (interactive)

-as		Ask for SOURCE dir (intsd/SOURCE) & add corresponding "from_to" lines to config.txt (interactive)

-umb		(!) Unmount all folders, move data & rebind

restore		Move select data back to original locations (interactive)

rollback	Unmount all folders, uninstall fbind & restore files

uninstall	Unmount all folders & uninstall fbind

(i) The "-m" option affects unmounted folders only. Caution: it replaces destination data!

(!) Warning: only use "fbind -umb" if you know exactly what you're doing! That option is only intended for first time use -- i.e., in case you forgot to move data after installing the module for the very first time and rebooted. Since "-m" only moves unmounted folders data, the "-u" option makes it work. Again, once everything is unmounted, "-m" will then replace destination data. "fbind -mb" is the safer alternative, since it only moves new data. Let's say you just added a few lines to your config.txt file and the corresponding folders are not bound & data was not moved yet -- that is when you use this.


### DEBUGGING

* Logfile --> /data/media/fbind/debug.log

* Default internal storage paths (auto-configured)
- intsd_path /data/media/0
- intobb_path /data/media/obb

* Alternate internal storage paths
- intsd_path /storage/emulated/obb
- intobb_path /storage/emulated/0

* Bind issues
- Try the `alternate internal storage paths` above.

* If `/system/bin/fbind` causes a bootloop, move it to `system/xbin` by running `touch /data/.xfbind` prior to installing. The setting is persistent across updates.


### ONLINE SUPPORT
- [Git Repository](https://github.com/Magisk-Modules-Repo/Magic-Folder-Binder)
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/page2post72688621)


### CHANGELOG

**2018.1.7 (201801070)**
- Enhanced platform.xml patching engine & "perms" feature
- [EXPERIMENTAL] Ability to mount multiple partitions, loop devices (.img files) & open multiple LUKS volumes
- Fixed extsd_path() "slee" typo, "sestatus not found" & other issues
- Improved compatibility with older Magisk versions (entirely new installer)
- Major optimizations
- Updated documentation (pro tips included)

**2018.1.2 (201801020)**
- Added wildcards support to `fbind -as`
- Automatically restore config backup upon installation if current config is missing or empty
- Automatically set/reset `Mount Namespace Mode` to Global
- Backwards compatible with Magisk versions older than 15, suporting template v4+
- Fixed a critical bug that caused absurd delays in the folder binding process
- Major optimizations
- Major reference updates, especially config_samples.txt -- definitely worth checking that out
- Smart SELinux mode handling -- "if enforcing; then set to permissive; do fbind stuff; set back to enforcing; fi" ;)
- [TEST] New storage permissions workaround

**2017.12.4 (201712040)**
- [xbin/fbind] rename "cryptsetup=true" --> "luks"
- [xbin/fbind] rename "magisk/fbind" leftovers to "$ModPath"

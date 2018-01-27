# Magic Folder Binder (fbind)     
## VR25 @ XDA Developers



### DESCRIPTION
- Take full control over your storage space with this feature-rich folder mounting software.


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

- part [block_device] [mount_point (any path except "/folder")] [file_system] ["fsck OPTION(s)" (filesystem specific, optional) --> auto-mount a partition -- to use as extsd, add the line extsd_path [mount_point]
- part [block_device--L] [mount_point (any path except "/folder")] [file_system] ["fsck OPTION(s)" (filesystem specific, optional) --> open a LUKS volume -- disables auto-bind service -- fbind must be ran manually after boot to handle the process -- notice block_device has a `--L` flag
- LOOP [/path/to/.img/file] [mount_point] ["e2fsck -OPTION(s)" (optional)] --> mount a loopback device -- set it as extsd with "extsd_path [mount_point]"

- app_data [folder] --> data/data <--> extsd/.data (needs part or LinuxFS formated SD card), to use with intsd instead, include the config line "extsd_path $intsd"
- bind_mnt [TARGET mount_point] --> same as "mount -o bind [TARGET mount_point]"
- cleanup [file/folder] --> auto-remove unwanted files/folders from intsd & extsd -- including by default, unwanted "Android" directories
- extsd_path [/path/to/alternate/storage]) --> ignore for default -- /mnt/media_rw/*, include the line `extsd_path $intsd` in your config file if your device hasn't or doesn't support SD card
- from_to [intsd folder] [extsd folder] --> great for media folders & better organization
- int_extf --> bind-mount the entire intsd to extsd/.fbind (includes obb)
- intsd_path [path] --> i.e., intsd_path /storage/emulated/0 (ignore for default -- /data/media/0)
- obb --> bind-mount the entire /data/media/obb folder to extsd/Android/obb
- obbf [app/game folder] --> individual obb
- target [target folder] --> great for standard paths (i.e., Android/data, TWRP/BACKUPS)
- no_bkp --> disable config auto-backup (useful if you have a multi user setup)

An additional argument (any string) to any of the binding functions above excludes additional "Android" folders from being deleted. For bind_mnt(), if the additional argument is `-mv`, then fbind -m affects that line too -- which is otherwise ignored by default for safety concerns. For app_data, "-u" allows fbind -u to "see" the specified line (also otherwise ignored by default).

`fsck -OPTION(s) /path/to/partition` (i.e., `fsck.f2fs -f /dev/block/mmcblk1`) -- this will check for and/or fix SD card file system errors before system gets a chance to mount the target partition.



### TERMINAL

Magic Folder Binder

Usage: fbind OPTION(s) ARGUMENT(s)

-a --> Add line(s) to config.txt (interactive)
-b --> Bind all
-c --> Storage cleanup
-d --> Disable auto-bind service
-e --> Re-enable auto-bind service
-f --> Disable this toolkit
-l --> Show config.txt
-m --> Move data to the SD card (unmounted folders only)
-r --> Remove lines(s) from config.txt (interactive)
-u --> Unmount all folders
-x --> Disable fbind
-mb --> Move data & bind corresponding folders
ref --> Display README
log --> Display debug.log

-ad --> Add "app_data" line(s) to config.txt (interactive)

-as --> Asks for SOURCE dirs (intsd/SOURCE) & adds corresponding "from_to" lines to config.txt (interactive)

-umb --> (!) Unmount all folders, move data & rebind

--restore --> Move select data back to original locations (interactive)

--rollback --> Unmount all folders, uninstall fbind & restore data

--uninstall --> Unmount all folders & uninstall fbind



### DEBUGGING

* Logfile --> /data/media/fbind/debug.log

* Default internal storage paths (auto-configured)
- intsd_path /data/media/0

* Alternate internal storage path
- intsd_path /storage/emulated/0

* Bind issues
- Try the `alternate internal storage path` above.

* If `/system/xbin/fbind` causes a bootloop, move it to `system/bin` by running `touch /data/.bfbind` prior to installing. The setting is persistent across updates.



### ONLINE SUPPORT
- [Git Repository](https://github.com/Magisk-Modules-Repo/Magic-Folder-Binder)
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/page2post72688621)



### RECENT CHANGES

**2018.1.27 (201801270)**
- General optimizations & bug fixes

**2018.1.13-1 (201801131)**
- Fixed `-m` not creating source/destinations paths & `-mb` not binding folders

**2018.1.13 (201801130)**
- General optimizations
- Updated reference

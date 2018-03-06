# Magic Folder Binder (fbind)     
## VR25 @ xda-developers



### DISCLAIMER
- This module is provided as is, without warranty of any kind. Always read the reference prior to installing/updating it. While no cats have been harmed in any way, shape or form, I assume no responsibility under anything that might go wrong due to the use/misuse of it. 



### DESCRIPTION
- Take full control over your storage space with this feature-rich folder mounting tool.



### SETUP STEPS
1. Read `Config Syntax` below and/or `ZipFile/config_samples.txt`.
2. Read the `debugging section` at the bottom.
3. Install the module from Magisk Manager or TWRP and reboot.
4. Add lines to /data/media/fbind/config.txt with `fbind -a` (interactive)
5. Run `fbind -mb` as root to move data & bind-mount corresponding folders all at once.
6. Forget.



### CONFIG SYNTAX

- part [block_device] [mount_point] [filesystem] ["fsck OPTION(s)" (filesystem specific, optional) --> auto-mount a partition -- to use as extsd, add the line extsd_path [mount_point]
- part [block_device--L] [mount_point] [filesystem] ["fsck OPTION(s)" (filesystem specific, optional) --> open a LUKS volume -- disables auto-bind service -- fbind must be ran manually after boot to handle the process -- notice block_device has a `--L` flag
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

An additional argument (any string) to any of the binding functions above excludes additional "Android" folders from being deleted. For bind_mnt, if the additional argument is `-mv`, then fbind -m affects that line too -- which is otherwise ignored by default for safety concerns. For app_data, "-u" allows fbind -u to "see" the specified line (also otherwise ignored by default).

`fsck -OPTION(s) /path/to/partition` (i.e., `fsck.f2fs -f /dev/block/mmcblk1`) -- this checks for and/or fixes SD card filesystem errors before system gets a chance to mount it.



### TERMINAL

Magic Folder Binder

Usage: fbind OPTION(s) ARGUMENT(s)

-a --> Add line(s) to config.txt (interactive)
-b --> Bind all
-c --> Storage cleanup
-d --> Disable auto-bind service
-e --> Re-enable auto-bind service
-f --> Disable this toolkit
-l --> List config lines with corresponding mount statuses
-m --> Move data to the SD card (unmounted folders only)
-r --> Remove lines(s) from config.txt (interactive)
-u --> Unmount all folders
-x --> Disable fbind
-mb --> Move data & bind corresponding folders
ref --> Display full reference (README.md)
log --> View debug.log

-ad --> Add "app_data" line(s) to config.txt (interactive)

-as --> Asks for SOURCE dirs (intsd/SOURCE) & adds corresponding "from_to" lines to config.txt (interactive)

restore --> Move select data back to original locations (interactive)

rollback --> Unmount all folders, uninstall fbind & restore data

[no args] --> Open quick reference

uninstall --> Unmount all folders & uninstall fbind

-h/--help/help --> See all of this again

Pro tip: -ad, -b, -m, -mb, restore, -u and -umb, work with PATTERN and 'PATTERN1|PATTERN2|PATTERNn' arguments as well.
- Examples:
-- fbind -b 'WhatsA|Downl|ADM'
-- fbind -u '^obb$'
-- fbind -m mGit
-- fbind restore from_to



### DEBUGGING

* Logfile --> /data/media/fbind/debug.log

* Set alternate internal storage path (default is /data/media/0)
- intsd_path /storage/emulated/0

* Bind issues
- Add the line `setenforce auto` to your config. If that doesn't work, replace it with `setenforce 0`. Auto means fbind sets SELinux mode to permissive before running its operations, and back to enforcing afterwards. If the mode was already permissive, it's left untouched. Zero forces permissive mode.
- Try the `alternate internal storage path` above.

* If `/system/xbin/fbind` causes a bootloop, move it to `system/bin` by running `touch /data/.bfbind` prior to installing. The setting is persistent across updates.



### ONLINE SUPPORT
- [Git Repository](https://github.com/Magisk-Modules-Repo/Magic-Folder-Binder)
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/page2post72688621)



### TIPS/NOTES

- I you're having a hard time understanding all of the above, read a few more times until you've had enough -- then head to xda-developers for additional/interactive support.



### RECENT CHANGES

**2018.3.6 (201803060)**
- -ad, -b, -m, -mb, restore, -u and -umb, now work with PATTERN and 'PATTERN1|PATTERN2|PATTERNn' arguments as well -- check the `PRO TIPS` section in config_samples.txt for more info
- Disable ESDFS and SDCARDFS & enable FUSE
- "fbind" (no args) command now displays a quick on-terminal reference
- Fixed root check issue with certain Magisk versions
- Log additional storage info
- Major optimizations
- Optional SELinux mode handling (config lines: setenforce auto, setenforce 0)
- [TEST] Universal full external SD card read-write access (new platform.xml workaround) -- some [or all] users may need to set SELinux mode to permissive to actually benefit from this (config line: setenforce 0)
- The `-l` (list config lines) option now displays corresponding mount statuses too
- Updated cryptsetup binary -- LUKS2 support (untested, possibly kernel module needed)
- Updated documentation

**2018.1.31 (201801310)**
- [Boot scripts] run loop operations in the background and in parallel to avoid delaying other modules' scripts
- Minor optimizations

**2018.1.30 (201801300)**
- Fixed internal obb path not working with ESDFS

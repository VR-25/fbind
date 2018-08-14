# Magic Folder Binder (fbind)     
## Copyright (C) 2018, VR25 @ xda-developers
### License: GPL v3+



#### DISCLAIMER

- This software is provided as is, in the hope that it will be useful, but without any warranty. Always read the reference prior to installing/updating. While no cats have been harmed, I assume no responsibility under anything that might go wrong due to the use/misuse of it.
- A copy of the GNU General Public License, version 3 or newer ships with every build. Please, read it prior to using, modifying and/or sharing any part of this work.
- To prevent fraud, DO NOT mirror any link associated with this project.



#### DESCRIPTION

- Redirect internal storage data writes to the sdcard, auto-mount ext4 .img files (loop devices) & external storage partitions, save app data to external storage, open & mount LUKS/LUKS2 volumes... and more.



#### PRE-REQUISITES

- Magisk
- Mount Namespace mode set to "Global" in Magisk Manager settings
- Terminal emulator app (i.e., Termux)



#### SETUP STEPS

1. Read `Config Syntax` below and/or `$zipFile/common/tutorial.txt`.
2. Read the `debugging section` at the bottom.
3. Install the module from Magisk Manager or TWRP and reboot.
4. Add config lines to /data/media/fbind/config.txt with `fbind -a` interactive command.
5. Run `fbind -mb` as root to move data & bind-mount corresponding folders all in one shot.
6. Go on with your life.



#### CONFIG SYNTAX (lines to put in /data/media/fbind/config.txt)

- part [/path/to/block/device or /path/to/block/device--L] [/path/to/mount/point] [filesystem] ["fsck -OPTION(s)" (filesystem specific, optional) --> auto-mount a partition (the --L flag is for LUKS volume, opened manually by running `fbind` on terminal)

- LOOP [/path/to/.img/file] [/path/to/mount/point] --> mount an ext4 .img file (loop device) (preceded by e2fsck -fy /path/to/.img/file)

- app_data [pkgName] [/path/to/mount/point (excl. pkgName, optional)] [-u (optional)] --> save data/data/pkgName to $appDataRoot/pkgName (requires a supported Linux filesystem, i.e., ext2-4, f2fs. The default $appDataRoot is $extsd/.app_data. /path/to/mount/point can be a loop device mount point)

- bind_mnt [/path/to/folder/being/mounted] [/path/to/mount/point] --> same as "mount -o bind [/path/to/folder/being/mounted] [/path/to/mount/point]"

- cleanup [file/folder (name only)] --> auto-remove unwanted files/folders from intsd & extsd (including by default, additional "Android" directories)

- extsd_path [/path/to/alternate/folder] --> set an alternate path to sdcard (default /mnt/media_rw/`theFirstFound`)

- from_to [intsdFolderName] [extsdFolderName] --> "from SOURCE to DESTINATION" (obvious enough, right? This is great for media folders, as duplicates can be avoided -- i.e., from_to WhatsApp .hiddenFolder/WhatsApp)

- target [intsdFolderName] --> bind-mount intsd/folderName to extsd/sameFolderName (this is for standard, non-media folders only -- i.e., Android, TWRP, .hiddenFolder)

- int_extf --> bind-mount the entire user (internal) storage to extsd/.fbind (including /data/media/obb)

- intsd_path [/path/to/alternate/folder] --> set an alternate path to internal (user) storage (default /data/media/0)

- obb --> bind-mount the entire /data/media/obb folder to extsd/Android/obb

- obbf [pkgName] --> bind-mount /data/media/obb/pkgName to extsd/Android/obb/pkgName

- no_bkp --> disable config auto-backup (for multi-user setups)

- fsck -OPTION(s) /path/to/partition --> automatically fsck the target external storage partition (i.e., `fsck.f2fs -f /dev/block/mmcblk1`)

- Notes: paths containing spaces must be double quoted (i.e., `target "folder name with spaces"`). An additional argument (any string) to any of the binding functions above, excludes additional "Android" folders from being auto-removed (except for `app_data`, from which those are always deleted). For bind_mnt, if the additional argument is `-mv`, then `fbind -m` affects that line as well -- which is otherwise ignored by default for safety concerns. For app_data, `-u` allows `fbind -u` to "see" the specified line (also otherwise ignored by default). App data can reside in an ext4 .img file (loop device) -- for that, simply include the required `LOOP` line and add its mount point to app_data as second argument. This is useful, since it works whether or not the sdcard has a Linux filesystem.



#### TERMINAL COMMANDS

Usage: fbind [options(s)] [argument(s)]

-a --> Add line(s) to config.txt (interactive)
-b --> Bind-mount all folders
-c --> Cleanup storage
-d --> Disable auto-bind service
-e --> Re-enable auto-bind service
-f --> Disable auto-mount module files (Magisk built-in feature)
-i --> Display comprehensive info (config & statuses)
-m --> Move data to the sdcard (affects unmounted folders only)
-r --> Remove lines(s) from config.txt (interactive)
-u --> Unmount all folders
-x --> Disable module (Magisk built-in feature)
-mb --> Move data & bind corresponding folders
ref --> Display full reference (README.md)
log --> Display last service.sh_main_log.txt

-ad --> Add "app_data" line(s) to config.txt (interactive)

-as --> Ask for SOURCE dirs (intsd/SOURCE) & add corresponding "from_to" lines to config.txt (interactive)

restore --> Move select data back to original locations (interactive)

rollback --> Unmount all folders, uninstall fbind & restore data

[no args] --> Open quick reference

uninstall --> Unmount all folders & uninstall fbind

-h/--help/help --> See all of this again

Pro tip: -ad, -b, -m, -mb, restore, -u and -umb, work with PATTERN and 'PATTERN1|PATTERN2|PATTERN...' arguments as well.
- Examples:
-- fbind -b 'WhatsA|Downl|ADM'
-- fbind -u '^obb$|mmcblk1p3|loop1.img'
-- fbind -m mGit
-- fbind restore from_to



### THROUBLESHOOTING

* logsDir=/data/media/fbind/logs

* Make sure Mount Namespace mode is set to "Global" in Magisk Manager settings

* Set alternate internal storage path (default is /data/media/0)
- intsd_path /storage/emulated/0

- Add the line `setenforce auto` to your config. If that doesn't work, replace it with `setenforce 0`. "Auto" means fbind sets SELinux mode to permissive before running its operations and back to enforcing afterwards. If the mode was already permissive, it's left untouched. `setenforce 0` forces permissive mode.



#### NOTES/TIPS

- Always enforce Unix line ending (LF) when editing config.txt with other tools. NEVER use Windows Notepad!
- Busybox installation is unnecessary. The module uses Magisk's built-in version.
- If you're having a hard time understanding all of the above, read a few more times until you've had enough, then check out tutorial.txt (in the zip or at /data/media/fbind/info). If you're still stuck, head to the xda-developers thread for additional/interactive support (link below).



#### DEVICE-RELATED ISSUES

- Available free space in internal storage may be misreported.
- Duplicate sdcard may show up in file managers. In actuality, there's no such thing under the hood. That's a system bug.



#### LINKS

- [Facebook Support Page](https://facebook.com/VR25-at-xda-developers-258150974794782)
- [Git Repository](https://github.com/Magisk-Modules-Repo/Magic-Folder-Binder)
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/page2post72688621)



#### LATEST CHANGES

**2018.8.14 (201808140)**
- Aggressively enable FUSE & disable ESDFS and SDCARDFS
- Fixed `fbind -i` always showing mount points containing spaces as [UNMOUNTED]
- Fixed install failure from MM (Android P, Magisk 16.7)
- Fixed storage permissions patcher not working on A/B partition devices
- General optimizations
- Updated README.md, debugging tools and tutorial.txt (now includes "APK to sdcard")

**2018.8.10-1 (201808101)**
- Fixed "set_perms: not found"

**2018.8.10 (201808100)**
- General bug fixes
- Minor cosmetic changes

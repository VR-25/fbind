# Magic Folder Binder (fbind)     
## (c) 2018, VR25 @ xda-developers
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
- Terminal emulator app (Termux is recommended)



#### SETUP STEPS

1. Read `Config Syntax` below and/or `$zipFile/config_samples.txt`.
2. Read the `debugging section` at the bottom.
3. Install the module from Magisk Manager or TWRP and reboot.
4. Add config lines to /data/media/fbind/config.txt with `fbind -a` interactive command.
5. Run `fbind -mb` as root to move data & bind-mount corresponding folders all in one shot.
6. Go on with your life.



#### CONFIG SYNTAX (lines to put in /data/media/fbind/config.txt)

- part [/path/to/block/device or /path/to/block/device--L] [/path/to/mount/point] [filesystem] ["fsck -OPTION(s)" (filesystem specific, optional) --> auto-mount a partition (the --L flag is for LUKS volume, opened manually by running `fbind` on terminal)

- LOOP [/path/to/.img/file] [/path/to/mount/point] --> mount an ext4 ext4 .img file (loop device) (preceded by e2fsck -fy /path/to/.img/file)

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

- Always use Unix line ending (LF) when editing config.txt with other tools. NEVER use Windows Notepad!
- Busybox installation is unnecessary. The module uses Magisk's built-in version.
- If you're having a hard time understanding all of the above, read a few more times until you've had enough, then check out config_samples.txt (in the zip or at /data/media/fbind/info). If you're still stuck, head to the xda-developers thread for additional/interactive support (link below).



#### DEVICE-RELATED ISSUES

- Available free space in internal storage may be misreported.
- Duplicate sdcard may show up in file managers. In actuality, there's no such thing under the hood. That's a system bug.



#### ONLINE SUPPORT

- [Git Repository](https://github.com/Magisk-Modules-Repo/Magic-Folder-Binder)
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/page2post72688621)



#### RECENT CHANGES

**2018.8.6 (201808060)**
- General optimizations
- Set second fallback extsd path (intsd)

**2018.8.1 (201808010)**
- Auto-detect whether fbind should go to bin or xbin dir to avoid bootloops
- General optimizations
- Striped down (removed unnecessary code & files)
- New and simplified installer
- Updated documentation

**2018.7.24 (201807240)**
- Ability to unmount loop devices and partitions on demand (i.e., fbind -u 'pattern1|pattern2|pattern...').
- Better loop device mounting logic ("ugly bugs" fixed)
- Bind-mount folders automatically regardless of --L (LUKS) flag's usage.
- Dedicated logs dir -- /data/media/fbind/logs (easier & advanced debugging)
- Deprecated `fbind -l` in favor of `fbind -i` (outputs much more information)
- Fixed "misleading [N/A] mount status".
- Fixed modPath detection & bad PATH variable issues (Magisk V16.6).
- Fixed "rm -rf not affecting hidden files/folders" in data moving functions.
- Ignore `app_data` line whose target apk is missing (to avoid app data loss).
- Option to mount app_data in ext4 .img file (loop device)
- Shipping with a comprehensive, noob-friendly tutorial (tutorial.txt, /data/media/fbind/info/tutorial.txt)
- Reliability improvements (better data loss protection algorithms)
- Updated documentation
- Using `rsync -a` for advanced copy operations, instead of `cp -a`.

# Magic Folder Binder (fbind)
## README.md
### Copyright (C) 2018, VR25 @ xda-developers
#### License: GPL v3+



---
#### DISCLAIMER

This software is provided as is, in the hope that it will be useful, but without any warranty. Always read/reread this reference prior to installing/upgrading. While no cats have been harmed, I assume no responsibility under anything which might go wrong due to the use/misuse of it.

A copy of the GNU General Public License, version 3 or newer ships with every build. Please, read it prior to using, modifying and/or sharing any part of this work.

To prevent fraud, DO NOT mirror any link associated with this project; DO NOT share ready-to-flash builds (zips) online!



---
#### DESCRIPTION

- Redirect select internal storage data to the actual SDcard; open & mount LUKS/LUKS2 volumes; auto-mount regular partitions... and more.



---
#### PRE-REQUISITES

- Magisk 15.0-17.3
- Terminal emulator app (i.e., Termux)



---
#### SETUP STEPS

Assuming you've read the entire documentation,
1. Install fbind from Magisk Manager or TWRP and reboot.
2. Create and customize `/data/media/fbind/config.txt`.
3. Run `fbind -mb` as root to move data & bind-mount corresponding folders.
4. Go on with your life.



---
#### CONFIG SYNTAX

- part </path/to/block/device or /path/to/block/device--L> </path/to/mount/point> <"fsck -OPTION(s)" (filesystem specific, optional)> -- auto-mount a partition (the --L flag is for LUKS volume, opened manually by running `fbind` on terminal)

- LOOP </path/to/.img/file> </path/to/mount/point> -- mount an ext4 .img file (loop device) (preceded by e2fsck -fy /path/to/.img/file)

- app_data <pkgName> </path/to/mount/point (excl. pkgName, optional)> <-u (optional)> -- save data/data/pkgName to $appDataRoot/pkgName (requires a supported Linux filesystem, i.e., ext2-4, f2fs. The default $appDataRoot is $extsd/.app_data. /path/to/mount/point can be a loop device mount point)

- bind_mnt </path/to/folder/being/mounted> </path/to/mount/point> -- same as "mount -o bind </path/to/folder/being/mounted> </path/to/mount/point>"

- cleanup <file/folder (name only)> -- auto-remove unwanted files/folders from intsd & extsd (including by default, additional "Android" directories)

- extsd_path </path/to/alternate/folder> -- set an alternate path to sdcard (default /mnt/media_rw/`theFirstFound`)

- from_to <intsdFolderName> <extsdFolderName> -- "from SOURCE to DESTINATION" (obvious enough, right? This is great for media folders, as duplicates can be avoided -- i.e., from_to WhatsApp .hiddenFolder/WhatsApp)

- target <intsdFolderName> -- bind-mount intsd/folderName to extsd/sameFolderName (this is for standard, non-media folders only -- i.e., Android, TWRP, .hiddenFolder)

- int_extf -- bind-mount the entire user (internal) storage to extsd/.fbind (including /data/media/obb)

- intsd_path </path/to/alternate/folder> -- set an alternate path to internal (user) storage (default /data/media/0)

- obb -- bind-mount the entire /data/media/obb folder to extsd/Android/obb

- obbf <pkgName> -- bind-mount /data/media/obb/pkgName to extsd/Android/obb/pkgName

- Notes: paths containing spaces must be double-quoted (i.e., `target "folder name with spaces"`). An additional argument (any string) to any of the binding functions above, excludes additional "Android" folders from being auto-removed (except for `app_data`, from which those are always deleted). For bind_mnt, if the additional argument is `-mv`, then `fbind -m` affects that line as well -- which is otherwise ignored by default for safety concerns. For app_data, `-u` allows `fbind -u` to "see" the specified line (also otherwise ignored by default). App data can reside in an ext4 .img file (loop device) -- for that, simply include the required `LOOP` line and add its mount point to app_data as second argument. This is useful, since it works whether or not the sdcard has a Linux filesystem.



---
#### TERMINAL COMMANDS

Magic Folder Binder

Usage: fbind <options(s)> <argument(s)>

-a   Add line(s) to config.txt (interactive)
-b   Bind-mount all folders
-c   Cleanup storage
-f   Disable auto-mount module files (Magisk built-in feature)
-i   Display comprehensive info (config & statuses)
-m   Move data to the sdcard (affects unmounted folders only)
-r   Remove lines(s) from config.txt (interactive)
-u   Unmount all folders
-x   Disable module (Magisk built-in feature)
-mb   Move data & bind corresponding folders
ref   Display full reference (README.md)
log   Display latest service.sh.log

-ad   Add "app_data" line(s) to config.txt (interactive)

-as   Ask for SOURCE dirs (intsd/SOURCE) & add corresponding "from_to" lines to config.txt (interactive)

restore   Move select data back to original locations (interactive)

rollback   Unmount all folders, uninstall fbind & restore data

[no args]   Open quick reference

uninstall   Unmount all folders & uninstall fbind

-h/--help/help   See all of this again

Pro tip: -ad, -b, -m, -mb, restore, -u and -umb, work with PATTERN and PATTERN1|PATTERN2|PATTERN... arguments as well.
  - Examples:
    - fbind -b WhatsA|Downl|ADM
    - fbind -u ^obb$|mmcblk1p3|loop1.img
    - fbind -m mGit
    - fbind restore from_to



---
### THROUBLESHOOTING

- logsDir=/data/media/fbind/logs/

- Set alternate internal storage path (default is /data/media/0): intsd_path /storage/emulated/0



---
#### NOTES/TIPS

- Always enforce Unix line ending (LF) when editing config.txt with other tools. NEVER use Windows Notepad!
- Busybox installation is unnecessary. The module uses Magisk's built-in.
- If you're having a hard time understanding all of the above, read a few more times until you've had enough, then check out `tutorial.txt` (located at `$zipFile/common/` or `/data/media/fbind/info/`). If you're still stuck, head to the xda-developers thread for additional/interactive support (link below).



---
#### DEVICE-SPECIFIC ISSUES

- Available free space in internal storage may be misreported.
- Duplicate sdcard may show up in file managers.



---
#### SUPPORT

- [Facebook page](https://facebook.com/VR25-at-xda-developers-258150974794782/)
- [Git repository](https://github.com/Magisk-Modules-Repo/fbind/)
- [Telegram profile](https://t.me/vr25xda/)
- [XDA thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/)



---
#### LATEST CHANGES

**2018.10.30.1 (201810301)**
- Fixed <unable to bind-mount folders whose names contain space characters>.
- Updated support links

**2018.10.30 (201810300)**
- Boot script is now in two different locations, but it'll run only once. Hopefully this rogue behavior ensures auto-bind works every time.
- Corrected wrong version numbers in module.prop.
- Fixed <fbind.sh permissions not changing due to MOUNTPOINT0 variable being local to install_module()>.
- Minor cosmetic changes
- Use </sbin/su -Mc mount -o rw,gid=9997,noatime> as <mount> alias.

**2018.10.29 (201810290)**
- Automatic partition filesystem detection
- Doubled SDcard wait timeout
- Enforce the <global> mount namespace by running <mount> under <su -Mc>.
- Generate basic logs as opposed to verbose.
- Magisk 15.0-17.3 support
- Remove modified props from /data/property/ and don't create these again.
- Removed <setenforce x> and other rather useless features.
- Save tmp files to </dev/fbind/>.
- Updated building and debugging tools
- Updated documentation
- Use <var=$((var + 1))> instead of <var++>.
- Use the largest SDcard partition as fallback for bind-mounts.

**2018.8.15 (201808150)**
- Auto-revert persistent props if fbind is disabled/removed
- Misc optimizations

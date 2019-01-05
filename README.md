# fbind
## Copyright (C) 2017-2019, VR25 @ xda-developers
### License: GPL V3+
#### README.md



---
#### DISCLAIMER

This software is provided as is, in the hope that it will be useful, but without any warranty. Always read/reread this reference prior to installing/upgrading. While no cats have been harmed, I assume no responsibility under anything which might go wrong due to the use/misuse of it.

A copy of the GNU General Public License, version 3 or newer ships with every build. Please, study it prior to using, modifying and/or sharing any part of this work.

To prevent fraud, DO NOT mirror any link associated with this project; DO NOT share ready-to-flash-builds (zips) on-line!



---
#### DESCRIPTION

This is an advanced mounting utility for folders, EXT4 images (loop devices), LUKS/LUKS2 encrypted volumes, regular partitions and more.



---
#### PRE-REQUISITES

- Any root solution, preferably Magisk 17.0+
- App to run `/system/etc/fbind/autorun.sh` on boot if system doesn't support Magisk nor init.d
- ARM/ARM64 CPU
- Basic `mount` and terminal usage knowledge
- Terminal Emulator (i.e., Termux)



---
#### CONFIG SYNTAX

- bind_mount <target> <mount point>   Generic bind-mount
  - e.g., `bind_mount $extsd/loop_device/app_data/spotify /data/data/com.spotify.music`

- extsd_path <path>   Use <path> as extsd.
  - e.g., `extsd_path /mnt/mmcblk1p2`

- from_to <source> <dest>   Wrapper for `bind_mount <$extsd/[path]> <$intsd/[path]>`
  - e.g., `from_to WhatsApp .WhatsApp`

- <fsck> <block device>   Check/fix external partition before system gets a chance to mount it. This is great for EXT[2-4] filesystems (e2fsck -fy is stable and fast) and NOT recommend for F2FS (fsck.f2fs can be extremely slow and cause/worsen corruption).
  - e.g., `e2fsck -fy /dev/block/mmcblk1p1`

- int_extf <path>   Bind-mount the entire user 0 (internal) storage to `$extsd/<path>` (implies obb). If `<path>` is not supplied, `.fbind` is used.
  - e.g., `int_extf .external_storage`

- intsd_path <path>   Use <path> as intsd.
  - e.g., `intsd_path /storage/emulated/0`

- loop <.img file> <mount point>   Mount an EXT4 .img file (loop device). `e2fsck -fy <.img file>` is executed first.
  - e.g., `loop $extsd/loop.img $intsd/loop`

- noAutoMount   Disable on boot auto-mount.

- noWriteRemount   Read the SDcardFS note below.

- obb   Wrapper for `bind_mount $extobb $obb`

- obbf <package name>   Wrapper for `bind_mount $extobb/<package name> $obb/<package name>`
  - e.g., `obbf com.mygame.greatgame`

- part <[block device] or [block device--L]> <mount point> <"fsck -OPTION(s)" (filesystem specific, optional)>   Auto-mount a partition. The --L flag is for LUKS volume, opened manually by running any `fbind` command. Filesystem is automatically detected. The first two arguments can be `-o <mount options>`, respectively. In that case, positional parameters are shifted. The defaut mount options are `rw` and `noatime`.
  - e.g., `part /dev/block/mmcblk1p1 /mnt/_sdcard`
  - e.g., `part -o nodev,noexec,nosuid /dev/block/mmcblk1p1 /mnt/_sdcard`

- permissive   Set SELinux mode to permissive.

- remove <target>   Auto-remove stubborn/unwanted file/folder from $intsd & $extsd.
  - e.g, `remove Android/data/com.facebook.orca`, `remove DCIM/.8be0da06c44688f6.cfg`

- target <path>   Wrapper for `bind_mount <$extsd/[path]> <$intsd/[same path]>`
  - e.g., `target Android/data/com.google.android.youtube`



---
#### TERMINAL

`Usage: fbind or fbind <options(s)> <argument(s)>

<no options>   Launch the folder mounting wizard.

-a|--auto-mount   Toggle on boot auto-mount (default: enabled).

-b|--bind-mount <target> <mount point>   Bind-mount folders not listed in config.txt. Extra SDcarsFS paths are handled automatically. Missing directories are created accordingly.
  e.g., fbind -b /data/someFolder /data/mountHere

-c|--config <editor [opts]>   Open config.txt w/ <editor [opts]> (default: vim/vi).
  e.g., fbind -c nano -l

-C|--cryptsetup <opt(s)> <arg(s)>   Run $modPath/bin/cryptsetup <opt(s)> <arg(s)>.

-f|--fuse   Toggle force FUSE yes/no (default: no). This is automatically enabled during installation if /data/forcefuse exists or the zip name contains the word "fuse" (case insensitive) or PROPFILE=true in config.sh. The setting persists across upgrades.

-h|--help  List all commands.

-i|--info   Show debugging info.

-l|--log  <editor [opts]>   Open fbind-boot-\$deviceName.log w/ <editor [opts]> (default: vim/vi).
  e.g., fbind -l

-m|--mount <pattern|pattern2|...>   Bind-mount matched or all (no arg).
  e.g., fbind -m Whats|Downl|part

-M|--move <pattern|pattern2|...>   Move matched or all (no args) to external storage. Only unmounted folders are affected.
  e.g., fbind -M Download|obb

-Mm <pattern|pattern2|...>   Same as "fbind -M <arg> && fbind -m <arg>"
  e.g., fbind -Mm

-r|--readme   Open README.md w/ <editor [opts]> (default: vim/vi).

-R|--remove <target>   Remove stubborn/unwanted file/folder from $intsd and $extsd. <target> is optional. By default, all <remove> lines from config are included.
  e.g., fbind -R Android/data/com.facebook.orca

-u|--unmount <pattern|pattern2|... or [mount point] >   Unmount matched or all (no arg). This works for regular bind-mounts, SDcardFS bind-mounts, regular partitions, loop devices and LUKS/LUKS2 encrypted volumes. Unmounting all doesn't affect partitions nor loop devices. These must be unmounted with a pattern argument. For unmounting folders bound with the -b|--bind_mount option, <mount point> must be supplied, since these pairs aren't in config.txt.
  e.g., fbind -u loop|part|Downl



---
#### NOTES

- Always enforce Unix line ending (LF) when editing config.txt with other tools. NEVER use Windows Notepad!

- Available free space in internal storage may be misreported.

- Busybox installation is unnecessary, unless fbind is installed into /system (legacy/Magisk-unsupported devices only).

- Config survives factory resets if internal storage (data/media/) is not wiped.

- Duplicate SDcard may show up in file managers.

- [FUSE] Some users may need to set `intsd_path /storage/emulated/0` (default is /data/media/0).

- If you stumble upon inaccessible folders or read-only access, try forcing FUSE mode (fbind -f). If your system doesn't support FUSE, it will bootloop, but fbind will notice and automatically revert the change.

- Logs are stored at `/data/adb/fbind/logs/`.

- [SDcardFS] Remounting /mnt/runtime/write/... may cause a system reboot. If this happens, fbind remembers to skip that next times.

- There is a sample config in `$zipFile/common/` and `/data/adb/fbind/info/`.



---
#### SETUP

First time
1. Install from Magisk Manager or custom recovery.
2. Reboot.
3. Configure (/data/adb/fbind/config.txt) -- recall that `fbind -c <editor [opts]>` opens config.txt w/ <editor [opts]> (default: vim/vi).
4. Move data to the SDcard with a file manager or `fbind --move` then run `fbind --mount`.

Upgrades
1. Install from Magisk Manager or custom recovery.
2. Reboot.

After ROM updates
- Unless `addon.d` feature is supported by the ROM, follow the upgrade steps above.

Bootloop (Magisk only)
- Flash the same version again to disable the module.

Uninstall
1. Magisk: use Magisk Manager or other tool; legacy: flashing the same version again removes all traces of fbind from /system.
2. Reboot.



---
#### LINKS

- [Facebook page](https://facebook.com/VR25-at-xda-developers-258150974794782/)
- [Git repository](https://github.com/Magisk-Modules-Repo/fbind/)
- [Telegram channel](https://t.me/vr25_xda/)
- [Telegram profile](https://t.me/vr25xda/)
- [XDA thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/)



---
#### LATEST CHANGES

**2019.1.5 (201901050)**
- Fixed auto-mount toggle (fbind -a) inverted output.
- Forcing FUSE mode (fbind -f) causes bootloop if the system doesn't support that. When this happens, changes are automatically reverted.
- General optimizations
- Under SDcardFS, remounting /mnt/runtime/write/... may cause a system reboot. If this happens, fbind remembers to skip that next times (noWriteRemount).
- Updated building tools
- Wizard has a "troubleshooting" option.

**2019.1.2 (201901020)**
- fbind -R|--remove <target>: remove stubborn/unwanted file/folder from $intsd and $extsd. <target> is optional. By default, all <remove> lines from config are included.
- fbind <no options>: launch the folder mounting wizard.
- fsck SDcard, refer to README.md (fbind -r) for details.
- Major fixes & optimizations

**2018.12.28 (201812280)**
- Fixed LUKS opening|mounting issues
- Fixed wrong modData path
- General fixes and optimizations
- Toggle `noAutoMount` (fbind -a|--auto-mount)
- Updated documentation
- Wait until data is decrypted

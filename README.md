# fbind
## Copyright (C) 2017-2018, VR25 @ xda-developers
### License: GPL V3+
#### README.md



---
#### DISCLAIMER

This software is provided as is, in the hope that it will be useful, but without any warranty. Always read/reread this reference prior to installing/upgrading. While no cats have been harmed, I assume no responsibility under anything which might go wrong due to the use/misuse of it.

A copy of the GNU General Public License, version 3 or newer ships with every build. Please, study it prior to using, modifying and/or sharing any part of this work.

To prevent fraud, DO NOT mirror any link associated with this project; DO NOT share ready-to-flash-builds (zips) on-line!



---
#### DESCRIPTION

- Advanced mounting utility for folders, EXT4 images (loop devices), LUKS/LUKS2 encrypted volumes, regular partitions and more...



---
#### PRE-REQUISITES

- Any root solution, preferably Magisk 17.0+
- App to run `/system/etc/fbind/autorun.sh` on boot if system doesn't support Magisk nor init.d
- ARM/ARM64 CPU
- Basic `mount` and terminal usage knowledge
- Terminal Emulator (i.e., Termux)



---
#### CONFIG SYNTAX

- bind_mount <target> <mount point>   Generic bind-mount, example: `bind_mount $extsd/loop_device/app_data/spotify /data/data/com.spotify.music`

- extsd_path <path>   Use <path> as extsd. Example: `extsd_path /mnt/mmcblk1p2`

- from_to <source> <dest>   Wrapper for `bind_mount <$extsd/[path]> <$intsd/[path]>`, example: `from_to WhatsApp .WhatsApp`

- int_extf <path>   Bind-mount the entire user 0 (internal) storage to `$extsd/<path>` (implies obb). If `<path>` is not supplied, `.fbind` is used. Example: `int_extf .external_storage`

- intsd_path <path>   Use <path> as intsd. Example: `intsd_path /storage/emulated/0`

- loop <.img file> <mount point>   Mount an EXT4 .img file (loop device). `e2fsck -fy <.img file>` is executed first. Example: `loop $extsd/loop.img $intsd/loop`

- obb   Wrapper for `bind_mount $extobb $obb`

- obbf <package name>   Wrapper for `bind_mount $extobb/<package name> $obb/<package name>`, example: `obbf com.mygame.greatgame`

- part <[block device] or [block device--L]> <mount point> <"fsck -OPTION(s)" (filesystem specific, optional)>   Auto-mount a partition. The --L flag is for LUKS volume, opened manually by running any `fbind` command. Filesystem is automatically detected. The first two arguments can be `-o <mount options>`, respectively. In that case, positional parameters are shifted. The defaut mount options are `rw` and `noatime`. Example 1: `part /dev/block/mmcblk1p1 /mnt/_sdcard`, example 2: `part -o nodev,noexec,nosuid /dev/block/mmcblk1p1 /mnt/_sdcard`

- permissive   Set SELinux mode to permissive.

- remove <path>   Auto-remove stubborn/unwanted file/folder from intsd & extsd. Examples: `remove Android/data/com.facebook.orca`, `remove DCIM/.8be0da06c44688f6.cfg`

- target <path>   Wrapper for `bind_mount <$extsd/[path]> <$intsd/[same path]>`, example: `target Android/data/com.google.android.youtube`



---
#### TERMINAL

`Usage: fbind <options(s)> <argument(s)>

-b/--bind_mount <target> <mount point>   Bind-mount folders not listed in config.txt. Extra SDcarsFS paths are handled automatically. Missing directories are created accordingly.
  e.g., fbind -b /data/someFolder /data/mountHere

-c/--config <editor [opts]>   Open config.txt w/ <editor [opts]> (default: vim/vi).
  e.g., fbind -c nano -l

-C/--cryptsetup <opt(s)> <arg(s)>   Run $modPath/bin/cryptsetup <opt(s)> <arg(s)>.

-f/--fuse   Toggle force FUSE yes/no (default: no). This is automatically enabled during installation if /data/forcefuse exists or the zip name contains the word "fuse" (case insensitive) or PROPFILE=true in config.sh. The setting persists across upgrades.

-i/--info   Show debugging info.

-l/--log  <editor [opts]>   Open fbind-boot-\$deviceName.log w/ <editor [opts]> (default: vim/vi).
  e.g., fbind -l

-m/--mount <pattern|pattern2|...>   Bind-mount matched or all (no arg).
  e.g., fbind -m Whats|Downl|part

-M/--move <pattern|pattern2|...>   Move matched or all (no args) to external storage. Only unmounted folders are affected.
  e.g., fbind -M Download|obb

-Mm <pattern|pattern2|...>   Same as "fbind -M <arg> && fbind -m <arg>"
  e.g., fbind -Mm

-r/--readme   Open README.md w/ <editor [opts]> (default: vim/vi).

-u/--unmount <pattern|pattern2|... or [mount point] >   Unmount matched or all (no arg). This works for regular bind-mounts, SDcardFS bind-mounts, regular partitions, loop devices and LUKS/LUKS2 encrypted volumes. Unmounting all doesn't affect partitions nor loop devices. These must be unmounted with a pattern argument. For unmounting folders bound with the -b/--bind_mount option, <mount point> must be supplied, since these pairs aren't in config.txt.
  e.g., fbind -u loop|part|Downl

Run fbins -r to see the full documentation (enter ":q!" to quit).`



---
#### NOTES

- Always enforce Unix line ending (LF) when editing config.txt with other tools. NEVER use Windows Notepad!

- Available free space in internal storage may be misreported.

- Busybox installation is unnecessary, unless fbind is installed into /system (legacy/Magisk-unsupported devices only).

- Config survives factory resets if internal storage (data/media/) is not wiped.

- Duplicate SDcard may show up in file managers.

- [FUSE] Some users may need to set `intsd_path /storage/emulated/0` (default is /data/media/0).

- Logs are stored at `/data/adb/fbind/logs/`.

- [SDcardFS] Remounting /mnt/runtime/write/... may cause a system reboot. If this happens, go to recovery terminal and run `echo noWriteRemount >>/sdcard/fbind/config.txt`.

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

**2018.12.24 (201812240)**
- [General] Fixes and optimizations
- [General] modData=/data/adb/fbind to bypass FBE (File Based Encryption). Config survives factory resets if internal storage (data/media/) is not wiped.
- [General] Updated documentation
- [part()] Automatic LUKS decryption (`blockDevice--L,PASSPHRASE`, optional)
- [part()] Support for extra mount options (part -o <mount opts> <block device> <mount point> <fsck command (e.g., "e2fsck -fy"), optional>

**2018.12.15 (201812150)**
- [SDcardFS] Additional variables for config.txt: extsd0=/mnt/media_rw/SDcardName, extobb0=$extsd0/Android/obb
- [SDcardFS] Do not remount /mnt/runtime/(read|write)/... if $extsd doesn't start with /mnt/runtime/.
- [SDcardFS] Remounting /mnt/runtime/write/... may cause a system reboot. If this happens, go to recovery terminal and run `echo noWriteRemount >>/sdcard/fbind/config.txt`.

**2018.12.14 (201812140)**
- [SDcardFS] Do not remount /mnt/runtime/write/....
- [SDcardFS] Do not set gid.
- [SDcardFS] obb=$intsd/Android/obb

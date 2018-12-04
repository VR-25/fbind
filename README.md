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

- Redirect select internal storage data to the actual SDcard; mount loop devices, LUKS/LUKS2 encrypted volumes, regular partitions... and more.



---
#### PRE-REQUISITES

- Any root solution, preferably Magisk V15.0+
- Basic `mount` and terminal usage knowledge
- Terminal Emulator (i.e., Termux)

- If your system doesn't support init.d, use an app to run `/system/etc/fbind/autorun.sh` on boot.



---
#### SETUP

First time
1. Install from Magisk Manager or custom recovery.
2. Configure
3. Reboot

Upgrade
1. Install from Magisk Manager or custom recovery.
2. Reboot

After ROM updates
- Unless `addon.d` feature is supported by the ROM, follow the upgrade steps above.

Uninstall
1. Remove through Magisk Manager app or MM for Recovery Mode (another module/tool built and maintained by me). On legacy devices, fashing the same version again removes all traces of fbind from /system.
2. Reboot



---
#### CONFIG SYNTAX

- bind_mount <target> <mount point>   Generic bind-mount, example: `bind_mount $extsd/loop_device/app_data/spotify /data/data/com.spotify.music`

- extsd_path <path>   Use <path> as extsd. Example: `extsd_path /data/mmcblk1p2`

- from_to <source> <dest>   Wrapper for `bind_mount <$extsd/[path]> <$intsd/[path]>`, example: `from_to WhatsApp .WhatsApp`

- int_extf <path>   Bind-mount the entire user (internal) storage to `$extsd/<path>` (includes OBB). If `<path>` is not supplied, `.fbind` is used. Example: `int_extf .external_storage`

- intsd_path <path>   Use <path> as intsd. Example: `intsd_path /storage/emulated/0`

- loop <.img file> <mount point>   Mount an EXT4 .img file (loop device). `e2fsck -fy <.img file>` is executed first. Example: `loop $extsd/loop.img $intsd/loop`

- obb   Wrapper for `bind_mount $extobb $obb`

- obbf <package name>   Wrapper for `bind_mount $extobb/<package name> $obb/<package name>`, example: `obbf com.mygame.greatgame`

- part <[block device] or [block device--L]> <mount point> <"fsck -OPTION(s)" (filesystem specific, optional)>   Auto-mount a partition. The --L flag is for LUKS volume, opened manually by running any `fbind` command. Example: `part /dev/block/mmcblk1p1 /data/_sdcard`

- remove <path>   Auto-remove unwanted file/folder from intsd & extsd. Examples: `remove Android/data/com.facebook.orca`, `remove DCIM/.8be0da06c44688f6.cfg`

- target <path>   Wrapper for `bind_mount <$extsd/[path]> <$intsd/[same path]>`, example: `target Android/data/com.google.android.youtube`



---
#### TERMINAL

`Usage: fbind <options(s)> <argument(s)>

-b/--bind_mount <target> <mount point>   Bind-mount folders not listed in config.txt. Additional SDcardFS mounts are handled automatically. Missing paths are created accordingly.

-c/--config <editor [opts]>   Open config.txt w/ <editor [opts]> (default: vim/vi).

-C/--cryptsetup <opt(s)> <arg(s)>   Run $modPath/bin/cryptsetup <opt(s)> <arg(s)>.

-i/--info   Show debugging info.

-l/--log  <editor [opts]>   Open fbind-boot-$deviceName.log w/ <editor [opts]> (default: vim/vi).

-m/--mount <pattern|pattern2|...>   Bind-mount matched or all (no arg).

-M/--move <pattern|pattern2|...>   Move matched or all (no args) to external storage. Only unmounted folders are affected.

-Mm <pattern|pattern2|...>   Same as "fbind -M <arg> && fbind -m <arg>"

-r/--readme   Open README.md w/ <editor [opts]> (default: vim/vi).

-u/--unmount <pattern|pattern2|... or [mount point] >   Unmount matched or all (no arg). This works for regular bind-mounts, SDcardFS bind-mounts, regular partitions, loop devices and LUKS/LUKS2 encrypted volumes. Unmounting all doesn't affect partitions nor loop devices. These must be unmounted with a pattern argument. For unmounting folders bound with the -b/--bind_mount option, <mount point> must be supplied, since these pairs aren't in config.txt.`



---
#### NOTES

- Always enforce Unix line ending (LF) when editing config.txt with other tools. NEVER use Windows Notepad!

- Available free space in internal storage may be misreported.

- Busybox installation is unnecessary, unless fbind is installed into /system (legacy/Magisk-unsupported devices only).

- Duplicate SDcard may show up in file managers.

- [FUSE] Some users may need to set `intsd_path /storage/emulated/0` (default is /data/media/0).

- Logs are stored at `/data/media/fbind/logs/`.

- There is a sample config in `$zipFile/common/` and `/data/media/fbind/info/`.



---
#### SUPPORT

- [Facebook page](https://facebook.com/VR25-at-xda-developers-258150974794782/)
- [Git repository](https://github.com/Magisk-Modules-Repo/fbind/)
- [Telegram channel](https://t.me/vr25_xda/)
- [Telegram profile](https://t.me/vr25xda/)
- [XDA thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/)



---
#### LATEST CHANGES

**2018.12.4 (201812040)**
- Detach (autorun|service).sh from the parent shell
- Extended modularization for easier maintenance
- Improved legacy systems support
- SDcard mount wait timeout set to 30 minutes to accommodate ROM initial setup and other long operations

**2018.12.3 (201812030)**
- Ability to easily bind-mount and unmount folders not listed in config.txt
- Automatic FUSE/SDcarsFS handling -- users don't have to care about these anymore; fbind will work with whichever is enabled. ESDFS (Motorola's Emulated SDcard Filesystem) will remain unsupported until a user shares their /proc/mounts.
- Fixed loop devices mounting issues; unmounting these with fbind -u is now supported.
- Improved filtering feature (fbind <option(s)> <pattern|pattern2|...>)
- LUKS unmounting and closing (fbind -u <pattern|pattern2|...>)
- Major cosmetic changes
- New log format
- Redesigned fbind utilities -- run <fbind> on terminal or read README.md for details.
- Removed bloatware
- SDcard mount wait timeout set to 10 minutes
- Support for /system install (legacy/Magisk-unsupported devices) and Magisk bleeding edge builds
- Updated building and debugging tools
- Updated documentation -- simplified, more user-friendly, more useful

**2018.11.2 (201811020)**
- Advanced <modPath> detection (more future-proof; trashed hard-coding)
- Always run under <umask 000> to prevent permission issues.
- Fixed <patch_config.sh not working>.
- Universal SDcardFS support (experimental, new algorithms), must be enabled manually with <su -c fbind -s> (toggles SDcardFS mode).

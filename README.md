# fbind


---
## DESCRIPTION

fbind is a versatile mounting utility for folders, disk images, LUKS/LUKS2 encrypted volumes, regular partitions and more.


---
## LICENSE

Copyright (C) 2017-2021, VR25 @ xda-developers

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.


---
## DISCLAIMER

Always read/reread this reference prior to installing/upgrading this software.

While no cats have been harmed, the author assumes no responsibility for anything that might break due to the use/misuse of it.

To prevent fraud, do NOT mirror any link associated with this project; do NOT share flashabe zips! Share official links instead.


---
## WARNING

fbind uses `fsck`, `mount`, `umount` and other low level programs that may cause data corruption/loss.
The author assumes no responsibility under anything that might break due to the use/misuse of this software.
By choosing to use/misuse it, you agree to do so at your own risk!


---
## PRE-REQUISITES

- Android or Android-based OS rooted with [Magisk](https://github.com/topjohnwu/Magisk/)
- [cryptsetup](https://forum.xda-developers.com/showpost.php?p=82561353&postcount=207/) (for encryption, optional)
- Terminal emulator (or adb shell) and/or text editor

Note: executables such as `cryptsetup` can be placed in `/data/adb/vr25/bin/` (with proper permissions) instead of being installed system-wide.


---
## CONFIG SYNTAX

`bind_mount <target> <mount point>` Generic Bind-mount

  e.g., bind_mount $extsd/loop_device/app_data/spotify /data/data/com.spotify.music

---
`extsd_path <path>` Use `path` as extsd.

  e.g., extsd_path /mnt/mmcblk1p2

---
`from_to <source> <dest>` Wrapper for `bind_mount <$extsd/[path]> <$intsd/[path]>`

  e.g., from_to WhatsApp .WhatsApp

---
`int_extf <path>` Bind-mount the entire user 0 (internal) storage to `$extsd/<path>` (implies obb). If `<path>` is not supplied, `.fbind` is used.

  e.g., int_extf .external_storage

---
`intsd_path <path>` Use `path` as `intsd`.

  e.g., intsd_path /storage/emulated/0

---
`loop <disk image> <mount point>` Mount a disk image, a.k.a., loop device.
`fsck -fy` (adaptive) is implied.

  e.g., loop $extsd/loop.img $intsd/loop

---
`noAutoMount` Disable on boot auto-mount.

`obb` Wrapper for `bind_mount $extobb $obb`

---
`obbf <package name>` Wrapper for `bind_mount $extobb/<package name> $obb/<package name>`

  e.g., obbf com.mygame.greatgame

---
`part [-o <mount option...>] <[block device[--L[,password]]]> <mount point> ["fsck <option...>"]` Auto-mount a partition.
The `--L` flag is for LUKS/2 volume, opened manually by running any `fbind` command.
The filesystem is automatically detected.
The defaut mount options are `rw` and `noatime`.
`e2fsck -fy` is always used for supported filesystems.

  e.g.,

    part /dev/block/mmcblk1p1 /mnt/_sdcard

    part -o nodev,noexec,nosuid /dev/block/mmcblk1p1 /mnt/_sdcard

---
`permissive` Set SELinux mode to permissive.

---
`prefix=<path>` Sets emulated storage path prefix (excluding emulated/*).

  e.g., prefix=/mnt/runtime/full

  An alternative to modifying the config is running `prefix=/mnt/runtime/full fbind --remount`

---
`remove <target>`>Auto-remove stubborn/unwanted file/folder from $intsd & $extsd.

  e.g., remove Android/data/com.facebook.orca

---
`target <path>` Wrapper for `bind_mount <$extsd/[path]> <$intsd/[same path]>`

  e.g., target Android/data/com.google.android.youtube


---
## CONFIG EXAMPLES
```
# All OBBs to $extsd/Android/obb/
obb

# Select OBBs to $extsd/Android/obb/
obbf com.somegame.greatgame

# $intsd/target/ to $extsd/sameTarget/
#  For non-media folders only
target TitaniumBackup

# $intsd/someFolder/ to $extsd/.someFolder/
#  Prevents duplicate media
from_to DCIM .fbind/DCIM
from_to Pictures .fbind/Pictures
from_to WhatsApp .fbind/WhatsApp

# Multiuser -- user11/someFolder/ to $extsd/someFolder/
bind_mount $extsd/someFolder ${intsd/%0/11}/someFolder

# Mount a partition and use it as $extsd
part /dev/block/mmcblk1p2 /mnt/p2
extsd_path=/mnt/p2
```


## TERMINAL COMMANDS
```
Usage:
  fbind (wizard)
  fbind [option...] [argument...]

-a|--auto-mount
Toggle auto-mount on boot (default: enabled).

-b|--bind-mount <target> <mount point>
Bind-mount folders not listed in config.txt.
SDcarsFS read and write runtime paths are handled automatically.
Missing directories are created accordingly.
e.g., fbind -b /data/someFolder /data/mountHere

-c|--config [editor] [option...]
Open config.txt w/ [editor] [option...] (default: vim|vi|nano).
e.g., fbind -c nano -l

-C|--cryptsetup [option...] [argument...]
Run cryptsetup [option...] [argument...].

-f|--fuse
Toggle FUSE usage for emulated storage (default: off).

-h|--help
List all commands.

-l|--log [editor] [option...]
Open service.log w/ [editor] [option...] (default: more|vim|vi|nano).
e.g., fbind -l

-m|--mount [egrep regex]
Bind-mount matched or all (no arg).
e.g., fbind -m "Whats|Downl|part"

-M|--move [ext. regex]
Move matched or all (no args) to external storage.
Only unmounted folders are affected.
e.g., fbind -M "Download|obb"

-Mm [egrep regex]
Same as "fbind -M [arg] && fbind -m [arg]"
e.g., fbind -Mm

-r|--readme
Open README.md w/ [editor] [option...] (default: more|vim|vi|nano).

-R|--remove [target]
Remove stubborn/unwanted file/folder from \$intsd and \$extsd.
By default, all "remove" lines from config are included.
e.g., fbind -R Android/data/com.facebook.orca

-u|--unmount [mount point or egrep regex]
Unmount matched or all (no arg).
This works for regular bind-mounts, SDcardFS bind-mounts, regular partitions, loop devices and LUKS/LUKS2 encrypted volumes.
Unmounting "all at once" (no arg) does not affect partitions nor loop devices.
These must be unmounted with a regex argument.
For unmounting folders bound with the --bind-mount option, the mount points must be supplied, since those are not in config.txt.
e.g., fbind -u "loop|part|Downl"

-um|--remount [egrep regex]
Remount matched or all (no arg).
e.g., fbind -um "Download|obb"
```

---
## NOTES

- Recent Magisk versions disable all modules when the system boots in safe mode.
Keep this in mind, just in case you face a bootloop - although, in most cases, fbind will automatically revert problematic changes.

- If you find terminal overwhelming, just run `fbind` and follow the wizard.

- Always enforce Unix line endings (LF) when editing config.txt.
NEVER use Windows Notepad for that!

- Available free space in internal storage may be misreported.

- [Some] file managers may show multiple SDcard/storage locations.

- [FUSE] Some users may need to set `intsd_path /storage/emulated/0` (default is /data/media/0).

- If you stumble upon inaccessible folders or read-only access, try forcing FUSE (fbind -f) usage for emulated storage.
If your system does not support FUSE, it may get into a bootloop.
If that happens, fbind will revert the change automatically on the next boot attempt.
To revert it manually, either run `fbind -f` again or remove `/data/adb/modules/fbind/system.prop` to `FUSE.prop` and remove `/data/adb/vr25/fbind-data/.FUSE`.

- Logs are stored at `/data/adb/vr25/fbind-data/logs/`.

- [SDcardFS] Remounting /mnt/runtime/write/... may cause a system reboot.
When this happens, fbind learns to skip it.
However, if the system reboots for a reason other than this, fbind will mistakenly create `/data/adb/vr25/fbind-data/.noWriteRemount`.
If you stumble across broken bind mounts, remove that file and remount all folders.
To do that in one shot, run `rm /data/adb/vr25/fbind-data/.noWriteRemount; fbind -um`.

- Rebooting is not required after installing/upgrading.
If`/sbin` is missing (many Android 11 based systems lack it), use the `/dev/.vr25/fbind/fbind` executable until you reboot - e.g., `/dev/.vr25/fbind/fbind -m`.


---
## LINKS

- [Airtm, username: ivandro863auzqg](https://app.airtm.com/send-or-request/send)
- [Facebook page](https://fb.me/vr25xda/)
- [Git repository](https://github.com/vr-25/fbind/)
- [Liberapay](https://liberapay.com/vr25/)
- [Patreon](https://patreon.com/vr25/)
- [PayPal](https://paypal.me/vr25xda/)
- [Telegram channel](https://t.me/vr25_xda/)
- [Telegram profile](https://t.me/vr25xda/)
- [Telegram group](https://t.me/fbind_group/)
- [XDA thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/)


---
## LATEST CHANGES

**v2021.3.4 (202103040)**
- Better logs
- Cryptsetup is no longer bundled, but it's still supported. Download link and very simple installation instructions are provided.
- Enhanced wizard.
- fbind --move shows progress.
- Fixed auto-mount
- Fixed unmount issues
- For now, Magisk is a strict requirement.
- Other major fixes & optimizations
- Rebooting is not required after installing/upgrading.
If`/sbin` is missing (many Android 11 based systems lack it), use the `/dev/.vr25/fbind/fbind` executable until you reboot - e.g., `/dev/.vr25/fbind/fbind -m`.
- Simplified down to the core to minimize overheard, compatibility and ease maintenance.
- The order of default text editors is now vim|vi|nano.
- Updated documentation

**v2021.11.11-beta (202111110)**
- Experimental support for recent Android versions
- General fixes
- Major optimizations

**v2021.11.13-beta (202111130)**
- Ability to specify the emulated storage path prefix to use (details in readme > config syntax)
- Android 11 testing kit in the flashable zip
- General enhancements

**v2021.11.14-beta (202111140)**
- `bindfs` binaries (ARM, ARM64, X86 and X86_64) are included and prioritized over `mount -o bind`
- Fixed `umount` issues
- General enhancements
- Updated flashable zip generator

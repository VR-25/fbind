# Magic Folder Binder (fbind)     
# VR25 @ XDA Developers

***
**DESCRIPTION**
- Forces Android to save select files/folders to the external_sd (or alternate partition) by default, & clean up the user's storage (select unwanted, stubborn files/folders) automatically.


***
**DISCLAIMER**
- ALWAYS read the reference prior to installing/updating fbind. While no cats have been harmed in any way, shape or form, I assume no responsibility under anything that might go wrong due to the use/misuse of this module. 


***
**QUICK SETUP**
1. Install the module.
2. Reboot.
3. Read `Config Syntax` below &/or /data/_fbind/info/config_samples.txt.
4. Setup /data/_fbind/config.txt.
5. Run `fbind -mb` as root to move data & bind corresponding folders automatically.
6. Forget.


***
**CONFIG SYNTAX
 
**Function + Parameter(s)**
- altpart [block device] [mount point] [filesystem] ["fsck OPTION(s)" (filesystem dependent, optional)] --> auto-mount alternate partition & use it as extsd
- app_data [folder] --> data/data <--> extsd/.data (needs altpart or LinuxFS formated SD card), to use with intsd instead, include the config line "extsd_path $intsd"
- bind_mnt [TARGET mount_point] --> same as "mount -o bind [TARGET mount_point]"
- cleanup [file/folder] --> auto-remove unwanted files/folders from intsd & extsd -- including by default, unwanted "Android" directories
- cryptsetup=true --> disable Auto-bind service (necessary for opening a LUKS volume)
- extsd_path [path] (i.e., /mnt/media_rw/NAME) --> ignore for default -- /mnt/media_rw/XXXX-XXXX, if extsd path is null/unspecified ("extsd_path" with nothing in front), fbind will auto detect it
- from_to [intsd folder] [extsd folder] --> great for media folders & extra organization
- intobb_path [path] --> i.e., /storage/emulated/0 (ignore for default -- /data/media/0)
- intsd_f --> intsd to extsd/.fbind (includes obb)
- intsd_path [path] --> i.e., /storage/emulated/0/Android/obb (ignore for default -- /data/media/obb)
- obb --> entire obb
- obbf [app/game folder] --> individual obb
- perms --> "pm grant" storage permissions to all apps (including future installations), use only if the default method (platform.xml patch) doesn't work for you
- target [target folder] --> great for standard paths (i.e., Android/data, TWRP/BACKUPS)

An additional argument (any string) to any of the binding functions above excludes additional Android folders from being deleted. For bind_mnt(), if the additional argument is `-mv`, then fbind -m will obey that line too -- which is otherwise ignored by default for safety concerns.

- You can add user variables to the config file. These must be in the format `u# or u##` -- i.e., u9=/data/media/9, u11=YouGetThePoint.

- You can add `fsck -OPTION(s) /path/to/partition` (i.e., `fsck.f2fs -f /dev/block/mmcblk1`). This will check for/fix SD card errors before system gets a chance to mount it.


***
**DEBUGGING**

* Logfile --> /data/_fbind/debug.log

* Most likely, you don't need this
- Permissive_SELinux -- sets SElinux mode to `permissive`.
- Permissive_SELinux -bind_only -- sets SELinux mode to `permissive` before binding folders and back to `enforcing` afterwards.

* Default internal storage paths (auto-configured)
- intsd_path /data/media/0
- intobb_path /data/media/obb

* Alternate internal storage paths
- intsd_path /storage/emulated/0
- intobb_path /storage/emulated/obb

* Bind issues
- Try the `alternate internal storage paths` above.
- Change `Namespace Mode` in Magisk Manager settings.

* If you suspect fbind causes a bootloop, try excluding `system/xbin` from installation, by running `touch /data/_x`.


***
**Online Support**
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/page2post72688621)
- [GitHub Repo](https://github.com/Magisk-Modules-Repo/Magic-Folder-Binder)

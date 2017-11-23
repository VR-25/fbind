# Magic Folder Binder (fbind)     
# VR25 @ XDA Developers


***
**DESCRIPTION**
- Forces Android to save select files/folders to the external_sd (or to a partition) by default, & clean up the user's storage (select unwanted files/folders) automatically.


***
**DISCLAIMER**
- ALWAYS read the reference prior to installing/updating fbind. While no cats have been harmed in any way, shape or form, I assume no responsibility under anything that might go wrong due to the use/misuse of this module. 


***
**QUICK SETUP**
1. Install the module.
2. Reboot.
3. Read `Config Syntax` below &/or /data/media/fbind/info/config_samples.txt.
4. Setup /data/media/fbind/config.txt.
5. Run `fbind -mb` as root to move data & bind corresponding folders automatically.
6. Forget.


***
**CONFIG SYNTAX**

- part [block device] [mount point (any path except "/folder"] [file_system] ["fsck OPTION(s)" (filesystem specific, optional) --> auto-mount a partition & use it as extsd
- app_data [folder] --> data/data <--> extsd/.data (needs part or LinuxFS formated SD card), to use with intsd instead, include the config line "extsd_path $intsd"
- bind_mnt [TARGET mount_point] --> same as "mount -o bind [TARGET mount_point]"
- cleanup [file/folder] --> auto-remove unwanted files/folders from intsd & extsd -- including by default, unwanted "Android" directories
- luks --> disable auto-bind service to open a LUKS volume -- handled by part() 
- extsd_path [/path/to/alternate/storage]) --> ignore for default -- /mnt/media_rw/*, include the line `extsd_path $intsd` in your config file if your device hasn't or doesn't support SD card
- from_to [intsd folder] [extsd folder] --> great for media folders & extra organization
- intobb_path [path] --> i.e., /storage/emulated/0 (ignore for default -- /data/media/0)
- intsd_f --> intsd to extsd/.fbind (includes obb)
- intsd_path [path] --> i.e., /storage/emulated/0/Android/obb (ignore for default -- /data/media/obb)
- obb --> entire obb
- obbf [app/game folder] --> individual obb
- perms --> "pm grant" storage permissions to all apps (including future installations)
- target [target folder] --> great for standard paths (i.e., Android/data, TWRP/BACKUPS)
- no_restore --> don't auto-restore config backup
- no_bkp --> don't backup config & don't auto-restore

An additional argument (any string) to any of the binding functions above excludes additional Android folders from being deleted. For bind_mnt(), if the additional argument is `-mv`, then fbind -m will obey that line too -- which is otherwise ignored by default for safety concerns. For app_data, "-u" allows fbind -u to "see" the specified line (also otherwise ignored by default).

You can add user variables to the config file. These must be in the format `u# or u##` -- i.e., u9=/data/media/9, u11=YouGetThePoint.

You can add `fsck -OPTION(s) /path/to/partition` (i.e., `fsck.f2fs -f /dev/block/mmcblk1`). This will check for/fix SD card errors before system gets a chance to mount it.


***
**fbind Terminal Toolkit**

Usage: fbind OPTION(s) ARGUMENT(s)

-a --> Add line(s) to config.txt (interactive)
-b --> Bind all
-c --> Storage cleanup
-d --> Disable autobind service
-e --> Re-enable autobind service
-f --> Disable this toolkit
-l --> Show config.txt
-m --> Move data to the sdcard
-r --> Remove lines(s) from config.txt (interactive)
-u --> Unbind everything
-x --> Disable the module
-mb --> Move data, bind folders
ref --> Show README
log --> Show debug.log
chlog --> Show changelog

-ad --> Add "app_data" line(s) to config.txt (interactive)

-as --> Ask for SOURCE dirs (intsd/SOURCE) & add corresponding "from_to" lines to config.txt (interactive)

-umb --> Unbind all, move data, rebind (CAUTION!)

restore --> Move select data back to original locations (interactive)

rollback --> Unbind all, uninstall fbind & restore files

uninstall --> Unbind all & uninstall fbind

(i) The "-m" option affects unmounted folders only. Caution: it replaces destination data!

(!) Warning: only use "fbind -umb" if you know exactly what you're doing! That option is only intended for first time use -- i.e., in case you forgot to move data after installing the module for the very first time and rebooted. Since "-m" only moves unmounted folders data, the "-u" option makes it work. Again, once everything is unmounted, "-m" will then replace destination data. "fbind -mb" is the safer alternative, since it only moves new data. Let's say you just added a few lines to your config.txt file and the corresponding folders are not bound & data was not moved yet -- that's when you use this.


***
**DEBUGGING**

* Logfile --> /data/media/fbind/debug.log

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

* If you suspect fbind causes a bootloop, try excluding `system/xbin` from installation, by running `touch /data/_x`.


***
**Online Support**
- [Git Repository](https://github.com/Magisk-Modules-Repo/Magic-Folder-Binder)
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/page2post72688621)

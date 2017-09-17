# Magic Folder Binder (fbind)                                           # VR25 @ XDA Developers              
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
3. Read "Config Syntax" below & $intsd/_fbind/info/config_example.txt.
4. Setup $intsd/_fbind/config.txt.
5. Run "fbind -mb" as root to move data & bind corresponding folders automatically.
6. Forget.


***
**CONFIG SYNTAX
 
**Function + Parameter(s)**
- altpart [block device] [mount point] [filesystem] ["fsck OPTION(s)" (filesystem dependent, optional)] --> auto-mount alternate partition & use it as extsd
- app_data [folder] --> data/data <--> $extsd/.data (needs altpart or LinuxFS formated SD card)
- bind_mnt [target mount_point] --> same as "mount -o bind [target mount_point]"
- cleanup [file/folder] --> auto-remove unwanted files/folders from intsd & extsd -- including by default, unwanted "Android" directories
- cryptsetup=true --> disable Auto-bind service (necessary for opening a LUKS volume)
- extsd_path [path] (i.e., /mnt/media_rw/NAME) --> ignore for default -- /mnt/media_rw/XXXX-XXXX
- from_to [$intsd folder] [$extsd folder] --> great for media folders & extra organization
- intobb_path [path] --> i.e., /storage/emulated/0 (ignore for default -- /data/media/0)
- intsd_path [path] --> i.e., /storage/emulated/0/Android/obb (ignore for default -- /data/media/obb)
- obb --> entire obb
- obbf [app/game folder] --> individual obb
- perm [package_name(s)] --> grant full storage access permission to specified package(s) (WIP)
- target [target folder] --> great for standard paths (i.e., Android/data, TWRP/BACKUPS)


***
**DEBUGGING**

* Logfile --> $intsd/_fbind/debug.log

* Most likely, you don't need this
- Permissive_SELinux -- sets SElinux mode to "permissive" (case sensitive).
- Permissive_SELinux -bind_only -- sets SELinux mode to "permissive" before binding folders and back to "enforcing" afterwards (case sensitive).

* Default internal storage paths (auto-configured)
- intsd_path /data/media/0
- intobb_path /data/media/obb

* Alternate internal storage paths
- intsd_path /storage/emulated/0
- intobb_path /storage/emulated/0/Android/obb

* Bind issues
- Make sure you have busybox or similar binary (i.e., toybox) installed.
- Try the alternate internal storage paths above.
- Change "Namespace Mode" in Magisk Manager settings.
- Google "Marshmallow SD Fix."

* If the module causes a bootloop, try excluding system/xbin from installation, by running "touch /data/_x".


***
**Online Support**
- [XDA Thread](https://forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/page2post72688621)
- [GitHub Repo](https://github.com/Magisk-Modules-Repo/Magic-Folder-Binder)
**2018.1.13 (201801130)**
- General optimizations
- Updated reference

**2018.1.10 (201801100)**
- General bug fixes & optimizations
- Quoted paths containing spaces are now handled as expected
- Removed storage permissions fixes -- will come back only if a new implementation (WIP) ends up being fully functional and universal
- Redesigned `-as` command line option

**2018.1.7 (201801070)**
- Enhanced platform.xml patching engine & "perms" feature
- [EXPERIMENTAL] Ability to mount multiple partitions, loop devices (.img files) & open multiple LUKS volumes
- Fixed extsd_path() "slee" typo, "sestatus not found" & other issues
- Improved compatibility with older Magisk versions (entirely new installer)
- Major optimizations
- Updated documentation (pro tips included)

**2018.1.2 (201801020)**
- Added wildcards support to `fbind -as`
- Automatically restore config backup upon installation if current config is missing or empty
- Automatically set/reset `Mount Namespace Mode` to Global
- Backwards compatible with Magisk versions older than 15, suporting template v4+
- Fixed a critical bug that caused absurd delays in the folder binding process
- Major optimizations
- Major reference updates, especially config_samples.txt -- definitely worth checking that out
- Smart SELinux mode handling -- "if enforcing; then set to permissive; do fbind stuff; set back to enforcing; fi" ;)
- [TEST] New storage permissions workaround

**2017.12.4 (201712040)**
- [xbin/fbind] rename "cryptsetup=true" --> "luks"
- [xbin/fbind] rename "magisk/fbind" leftovers to "$ModPath"

**2017.12.3 (201712030)**
- Better & wider compatibility -- from Magisk 12 all the way to 14.5, possibly previous and future versions too
- Fixed wrong "luks" config switch
- Improved "hot fsck" switch mechanism
- General optimizations

**2017.11.24 (201711240)**
- Fixed wrong extsd path
- Updated reference

**2017.11.23 (201711230)**
- Ability to disable config auto-backup and/or restore (config switches: `no_bkp`, `no_restore`)
- General optimizations
- Isolated cryptsetup binary
- Renamed "cryptsetup=true" to "luks"
- Updated reference

**2017.11.9 (201711090)**
- Auto-set Mount Namespace to Global.
- Migrate /data/_fbind --> /data/media/fbind -- to persist across factory resets.

**2017.10.21 (201710210)**
- Fixed fbind chlog & ref options.
- General optimizations

**v2017.10.12 (201710120)**
- "altpart" function renamed to "part"
- Updated reference
- General optimizations

**v2017.10.11 (201710110)**
- Removed Platform.xml patcher leftovers.
- Misc optimizations

**v2017.10.10-2 (201710102)**
- Auto-restore config backup if config file is empty.
- Don't backup config if it's empty.

**v2017.10.10-1 (201710101)**
- Enable extsd_path() alt_extsd flag when "$1" = "$intsd".
- rm /data/_fbind on rollback.
- Disabled post-fs-data.sh (platform.xml patching -- unsuccessful).
- New versionCode format YYYYMMDD[0-9]

**v2017.10.1 (201710010)**
* Bug fixes & optimizations

**v2017.9.30 (201709300)**
* Fixed
-- App data move
-- Bind issues
* Updated fbind terminal toolkit
-- Batch operations
--- fbind -ad --> add "app_data" lines to config.txt (interactive)
--- fbind -as --> ask for SOURCE dirs (intsd/SOURCE) & add corresponding "from_to" lines to config.txt (interactive)
--- fbind restore --> move select data back to original locations (interactive)	

**v2017.9.27.3 (201709273)**
- Fixed SD card detection mechanism.

**v2017.9.27.2 (201709272)**
- Default SD card search path is no longer limited to "/mnt/media_rw/XXXX-XXXX". So, setting "extsd_path PATH" is no longer necessary if the path to the storage device starts with "/mnt/media_rw".
- Updated reference

**v2017.9.27.1 (201709271)**
- Fixed bind-mount app_data to intsd.
- Now, if extsd path is null/unspecified ("extsd_path" with nothing in front), fbind will auto detect it.

**v2017.9.27 (201709270)**
- Fixed from_to bind error.
- You can now add `fsck -OPTION(s) /path/to/partition` to your config file (i.e., `fsck.f2fs -f /dev/block/mmcblk1`). This will check for/fix SD card errors before system gets a chance to mount it.
- Updated reference.

**v2017.9.26 (201709260)**
- Those facing bind issues, please double check your config file for errors...
**-- there's a small chance config_updater.sh might have messed with it a bit during 201709160 build update.**
- Updated reference (please READ/RE-READ config_samples.txt & README.txt).
- Added critical flag -- bind_mnt, mv only if $3 = "-mv".
- Added ability to unmount (fbind -u) /data/data/app -- flag -u -- i.e., app_data com.spotify.music -u).
- app_data() works with internal storage too -- reduce the size of TWRP backups by saving huge app data to $intsd/.app_data.
-- The line "extsd_path $intsd" must be present in your config file.
- fbind -u affects bind_mnt() as well.
- Rearranged $PATH elements to avoid/fix busybox issues.
- int_extf() is back.
- MASSIVE optimizations
- Auto-grant storage permissions to ALL apps by default (platform.xml patch & auto-re-patch across ROM updates).
-- Alternate method uses "pm grant" -- add the line "perms" to your config file if the above method doesn't work.
--- This one might take a while to complete (first time only)

**v2017.9.18.1 (201709181)**
- Fixed bind_mnt()
- Fixed fbind cmd
- Updated reference

**v2017.9.18 (201709180)**
- [TEST] auto-add storage access permissions to /data/system/packages.xml -- perm pkg_name
- Ability to move bind_mnt() data (fbind -m) when a 3rd argument is present (i.e., "bind_mnt data/FOLDER $intsd/FOLDER X")
- User variables
- No longer bind-mounting /data/_fbind to $intsd/_fbind.
- Minor optimizations
- Updated reference

**v2017.9.16 (201709160)**
- "from_to -e" replaced by "bind_mnt". The latter follows the standard "mount -o bind" syntax.

**v2017.9.15 (201709150)**
- Ability to fully replace insd with extsd.
- Massive redesigns & optimizations
- Marshmallow storage access permissions fix -- perm() (WIP)

**v2017.9.14 (201709140)**
- Fixed wrong 'from_to -e' log
- Better altpart() disk usage log
- Minor optimizations

**v2017.9.12 (201709120)**
- Reverted cleanup() array implementation due to "space" bug.
- Updated reference.
- Enhanced config auto-backup.

**v2017.9.11 (201709110)**
- Enhanced cleanup function.
- Ability to add "Android" folders cleanup exceptions -- by passing an extra non-null argument to a binding function (i.e., target FOLDER X, from_to SOURCE DEST X; applies to all binding functions; "X" can be any string).
- Now using Magisk's internal busybox for all operations.
- Fixed cyptsetup binary errors.
- Updated reference.
- Under-the-hood optimizations

**v2017.9.10 (201709100)**
- Fixed potential bind failure.
- Module template updated to v1400.
- Added features -- auto-recreate & auto-backup config file.
- Cosmetic enhancements

**v2017.9.9 (20170990)**
- Massive overall optimizations
- Fixed permission issues when creating folders in extsd_path (not altpart) with Linux filesystem.
- Optimized "move_data" function.
- Fixed update binary errors (actually, these weren't errors at all, but fully working code misleadingly reported by Magisk v13.6+ as "bad").
- Fully implemented fbind -dd & -r options. Run "fbind" for info on what these do.
- Array style cleanup function
- Non-existing intsd folders are now created automatically as well (very helpful across internal storage wipes -- assuming a config.txt backup exists).

**v2017.9.5**
- Fixed bad versionCode. Magisk Manager won't report this version as an update.
- Fixed "kill -b --> from_to -e" cleanup extension.
- Properly implemented cryptsetup.
- Updated install script.
- Cosmetic & sanitary enhancements

**v2017.8.30**
- fbind -rollback is now able to restore /data/data/* as well (safely).
- app_data() can now work without an alternate partition (usually /dev/block/mmcblkp2), assuming /dev/block/mmcblkp1 has a Linux filesystem (i.e., ext2,3,4, f2fs) & extsd_path() is in use (obviously).
- Added "from_to -e" (extended from_to) -- yes, it does exactly what the name suggests. Check README &/or config_example.txt for more info.
- "kill -b" also cleans up "from_to -e" folders. At the end, it "sources" an optional cleanup script ($intsd/fbind/cleanup.sh).
- Interactive fbind -a (add line(s)) WIP --> -dd (add app_data line(s)) & -r (remove line(s)
- Added "cryptsetup" (LUKS) support (WIP).

**v2017.8.26.1**
- Added kill -b -- auto-remove nasty [Android] subdirs from extsd bound folders. No args needed. More efficient, performance & resources-wise than kill -r/ir/xr.
- Added fbind -c -- run cleanup()
- Updated reference

**v2017.8.26**
- More optimizations
- Redesigned kill() -- additional features (find_rm) & more compact/intuitive (check REDME's "Config Syntax" section)
- Enhanced "update_prep.sh" to be more widely compatible with older module versions.
- Updated reference (README.txt & config_example.txt)

**v2017.8.24**
- Massive optimizations
- Parameterized app_data() to bind individual app data (safer).
- Added ability to "copy -a" /data/data/$1 to $extsd/.data from terminal (fbind -m).
- Added app_data() Cleanup Extension (post-fs-data.sh) to safely rm "/data/data/$1/*".
- Updated wait_emulated() for altpart().
- Better log & fbind toolkit output
- Updated reference

**v2017.8.23**
- Redesigned for easier maintenance. $MODPATH/service.sh & $MODPATH/system/xbin/fbind now use/"source" a common, standalone core, which contains all the functions required for the module to work.
- Major optimizations
- Enhanced debugging tools.
- [TEST-FIX] auto-mount alternate partition --> altpart() $1=block_device, $2=mount_point $3=file_system, $4="fsck OPTION(s)" (filesystem dependent, optional).
- Ability to specify an alternate extsd_path [PATH] (i.e., /mnt/media_rw/NAME) --> for path other than the standard /mnt/media_rw/XXXX-XXXX. SD cards with filesystems other than "fat32" or "exfat" generally have longer names.
- Updated reference.
- Added options to see the README and changelog on terminal (fbind -ref & -chlog).
- Not a change, but please... ALWAYS read the reference (README.txt & config_example.txt) before installing/updating. Not answering dumb questions anymore.

**v2017.8.18.2**
- [TEST-FIX] block device detection (alternate partition)

**v2017.8.18.1**
- Major optimizations
- Faster bind engine
- Bug fixes

**v2017.8.18**
- Fixed "intobb path" typo
- [EXPERIMENTAL] Added "data_data" function to bind /data/data to $extsd/.data (ext2,3,4 partition only)
- [TEST-FIX] Wait for alternate partition to show up in /dev/block before attempting to auto-mount it to $extsd_path
- Auto "e2fsck -fy" alternate partition
- Check README for more info

**v2017.8.16**
- Massive optimizations
- [TEST] Added option to auto-mount an alternate partition (ext2,3,4 only) to "$extsd_path." Check README.
- Updated reference.
- Now you can exclude fbind command line tool from installation by running "touch /data/_f". This is for those who want just the core functionality of the module. On the other hand, it may prevent bootloop in problematic, security freak systems.

**v2017.8.15-1**
- Minor optimizations
- Code cleanup

**v2017.8.15**
- Added support for alternate sdcard path (i.e., /data/extsd2). Check README.txt for more info.
- Minor optimizations

**v2017.8.14**
- Added "autokill stubborn files" (in addition to the "autokill stubborn folders" feature). Check README.txt for more info.
- Major optimizations
- Improved debugging support. Check README.txt for more info.

**v2017.8.5**
- Updated installer, engine, documentation and filenames under $intsd/fbind
- [TEST-bootloop-fix-Samsung] fbind moved from bin dir to xbin

**v2017.7.29**
- Updated documentation
- Now available for download from Magisk Manager

**v2017.7.25**
- Massive optimizations
- fbind_setup.txt is now located in /data/media/0/fbind along with other fbind files for better organization.
- Submitted to the official Magisk modules repo -- awaiting approval.

**v2017.7.24**
- Fixed TWRP installation error
- Major optimizations for easier template migration and faster updates.
- Updated reference (fixed typos, replaced obsolete names).
- Cosmetic changes (I love these!) ;)

**v2017.7.21**
- Updated to Magisk module template v4
- 
**v2017.7.21-Magisk-v12 is also available, but will no longer be updated if the latest Magisk has no major issues.**
- Major optimizations.
- Updated reference. 
- Minor cosmetic changes

**v2017.7.7**
- Fixed a couple of fbind stupid bugs. I need to re-evaluate my logical thinking. :p
- Some major optimizations
- Minor cosmetic changes

**v2017.7.4**
- Fixed MODPATH error in fbind command line tool

**v2017.7.3**
- Under the hood optimizations
- README.md file is now copied to /sdcard as "fbind_reference.txt." This allows fbind_setup.txt to lose some extra fat ;)

**v2017.7.2**
- Fixed a very misleading typo in fbind help function.
- Minor code optimizations.

**v2017.7.1**
- Added storage sanitizer function to automatically remove stubborn folders from the internal storage and sdcard. For more details, check the fbind_setup.txt.
- The binding engine is even faster.
- fbind will now help keep your device from overheating, thanks to its new folder cooling feature.

**v2017.6.30-1**
- Fixed "fbind -mb" and "-b" not working properly.
- Under the hood improvements/optimizations.

**v2017.6.30**
- The function "sdcard," built to "replace" the entire internal storage, now binds it to [$sdcard/.fbind] to avoid duplicates. Previously, the internal storage was bound to the root of the sdcard, causing a duplicated media nightmare. When you enable this function, fbind.log & fbind_setup.txt are moved to /data/.fbind for obvious reasons. Lastly, this may or may not work well with obb (WIP).
- Fixed "some folders are not created automatically" issue.
- Fixed "fbind -a LINE" not adding line to fbind_setup.txt when the user inputs a parameter-less function, such as "sdcard" or "obb."
- Improved log engine to display additional SD card information, including sdcardfs status. This helps a lot in debugging.
- Removed Termux terminal emulator app (force closes). You can always manually install it or any other terminal emulator app you like.
- New command: "fbind -log" -- displays the content of fbind.log on terminal emulator.
- Some cosmetic touches here and there

**v2017.6.29**
- More debugging support (check fbind_setup.txt)
- New features/commands -- uninstall (removes the module), rollback (removes the module & moves files back to the internal storage), disable fbind command line tool (i.e., in case it trips SafetyNet) and disable module (the same you would otherwise do from Magisk Manager). Check post #3 for more info.

**v2017.6.27**
- Improved documentation and debugging tools
- Minor code analysis and optimizations

**v2017.6.26**
- Massive code optimizations
- New fbind_setup.txt template gives you the ability to specify your internal storage and obb paths.
- From now on, whenever there is a new fbind_setup.txt template, the installer will copy your current setup to it automatically instead of just replacing your list.
- fbind terminal emulator tool has new features, including support for multiple operations at once. Check post #3 or simply run the command without arguments to open the help function.
- "Termux terminal emulator & linux environment" updated

**v2017.6.25-1**
- Fixed syntax error when binding folders with space(s).
- Automatic newline checking/addition at the end of fbind_setup.txt (necessary for "fbind -a LINE" to work).

**v2017.6.25**
- Merged fbind_bind, fbind_move and fbind_unbind scripts into one -- fbind. That all-in-one script allows you to bind-all, unbind-all, move-all and manage your fbind_setup.txt from terminal emulator! Usage is very straightforward -- just run fbind without arguments to open the help function and follow the instructions.

**v2017.6.23**
- Fixed log not being cleared out across reboots. After some time, this would fill up the internal storage.
- Added scripts "fbind_bind" (to bind all manually) and "fbind_unbind" (to release all manually) in addition to "fbind_move" to guive you more controls and improve automation (we all like easier lives).

**v2017.6.22-2**
- Previous fix, 2nd attempt

**v2017.6.22-1**
- Fixed "sdcardfs force off" prop not being set on Samsung GS8 -- dear Sammy, please, stop doing too much of non-standard things! :)

**v2017.6.22**
- Fixed "resetprop" issue preventing sdcardfs from being disabled. It was being called too early. That is before it was available in /sbin. In order to more conveniently support newer versions of Magisk (with the unified binary), I decided to use "setprop" over "resetprop." I found no difference in the way they work in this particular case -- "persist" type props are stored in /data/property either way, which means they are persistent accross reboots.
- Code optimizations
- [TEST-fix] double sd card showing up in file explorer (Galaxy S8+). This may interfere with obb binding. Please, test and report back.

**v2017.6.21-2**
- Fixed Termux installation error
- Fixed sdcardfs prop issue (previous attempt didn't take care of it)

**v2017.6.21-1**
- Don't set "disable sdcardfs" prop on devices it doesn't apply to (for the sake of cleanliness and to avoid that OCD behavior) ;)
- Code cleanup

**v2017.6.21**
- Removed built-in busybox
- Disabled sdcardfs, as it was found to be behind the binding issues on some devices, such as SGS8+ and HTC 10. Big thanks to Captain_Throwback for helping me solve the puzzle

**v2017.6.20.1**
- Possible bootloop fix for devices getting stuck after installing 
**v2017.6.20**
- Auto-fix fbind_setup.txt permissions on install/update (used to go out of wack in some cases)

**v2017.6.20**
- Code optimizations
- Fixed data/app/Termux.apk permissions
- Auto-fix /data/media/0/fbind.log permissions 
- Built-in busybox

**v2017.6.19-2**
- Fixed fbind_move error.

**v2017.6.19-1**
- SELinux permissive mode enabled by default (manage that setting in fbind_setup.txt).
- Termux.apk moved from $MODPATH/system/priv-app to data/app to avoid tripping SafetyNet
- Since fbind_setup.txt was updated, you current list will be renamed to previous_fbind_setup.txt. Simply copy-paste your setup over to the new template.

**v2017.6.19**
- Includes all fixes from previous versions plus SELinux workaround for those who cannot bind folders.
- OBB additions for Samsung devices (please, let me know whether obb binds properly now).

**v2017.6.18**
- Greatest upgrade so far!
- List syntax changed from "easy" to "absurdly easy." See for yourself!
- Optimized engine.
- Target folders are now created automatically.
- You still have to move your files manually though, for the sake of performance and safety.
- Running that automatically on boot would delay the binding process SIGNIFICANTLY. I'm sure I don't need to say why that's a big no no.
- However, sit down and relax. I got you covered on this one too! ;)
- Simply run fbind_move as root in terminal emulator and let it do its magic. Your setup will be read from fbind_setup.txt and files will be moved to the target folders accordingly.
- That's it!

**v2017.6.16**
- Another complete redesign
- Rebooting twice is no longer needed to apply changes
- Automatic SD card detection timeout (no more additional module variants to choose from)
- Faster folder binding
- Fix fbind_setup.txt permissions automatically

**v2017.6.14**
- Complete redesign
- Initial release

**v2017.6.13**
- Initial version

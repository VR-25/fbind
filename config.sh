##########################################################################################
#
# Magisk Module Template Config Script
# by topjohnwu
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure the settings in this file (config.sh)
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Configs
##########################################################################################

# Set to true if you need to enable Magic Mount
# Most mods would like it to be enabled
AUTOMOUNT=true

# Set to true if you need to load system.prop
PROPFILE=true

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Installation Message
##########################################################################################

# Set what you want to show when installing your mod

print_modname() {
  ui_print " "
  ui_print "$(i name) $(i version)"
  ui_print "$(i author)"
  ui_print " "
}

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info about how Magic Mount works, and why you need this

# This is an example
REPLACE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here, it will override the example above
# !DO NOT! remove this if you don't need to replace anything, leave it empty as it is now
REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################

set_permissions() {
  # Only some special files require specific permissions
  # The default permissions should be good enough for most cases

  # Here are some examples for the set_perm functions:

  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm_recursive  $MODPATH/system/lib       0       0       0755            0644

  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm  $MODPATH/system/bin/app_process32   0       2000    0755         u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0       2000    0755         u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0       0       0644

  # The following is default permissions, DO NOT remove
  set_perm_recursive  $MODPATH  0  0  0755  0644

  # Permissions for executables
  for f in $MODPATH/bin/* $MODPATH/system/bin/* \
    $MODPATH/system/xbin/* $MODPATH/*.sh
  do
    [ -f "$f" ] && set_perm $f 0 0 0755
  done
  set_perm $MOUNTPATH0/.core/service.d/fbind.sh 0 0 0755
}

##########################################################################################
# Custom Functions
##########################################################################################

# This file (config.sh) will be sourced by the main flash script after util_functions.sh
# If you need custom logic, please add them here as functions, and call these functions in
# update-binary. Refrain from adding code directly into update-binary, as it will make it
# difficult for you to migrate your modules to newer template versions.
# Make update-binary as clean as possible, try to only do function calls in it.


install_module() {

  # shell behavior
  set -euxo pipefail
  trap debug_exit EXIT

  # get CPU arch
  case "$ARCH" in
    *86*) local binArch=x86;;
    *ar*) local binArch=arm;;
    *) ui_print " "
       ui_print "(!) Unsupported CPU architecture ($ARCH)!"
       ui_print " "
       exit 1;;
  esac

  local binary=""
  local modData=/data/media/$MODID
  config=$modData/config.txt

  # magisk.img mount path
  $BOOTMODE && MOUNTPATH0=$(sed -n 's/^.*MOUNTPATH=//p' $MAGISKBIN/util_functions.sh | head -n 1) \
    || MOUNTPATH0=$MOUNTPATH

  curVer=$(grep_prop versionCode $MOUNTPATH0/$MODID/module.prop || true)
  [ -z "$curVer" ] && curVer=0

  # create module paths
  rm -rf $MODPATH 2>/dev/null || true
  mkdir -p $MODPATH/bin $modData/info $MOUNTPATH0/.core/service.d
  [ -d /system/xbin ] && mkdir -p $MODPATH/system/xbin \
    || mkdir -p $MODPATH/system/bin

  # extract module files
  ui_print "- Extracting module files"
  cd $INSTALLER
  unzip -o "$ZIP" -d ./ >&2
  mv bin/cryptsetup_$binArch $MODPATH/bin/cryptsetup
  mv bin/fstype_$binArch $MODPATH/bin/fstype
  mv bin/rsync_$binArch $MODPATH/bin/rsync
  mv common/fbind $MODPATH/system/*bin/
  mv common/core.sh $MODPATH/
  cp -f common/service.sh $MOUNTPATH0/.core/service.d/fbind.sh
  mv -f common/tutorial* License* README* $modData/info/

  # patch config.txt
  sh common/patch_config.sh

  set +euxo pipefail

  # cleanup
  if [ $curVer -lt 201810290 ]; then
    cd /data/property/ && rm *esdfs_sdcard *fuse_sdcard *sys.sdcardfs
    rm -rf $modData/logs/ /storage/*/.fbind_bkp/ /external_sd/.fbind_bkp/ \
      $MOUNTPATH0/.core/post-fs-data.d/fbind.sh $modData/*tmp*
  fi 2>/dev/null
}


debug_exit() {
  local e=$?
  echo -e "\n***EXIT $e***\n"
  set +euxo pipefail
  set
  echo
  echo "SELinux status: $(getenforce 2>/dev/null || sestatus 2>/dev/null)" \
    | sed 's/En/en/;s/Pe/pe/'
  if [ $e -ne 0 ]; then
    unmount_magisk_img
    $BOOTMODE || recovery_cleanup
    set -u
    rm -rf $TMPDIR
  fi 1>/dev/null 2>&1
  exit $e
} 1>&2


# module.prop reader
i() {
  local p=$INSTALLER/module.prop
  [ -f $p ] || p=$MODPATH/module.prop
  grep_prop $1 $p
}


version_info() {

  local c="" whatsNew="- Fixed <unable to bind-mount folders whose names contain space characters>.
- Updated support links"

  set -euxo pipefail

  ui_print " "
  ui_print "  WHAT'S NEW"
  echo "$whatsNew" | \
    while read c; do
      ui_print "    $c"
    done
  ui_print " "

  # a note on untested Magisk versions
  if [ ${MAGISK_VER/.} -gt 173 ]; then
    ui_print " "
    ui_print "(i) This Magisk version hasn't been tested by @VR25!"
    ui_print "- If you come across any issue, please report."
    ui_print " "
  fi

  ui_print "  SUPPORT"
  ui_print "    - Facebook page: facebook.com/VR25-at-xda-developers-258150974794782/"
  ui_print "    - Git repository: github.com/Magisk-Modules-Repo/fbind/"
  ui_print "    - Telegram profile: t.me/vr25xda/"
  ui_print "    - XDA thread: forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/"
  ui_print " "
}

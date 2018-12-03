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
PROPFILE=false

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
  for f in $MODPATH/bin/* $MODPATH/system/*bin/* $MODPATH/*.sh; do
    [ -f "$f" ] && set_perm $f 0 0 0755
  done
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

  umask 000
  set -euxo pipefail
  trap debug_exit EXIT

  local binArch=$(get_cpu_arch)
  config=/data/media/$MODID/config.txt

  # magisk.img mount path
  if $BOOTMODE; then
    MOUNTPATH0=/sbin/.magisk/img
    [ -e $MOUNTPATH0 ] || MOUNTPATH0=/sbin/.core/img
    if [ ! -e $MOUNTPATH0 ]; then
      ui_print " "
      ui_print "(!) \$MOUNTPATH0 not found"
      ui_print " "
      exit 1
    fi
  else
    MOUNTPATH0=$MOUNTPATH
  fi

  curVer=$(grep_prop versionCode $MOUNTPATH0/$MODID/module.prop || :)
  [ -z "$curVer" ] && curVer=0

  # create module paths
  rm -rf $MODPATH 2>/dev/null || :
  mkdir -p ${config%/*}/info $MODPATH/bin
  [ -d /system/xbin ] && mkdir -p $MODPATH/system/xbin \
    || mkdir -p $MODPATH/system/bin

  # extract module files
  ui_print "- Extracting module files"
  cd $INSTALLER
  unzip -o "$ZIP" -d ./ >&2
  mv bin/cryptsetup_$binArch $MODPATH/bin/cryptsetup
  mv bin/fstype_$binArch $MODPATH/bin/fstype
  mv common/$MODID $MODPATH/system/*bin/
  mv common/core.sh $MODPATH/
  mv -f License* README* common/sample* ${config%/*}/info/

  set +euo pipefail
  cleanup
}


install_system() {

  umask 000
  set -euxo pipefail

  local modId=fbind
  local binArch=$(get_cpu_arch)
  local modPath=/system/etc/$modId
  local config=/data/media/$modId/config.txt

  grep_prop() {
    local REGEX="s/^$1=//p"
    shift
    local FILES=$@
    [ -z "$FILES" ] && FILES='/system/build.prop'
    sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
  }

  mount -o rw /system 2>/dev/null || mount -o remount,rw /system
  curVer=$(grep_prop versionCode $modPath/module.prop || :)
  [ -z "$curVer" ] && curVer=0

  # set OUTFD
  if [ -z $OUTFD ] || readlink /proc/$$/fd/$OUTFD | grep -q /tmp; then
    for FD in `ls /proc/$$/fd`; do
      if readlink /proc/$$/fd/$FD | grep -q pipe; then
        if ps | grep -v grep | grep -q " 3 $FD "; then
          OUTFD=$FD
          break
        fi
      fi
    done
  fi

  ui_print() { echo -e "ui_print $1\nui_print" >> /proc/self/fd/$OUTFD; }

  print_modname

  # install/uninstall
  if [ $curVer -eq $(i versionCode) ]; then
    ui_print "(i) Uninstalling"
    rm -rf /system/etc/init.d/$modId \
           /system/etc/$modId \
           /system/addon.d/$modId.sh \
           /system/*bin/$modId 2>/dev/null || :
    ui_print " "

  else
    # create paths
    mkdir -p $modPath/bin
    mkdir -p ${config%/*}/info

    # place files
    ui_print "- Installing"
    cd $INSTALLER
    unzip -o "$ZIP" -d ./ >&2
    if [ -d /system/xbin ]; then
      mv -f common/$modId /system/xbin/
    else
      mv -f common/$modId /system/bin/
    fi
    mv bin/cryptsetup_$binArch $modPath/bin/cryptsetup
    mv bin/fstype_$binArch $modPath/bin/fstype
    mv -f common/core.sh module.prop $modPath/
    mv -f License* README* common/sample* ${config%/*}/info/
    chown 0:0 /system/*bin/$modId $modPath/bin/cryptsetup $modPath/bin/fstype
    chmod 0755 /system/*bin/$modId $modPath/bin/cryptsetup $modPath/bin/fstype
    if [ -e /system/etc/init.d ]; then
      $LATESTARTSERVICE && mv -f common/service.sh /system/etc/init.d/$modId || :
      chown 0:0 /system/etc/init.d/$modId
      chmod 0755 /system/etc/init.d/$modId
    fi
    if [ -e /system/addon.d ]; then
      mv -f common/addon.d.sh /system/addon.d/$modId.sh
      chown 0:0 /system/addon.d/$modId.sh
      chmod 0755 /system/addon.d/$modId.sh
    fi

    set +euo pipefail
    cleanup
    MAGISK_VER=0
    version_info
  fi
  exit 0
}


debug_exit() {
  local exitCode=$?
  echo -e "\n***EXIT $exitCode***\n"
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
  echo
  exit $exitCode
} 1>&2


# module.prop reader
i() {
  local p=$INSTALLER/module.prop
  [ -f $p ] || p=$MODPATH/module.prop
  grep_prop $1 $p
}


get_cpu_arch() {
  case $(uname -m) in
    *86*) echo -n x86;;
    *ar*) echo -n arm;;
    *) ui_print " "
       ui_print "(!) Unsupported CPU architecture ($ARCH)"
       ui_print " "
       exit 1;;
  esac
}


cleanup() {
  if [ $curVer -lt 201812030 ]; then
    . common/config_patcher.sh
    cd /data/property/ && rm *esdfs_sdcard *fuse_sdcard *sys.sdcardfs
    rm -rf ${config%/*}/logs/ /storage/*/.fbind_bkp/ /external_sd/.fbind_bkp/ \
      $MOUNTPATH0/.core/*/fbind.sh ${config%/*}/*tmp*
  fi 2>/dev/null
}


version_info() {

  local c="" whatsNew="- Ability to easily bind-mount and unmount folders not listed in config.txt
- Automatic FUSE/SDcarsFS handling -- users don't have to care about these anymore; fbind will work with whichever is enabled. ESDFS (Motorola's Emulated SDcard Filesystem) will remain unsupported until a user shares their /proc/mounts.
- Fixed loop devices mounting issues; unmounting these with fbind -u is now supported.
- Improved filtering feature (fbind <option(s)> <pattern|pattern2|...>)
- LUKS unmounting and closing (fbind -u <pattern|pattern2|...>)
- Major cosmetic changes
- New log format
- Redesigned fbind utilities -- run <fbind> on terminal or read README.md for details.
- Removed bloatware
- SDcard wait timeout set to 5 minutes
- Support for /system install (legacy/Magisk-unsupported devices) and Magisk bleeding edge builds
- Updated building and debugging tools
- Updated documentation -- simplified, more user-friendly, more useful"

  set -euo pipefail

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
  ui_print "    - Telegram channel: t.me/vr25_xda/"
  ui_print "    - Telegram profile: t.me/vr25xda/"
  ui_print "    - XDA thread: forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/"
  ui_print " "
}

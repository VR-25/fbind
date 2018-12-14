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
  config=/data/media/0/$MODID/config.txt

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

  if [ $curVer -eq $(i versionCode) ] && ! $BOOTMODE; then
    touch $MODPATH/disable
    ui_print " "
    ui_print "(i) Module disabled"
    ui_print " "
    set +euo pipefail
    unmount_magisk_img
    $BOOTMODE || recovery_cleanup
    set -u
    rm -rf $TMPDIR
    exit 0
  fi

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
  mv common/FUSE.prop $MODPATH/

  # force FUSE
  if [ -e $MOUNTPATH0/$MODID/system.prop ] || [ -e /data/forcefuse ] \
    || echo "${0##*/}" | grep -iq fuse || $PROPFILE
  then
    mv $MODPATH/FUSE.prop $MODPATH/system.prop
    rm -rf /data/forcefuse 2>/dev/null || :
  fi

  set +euo pipefail
  . common/cleanup.sh
}


install_system() {

  umask 000
  set -euxo pipefail
  trap debug_exit EXIT

  local modId=fbind
  local binArch=$(get_cpu_arch)
  local modPath=/system/etc/$modId
  local config=/data/media/0/$modId/config.txt

  grep_prop() {
    local REGEX="s/^$1=//p"
    shift
    local FILES=$@
    [ -z "$FILES" ] && FILES='/system/build.prop'
    sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
  }

  set_perm() {
    chown 0:0 "$@"
    chmod 0755 "$@"
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
    set_perm /system/*bin/$modId $modPath/bin/cryptsetup $modPath/bin/fstype
    mv -f common/service.sh $modPath/autorun.sh
    set_perm $modPath/autorun.sh
    [ -e /system/etc/init.d ] && $LATESTARTSERVICE && ln -sf $modPath/autorun.sh /system/etc/init.d/$modId || :
    if [ -e /system/addon.d ]; then
      mv -f common/addon.d.sh /system/addon.d/$modId.sh
      set_perm /system/addon.d/$modId.sh
    fi

    set +euo pipefail
    . common/cleanup.sh
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


version_info() {

  local c="" whatsNew="- [SDcardFS] Do not remount /mnt/runtime/write
- [SDcardFS] Do not set gid
- [SDcardFS] obb=\$intsd/Android/obb"

  set -euo pipefail

  # a note on untested Magisk versions
  if [ ${MAGISK_VER/.} -gt 180 ]; then
    ui_print " "
    ui_print "  (i) NOTE: this Magisk version hasn't been tested by @VR25!"
    ui_print "    - If you come across any issue, please report."
  fi

  ui_print " "
  ui_print "  WHAT'S NEW"
  echo "$whatsNew" | \
    while read c; do
      ui_print "    $c"
    done
  ui_print " "

  ui_print "  LINKS"
  ui_print "    - Facebook page: facebook.com/VR25-at-xda-developers-258150974794782/"
  ui_print "    - Git repository: github.com/Magisk-Modules-Repo/fbind/"
  ui_print "    - Telegram channel: t.me/vr25_xda/"
  ui_print "    - Telegram profile: t.me/vr25xda/"
  ui_print "    - XDA thread: forum.xda-developers.com/apps/magisk/module-magic-folder-binder-t3621814/"
  ui_print " "
}


# migrate modData
mv /data/media/fbind /data/media/0/ 2>/dev/null

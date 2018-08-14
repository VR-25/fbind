#!/system/bin/sh
# fbind Boot Service (auto-bind)
# Copyright (C) 2017-2018, VR25 @ xda-developers
# License: GPL v3+


main() {

  modID=fbind
  modPath=${0%/*}
  modData=/data/media/$modID
  logsDir=$modData/logs
  newLog=$logsDir/service.sh.log
  oldLog=$logsDir/service.sh_old.log

  # verbosity engine
  mkdir -p $logsDir 2>/dev/null
  [[ -f $newLog ]] && mv $newLog $oldLog
  set -x 2>>$newLog

  mkdir $modData 2>/dev/null
  rm $modData/.no_restore 2>/dev/null


  # intelligently handle SELinux mode
  grep -v '^#' $modData/config.txt 2>/dev/null | grep -q 'setenforce 0' \
    && setenforce 0
  grep -v '^#' $modData/config.txt 2>/dev/null | grep -q 'setenforce auto' \
    && SELinuxAutoMode=true || SELinuxAutoMode=false
  SEck="$(ls -1 $(echo "$PATH" | sed 's/:/ /g') 2>/dev/null | grep -E 'sestatus|getenforce' | head -n1)"

  if [ -n "$SEck" ] && $SELinuxAutoMode; then
    if $SEck | grep -iq enforcing; then
      wasEnforcing=true
      setenforce 0
    else
      wasEnforcing=false
    fi
  fi


  . $modPath/core.sh
  log_start

  # check/fix sdcard filesystem
  if grep -Ev '^#|^part ' $config | grep -iq fsck; then
    echo -e "\n\nFSCK\n"
    wait_until_true [ -b "$(grep -Ev '^#|^part ' $config | grep -i fsck | sed -n 's:^.*/dev/:/dev/:p')" ]
    [ "$?" -eq "0" ] && $(grep -Ev '^#|^part ' $config | grep fsck) || \
      echo "(!) $(grep -Ev '^#|^part ' $config | grep -i fsck | sed -n 's:^.*/dev/:/dev/:p') not ready"
    echo
  fi

  echo -e '\n'
  apply_config
  echo -e '\n'

  if grep -v '^#' $config | grep -Eq '^app_data |^int_extf$|^bind_mnt |^obb.*|^from_to |^target '; then
    bind_folders
  else
    echo -e "\nBIND-MOUNT>\n- Nothing to bind-mount"
  fi

  echo -e '\n'

  if [ -f $modData/cleanup.sh ] || grep -v '^#' $config | grep -q '^cleanup '; then
    cleanupf
  else
    echo -e "\nCLEANUP\n- Nothing to clean"
  fi

  log_end
}

(main) &

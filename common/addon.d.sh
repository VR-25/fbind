#!/sbin/sh
# Preserves fbind across ROM updates
# Based on 50-cm.sh

. /tmp/backuptool.functions

list_files() {
cat <<EOF
bin/fbind
etc/fbind/core.sh
etc/fbind/bin/cryptsetup
etc/fbind/bin/fstype
etc/fbind/module.prop
etc/init.d/fbind
xbin/fbind
EOF
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $S/"$FILE"
    done
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    # set ownership and permissions
    for i in bin/fbind \
      etc/fbind/bin/cryptsetup \
      etc/fbind/bin/fstype \
      etc/init.d/fbind \
      xbin/fbind
    do
      if [ -f $i ]; then
        chown 0:0 $i
        chmod 0755 $i
      fi
    done
  ;;
esac

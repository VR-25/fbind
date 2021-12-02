#!/usr/bin/env sh

echo
trap 'e=$?; echo; exit $e' EXIT
cd "${0%/*}" 2>/dev/null

for i in system/bin/fbind *.sh; do
  sh -n $i || exit
done

filename=fbind_magisk_$(date +%Y-%m-%d_%H:%M:%S).zip
echo _builds/$filename
mkdir -p _builds
zip -r9 _builds/$filename * .git* -x \*.zip -x .git/\* -x '_*/*'

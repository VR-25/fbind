#!/usr/bin/env sh

echo
trap 'e=$?; echo; exit $e' EXIT
cd "${0%/*}" 2>/dev/null

sh -n system/bin/fbind && {
  filename=fbind-$(date +%Y.%m.%d.%H.%M.%S).zip
  echo $filename
  mkdir -p _builds
  zip -r9 _builds/$filename * .git* -x \*.zip -x .git/\* -x '_*/*'
}

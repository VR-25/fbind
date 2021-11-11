#!/usr/bin/env sh

cd "${0%/*}" 2>/dev/null
zip -r9 fbind-$(date +%Y%m%d%H%M%S).zip * .git* -x \*.zip -x .git/\* -x _misc/\*

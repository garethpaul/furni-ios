#!/bin/bash
set -euo pipefail

test ! -e .travis.yml
test -f Furni.xcworkspace/contents.xcworkspacedata
test -f Furni.xcodeproj/xcshareddata/xcschemes/Furni.xcscheme

plutil -lint Furni/Info.plist Furni/Furni.entitlements FurniTests/Info.plist
cmp -s Podfile.lock Pods/Manifest.lock

if find . -path ./.git -prune -o -type f \( \
  -name '*.p12' -o \
  -name '*.mobileprovision' -o \
  -name '*.pem' -o \
  -name '*.key' -o \
  -name '*.cer' \
\) -print -quit | grep -q .; then
  echo 'Credential or signing material must not be committed.' >&2
  exit 1
fi

if git grep -I -n -E -- \
  'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|encrypted_[A-Za-z0-9_]+:|secure:[[:space:]]*[A-Za-z0-9]' \
  -- ':!scripts/ci-static.sh'; then
  echo 'Potential private key or encrypted CI credential found.' >&2
  exit 1
fi

if git grep -I -n -E -- \
  'pull_request_target|permissions:[[:space:]]*write-all|persist-credentials:[[:space:]]*true' \
  -- '.github/workflows/*.yml' '.github/workflows/*.yaml'; then
  echo 'Workflow requests an unsafe trigger, permission, or persisted credential.' >&2
  exit 1
fi

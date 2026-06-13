#!/bin/bash
set -e
APORTS=$(cd ~/pmbootstrap && ./pmbootstrap.py config aports | tr -d '[:space:]')
for D in "$APORTS/device/testing/firmware-vsmart-zangyapro" \
         ~/active1-pmos/pmaports/device/testing/firmware-vsmart-zangyapro; do
  sed -i 's|^# Maintainer: active1-pmos$|# Maintainer: active1-pmos <dev@example.com>|' "$D/APKBUILD"
done
cd ~/pmbootstrap
./pmbootstrap.py build firmware-vsmart-zangyapro 2>&1 | tail -5
echo "=== built apk? ==="
find ~/.local/var/pmbootstrap -name 'firmware-vsmart-zangyapro-*.apk' 2>/dev/null
echo DONE

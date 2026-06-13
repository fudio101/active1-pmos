#!/bin/bash
D=~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/device-vsmart-zangyapro
DST=/mnt/c/adb/active1-pmos/pmaports-device
cp "$D/deviceinfo" "$D/APKBUILD" "$D/modules-initfs" "$DST/" 2>&1
echo "--- copied ---"
ls -la "$DST/"

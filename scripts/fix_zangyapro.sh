#!/bin/bash
cd ~/pmbootstrap
APORTS=$(./pmbootstrap.py config aports | tr -d '[:space:]')
DST="$APORTS/device/testing/device-vsmart-zangyapro"
echo "DST=$DST"
sed -i '/firmware-vsmart-zangyapro/d' "$DST/APKBUILD"
./pmbootstrap.py checksum device-vsmart-zangyapro 2>&1 | tail -2
echo "=== depends sau khi sua ==="
grep -A10 'depends=' "$DST/APKBUILD"
echo "=== device config ==="
./pmbootstrap.py config device
echo DONE

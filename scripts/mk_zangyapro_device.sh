#!/bin/bash
set -e
cd ~/pmbootstrap
APORTS=$(./pmbootstrap.py config aports 2>/dev/null | tr -d '[:space:]')
echo "APORTS=$APORTS"
SRC="$APORTS/device/testing/device-xiaomi-jasmine_sprout"
DST="$APORTS/device/testing/device-vsmart-zangyapro"
echo "===== jasmine APKBUILD ====="
cat "$SRC/APKBUILD"
echo "===== jasmine modules-initfs ====="
cat "$SRC/modules-initfs" 2>/dev/null
rm -rf "$DST"
cp -r "$SRC" "$DST"
DI="$DST/deviceinfo"
sed -i 's|deviceinfo_name=.*|deviceinfo_name="Vsmart Active 1"|' "$DI"
sed -i 's|deviceinfo_manufacturer=.*|deviceinfo_manufacturer="Vsmart"|' "$DI"
sed -i 's|deviceinfo_codename=.*|deviceinfo_codename="vsmart-zangyapro"|' "$DI"
sed -i 's|deviceinfo_dtb=.*|deviceinfo_dtb="qcom/sdm660-vsmart-zangyapro"|' "$DI"
sed -i 's|xiaomi-jasmine_sprout|vsmart-zangyapro|g' "$DST/APKBUILD"
sed -i 's|Xiaomi Mi A2|Vsmart Active 1|g' "$DST/APKBUILD"
echo ""
echo "===== NEW deviceinfo ====="
cat "$DI"
echo "===== NEW APKBUILD ====="
cat "$DST/APKBUILD"
echo "DST=$DST"
echo DONE

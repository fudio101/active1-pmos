#!/bin/bash
set -e
APORTS=$(cd ~/pmbootstrap && ./pmbootstrap.py config aports | tr -d '[:space:]')
REPO=~/active1-pmos
LIVE_FW="$APORTS/device/testing/firmware-vsmart-zangyapro"
REPO_FW="$REPO/pmaports/device/testing/firmware-vsmart-zangyapro"

# locate the WCN3990 firmware files (from earlier extract, else re-extract jasmine apk)
BOARD=$(find /tmp/fw -name board-2.bin -path '*WCN3990*' 2>/dev/null | head -1)
FW5=$(find /tmp/fw -name firmware-5.bin -path '*WCN3990*' 2>/dev/null | head -1)
if [ -z "$BOARD" ]; then
  APK=$(find ~/.local/var/pmbootstrap -name 'firmware-xiaomi-jasmine_sprout-*.apk' | sort | tail -1)
  rm -rf /tmp/fw; mkdir -p /tmp/fw; ( cd /tmp/fw && tar -xzf "$APK" )
  BOARD=$(find /tmp/fw -name board-2.bin -path '*WCN3990*' | head -1)
  FW5=$(find /tmp/fw -name firmware-5.bin -path '*WCN3990*' | head -1)
fi
echo "board-2.bin = $BOARD ($(stat -c %s "$BOARD") bytes)"
echo "firmware-5.bin = $FW5"

for D in "$LIVE_FW" "$REPO_FW"; do
  mkdir -p "$D"
  cp "$BOARD" "$D/board-2.bin"
  [ -n "$FW5" ] && cp "$FW5" "$D/firmware-5.bin"
  cat > "$D/APKBUILD" <<'EOF'
# Maintainer: active1-pmos
pkgname=firmware-vsmart-zangyapro
pkgver=1
pkgrel=0
pkgdesc="Vsmart Active 1 (zangyapro) WCN3990 WiFi board firmware"
url="https://postmarketos.org"
arch="aarch64"
license="proprietary"
options="!check !strip !archcheck !spdx !tracedeps"
source="board-2.bin firmware-5.bin"
_fw="lib/firmware/ath10k/WCN3990/hw1.0"
package() {
	install -Dm644 "$srcdir"/board-2.bin "$pkgdir"/$_fw/board-2.bin
	install -Dm644 "$srcdir"/firmware-5.bin "$pkgdir"/$_fw/firmware-5.bin
}
EOF
done

# point device package at the new firmware package
for F in "$APORTS/device/testing/device-vsmart-zangyapro/APKBUILD" \
         "$REPO/pmaports/device/testing/device-vsmart-zangyapro/APKBUILD"; do
  sed -i 's/firmware-xiaomi-jasmine_sprout/firmware-vsmart-zangyapro/' "$F"
done

cd ~/pmbootstrap
./pmbootstrap.py checksum firmware-vsmart-zangyapro 2>&1 | tail -1
./pmbootstrap.py checksum device-vsmart-zangyapro 2>&1 | tail -1
echo "=== build firmware pkg to verify ==="
./pmbootstrap.py build firmware-vsmart-zangyapro 2>&1 | tail -4

echo "=== verify ==="
ls -la "$REPO_FW"
echo "--- device depends ---"
grep -A11 'depends=' "$REPO/pmaports/device/testing/device-vsmart-zangyapro/APKBUILD"
echo DONE

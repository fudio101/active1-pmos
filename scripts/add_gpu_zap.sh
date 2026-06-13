#!/bin/bash
set -e
APORTS=$(cd ~/pmbootstrap && ./pmbootstrap.py config aports | tr -d '[:space:]')
REPO=~/active1-pmos
for D in "$APORTS/device/testing/firmware-vsmart-zangyapro" \
         "$REPO/pmaports/device/testing/firmware-vsmart-zangyapro"; do
  cp /tmp/a512_zap.elf "$D/a512_zap.mbn"
  cat > "$D/APKBUILD" <<'EOF'
# Maintainer: fudio101 <thenguyen1024@gmail.com>
pkgname=firmware-vsmart-zangyapro
pkgver=1
pkgrel=1
pkgdesc="Vsmart Active 1 (zangyapro) firmware: WCN3990 WiFi + Adreno 512 zap"
url="https://postmarketos.org"
arch="aarch64"
license="proprietary"
options="!check !strip !archcheck !spdx !tracedeps"
source="board-2.bin firmware-5.bin a512_zap.mbn"
package() {
	install -Dm644 "$srcdir"/board-2.bin   "$pkgdir"/lib/firmware/ath10k/WCN3990/hw1.0/board-2.bin
	install -Dm644 "$srcdir"/firmware-5.bin "$pkgdir"/lib/firmware/ath10k/WCN3990/hw1.0/firmware-5.bin
	install -Dm644 "$srcdir"/a512_zap.mbn   "$pkgdir"/lib/firmware/postmarketos/a512_zap.mbn
}
EOF
done
cd ~/pmbootstrap
./pmbootstrap.py checksum firmware-vsmart-zangyapro 2>&1 | tail -1
echo "=== build ==="
./pmbootstrap.py build firmware-vsmart-zangyapro 2>&1 | tail -3
echo "=== commit ==="
cd "$REPO"; git add -A
git -c user.email=thenguyen1024@gmail.com -c user.name=fudio101 commit -q -m "firmware: add Adreno 512 zap shader for GPU" || echo "(nothing)"
git log --oneline | head -4
echo DONE

#!/bin/bash
# Build the final upstream-mirroring layout in ~/active1-pmos and git-init it.
set -e
SRC=/mnt/c/adb/active1-pmos
DST=~/active1-pmos
KSRC=~/linux-sdm660
DTS=sdm660-vsmart-zangyapro.dts
DEVICE=vsmart-zangyapro

rm -rf "$DST"
mkdir -p "$DST"/{kernel,wiki,docs,scripts,build-output}
mkdir -p "$DST/pmaports/device/testing/device-$DEVICE"

cp "$SRC/README.md" "$SRC/dev.sh" "$DST/"
cp "$SRC"/pmaports-device/* "$DST/pmaports/device/testing/device-$DEVICE/"
cp "$SRC"/device-tree/*.dts "$DST/kernel/"
cp "$SRC"/wiki/*.md "$DST/wiki/"
cp "$SRC"/docs/hardware.md "$SRC"/docs/porting-notes.md "$DST/docs/"
cp "$SRC"/scripts/*.sh "$SRC"/scripts/*.ps1 "$SRC"/scripts/*.py "$DST/scripts/" 2>/dev/null || true
cp "$SRC"/build-output/*.log "$DST/build-output/" 2>/dev/null || true

# normalize line endings + perms
find "$DST" -type f \( -name '*.sh' -o -name '*.md' -o -name 'deviceinfo' -o -name 'APKBUILD' -o -name 'modules-initfs' -o -name '*.dts' \) -exec sed -i 's/\r$//' {} \;
chmod +x "$DST/dev.sh" "$DST"/scripts/*.sh 2>/dev/null || true

# .gitignore
cat > "$DST/.gitignore" <<'EOF'
build-output/*.img
build-output/*.log
*.img
EOF

# kernel patch for upstreaming
( cd "$KSRC"
  git config user.email "dev@example.com" 2>/dev/null || true
  git config user.name "active1-pmos" 2>/dev/null || true
  git add "arch/arm64/boot/dts/qcom/$DTS" "arch/arm64/boot/dts/qcom/Makefile" 2>/dev/null || true
  git commit -q -m "arm64: dts: qcom: sdm660: add Vsmart Active 1 (zangyapro)" 2>/dev/null || true
  git format-patch -1 --stdout 2>/dev/null ) > "$DST/kernel/0001-arm64-dts-qcom-sdm660-add-vsmart-active1.patch" || echo "(patch gen skipped)"

# git init the project
( cd "$DST"
  git init -q
  git add -A
  git -c user.email=dev@example.com -c user.name=active1-pmos commit -q -m "Initial postmarketOS port for Vsmart Active 1 (zangyapro)" || true )

echo "===== ~/active1-pmos tree ====="
( cd "$DST" && find . -not -path './.git/*' -type f | sort )
echo "===== git log ====="
( cd "$DST" && git log --oneline 2>/dev/null )
echo DONE

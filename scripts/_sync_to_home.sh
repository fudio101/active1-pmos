#!/bin/bash
# Copy project tu /mnt/c (Windows mount) sang ~/active1-pmos (Linux canonical)
set -e
SRC=/mnt/c/adb/active1-pmos
DST=~/active1-pmos
mkdir -p "$DST"
cp -r "$SRC"/. "$DST"/
# bo CRLF (vi file tao tu Windows) + chmod
find "$DST" -name '*.sh' -exec sed -i 's/\r$//' {} \;
sed -i 's/\r$//' "$DST/dev.sh"
chmod +x "$DST/dev.sh" "$DST"/scripts/*.sh 2>/dev/null || true
echo "=== ~/active1-pmos ==="
ls -la "$DST"
echo "=== cay file ==="
( cd "$DST" && find . -type f | sort )
echo "=== thu chay help ==="
"$DST/dev.sh" help 2>&1 | head -20
echo DONE

#!/bin/bash
cd ~/pmbootstrap
echo "=== export ==="
./pmbootstrap.py export /tmp/pmos-export 2>&1 | tail -15
echo "=== files in /tmp/pmos-export ==="
ls -la /tmp/pmos-export/
echo "=== copy boot.img ra /mnt/c/adb ==="
# boot image co the ten boot.img hoac <device>.img; tim file boot
BIMG=$(ls /tmp/pmos-export/boot.img 2>/dev/null || ls /tmp/pmos-export/*boot*.img 2>/dev/null | head -1)
echo "BIMG=$BIMG"
cp -Lv "$BIMG" /mnt/c/adb/pmos-jasmine-boot.img 2>&1
echo "=== ket qua ==="
ls -la /mnt/c/adb/pmos-jasmine-boot.img 2>&1
# kiem magic (ANDROID!)
xxd -l 8 /mnt/c/adb/pmos-jasmine-boot.img 2>&1
echo "DONE"

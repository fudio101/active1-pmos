#!/bin/bash
set -e
EMAIL="thenguyen1024@gmail.com"
NAME="fudio101"
APORTS=$(cd ~/pmbootstrap && ./pmbootstrap.py config aports | tr -d '[:space:]')
REPO=~/active1-pmos

echo "=== set maintainer in APKBUILDs ==="
for F in "$APORTS/device/testing/device-vsmart-zangyapro/APKBUILD" \
         "$APORTS/device/testing/firmware-vsmart-zangyapro/APKBUILD" \
         "$REPO/pmaports/device/testing/device-vsmart-zangyapro/APKBUILD" \
         "$REPO/pmaports/device/testing/firmware-vsmart-zangyapro/APKBUILD"; do
  [ -f "$F" ] || continue
  if grep -q '^# Maintainer:' "$F"; then
    sed -i "s|^# Maintainer:.*|# Maintainer: $NAME <$EMAIL>|" "$F"
  else
    sed -i "1i # Maintainer: $NAME <$EMAIL>" "$F"
  fi
done
cd ~/pmbootstrap
./pmbootstrap.py checksum device-vsmart-zangyapro 2>&1 | tail -1
./pmbootstrap.py checksum firmware-vsmart-zangyapro 2>&1 | tail -1

echo "=== git commit ==="
cd "$REPO"
git config user.email "$EMAIL"; git config user.name "$NAME"
git add -A
git commit -q -m "Add firmware-vsmart-zangyapro (WCN3990 board-2.bin); maintainer email" || echo "(nothing to commit)"
git log --oneline | head -4

echo ""
echo "=== search stock partitions for GPU zap (a5xx) ==="
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'echo 147147 | sudo -S sh -c "echo ---vendor_a/firmware---; ls /run/msm-firmware-loader/mnt/vendor_a/firmware/ 2>/dev/null; echo ---any zap/a5 anywhere---; find /run/msm-firmware-loader/mnt -iname \"*zap*\" 2>/dev/null; find /run/msm-firmware-loader/mnt -iname \"a5*\" 2>/dev/null | head"'
echo DONE

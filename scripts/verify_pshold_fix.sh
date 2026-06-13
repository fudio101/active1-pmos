#!/bin/bash
# Run AFTER booting the patched kernel. Confirms the PMIC PS_HOLD reset type
# was reprogrammed to HARD_RESET (0x07), then optionally tests a real reboot.
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"

echo "=== kernel build id (confirm new kernel running) ==="
$SSH 'uname -a; cat /proc/sys/kernel/random/boot_id' 2>/dev/null

echo "=== driver log: PS_HOLD configured? ==="
$SSH 'echo 147147 | sudo -S dmesg 2>/dev/null | grep -iE "PS_HOLD|pshold|hard reset"'

echo "=== PMIC PON PS_HOLD reset-type register (085a should be 07, was 01) ==="
$SSH 'echo 147147 | sudo -S grep -E "^085a|^085b" /sys/kernel/debug/regmap/0-00/registers' 2>/dev/null

echo ""
echo "If 085a = 07  -> fix is active. Next: run a real reboot test:"
echo "   bash scripts/reboot_test.sh"
echo DONE

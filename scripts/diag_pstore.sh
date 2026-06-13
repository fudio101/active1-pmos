#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"

echo "===== pstore dir ====="
$SSH 'echo 147147 | sudo -S ls -la /sys/fs/pstore/ 2>/dev/null'
echo ""
echo "===== ramoops in DT / reserved-memory? ====="
$SSH 'echo 147147 | sudo -S sh -c "ls /sys/firmware/devicetree/base/reserved-memory/ 2>/dev/null | grep -iE \"ramoops|pstore|ram_console|debug\"; echo ---dmesg---; dmesg 2>/dev/null | grep -iE \"ramoops|pstore|console-ramoops\""'
echo ""
echo "===== last-boot console (the hang), full tail ====="
$SSH 'echo 147147 | sudo -S sh -c "for f in /sys/fs/pstore/*; do echo \"=== \$f ===\"; tail -80 \"\$f\"; done" 2>/dev/null'
echo DONE

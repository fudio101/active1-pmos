#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"

echo "===== uptime / boot id ====="
$SSH 'uptime; echo; cat /proc/sys/kernel/random/boot_id'

echo ""
echo "===== pstore (ramoops) present? last-boot console? ====="
$SSH 'echo 147147 | sudo -S sh -c "ls -la /sys/fs/pstore/ 2>&1; echo ---; mount | grep -i pstore"'

echo ""
echo "===== last-boot console log (the HANG), tail ====="
$SSH 'echo 147147 | sudo -S sh -c "f=\$(ls /sys/fs/pstore/console-ramoops* 2>/dev/null | head -1); [ -n \"\$f\" ] && tail -60 \"\$f\" || echo NO_PSTORE_CONSOLE"'

echo ""
echo "===== reboot mechanism (psci / qcom reboot-mode / pon) ====="
$SSH 'echo 147147 | sudo -S sh -c "cat /sys/firmware/devicetree/base/psci/compatible 2>/dev/null | tr \"\\0\" \" \"; echo; ls /sys/firmware/devicetree/base/ | grep -iE \"pon|reboot|restart\"; echo ---; dmesg | grep -iE \"psci|pm8998|qcom-pon|reboot|restart|watchdog\" | head -20"'

echo ""
echo "===== remoteproc states (modem/adsp/wcnss left running?) ====="
$SSH 'echo 147147 | sudo -S sh -c "for r in /sys/class/remoteproc/remoteproc*; do echo -n \"\$r: \"; cat \$r/name 2>/dev/null | tr -d \"\\n\"; echo -n \" -> \"; cat \$r/state 2>/dev/null; done"'

echo ""
echo "===== kernel cmdline ====="
$SSH 'cat /proc/cmdline'

echo DONE

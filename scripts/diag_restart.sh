#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"

echo "===== pshold node in DT? ====="
$SSH 'echo 147147 | sudo -S sh -c "find /sys/firmware/devicetree/base -iname \"*pshold*\" -o -iname \"*restart*\" 2>/dev/null; echo ---grep-compat---; grep -rl pshold /sys/firmware/devicetree/base/ 2>/dev/null"'

echo ""
echo "===== restart/poweroff handlers in dmesg ====="
$SSH 'echo 147147 | sudo -S sh -c "dmesg | grep -iE \"pshold|psci.*reset|restart|poweroff|reboot|pm_power_off|sys-off\" | head -20"'

echo ""
echo "===== reboot/restart soc nodes (compat) ====="
$SSH 'echo 147147 | sudo -S sh -c "for d in /sys/firmware/devicetree/base/soc/*; do c=\$d/compatible; [ -f \"\$c\" ] && { n=\$(basename \$d); v=\$(tr \"\\0\" \" \" < \$c); echo \"\$n: \$v\"; }; done | grep -iE \"pshold|reset|reboot|restart|pon|pwrkey\""'

echo ""
echo "===== what is registered as restart (kallsyms hint) ====="
$SSH 'echo 147147 | sudo -S sh -c "cat /sys/kernel/debug/sleep_stats 2>/dev/null | head -3; echo ---; dmesg | grep -iE \"qcom_scm|scm: convention|psci\" | head -6"'
echo DONE

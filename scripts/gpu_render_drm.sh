#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"

echo "===== which glmark2 variants are available? ====="
$SSH 'ls /usr/bin/glmark2* 2>/dev/null; echo 147147 | sudo -S apk info glmark2 2>/dev/null | head -1'

echo ""
echo "===== GPU debugfs state (find dri node, dump gpu info) ====="
$SSH 'echo 147147 | sudo -S sh -c "for n in /sys/kernel/debug/dri/*; do [ -f \$n/gpu ] && { echo \"== \$n/gpu ==\"; cat \$n/gpu; }; done"'

echo ""
echo "===== GPU chip / microcode (success) in dmesg ====="
$SSH 'echo 147147 | sudo -S dmesg 2>/dev/null | grep -iE "Adreno|a5xx|chip-id|loaded qcom/a530|GPU.*rev|ME init|gpu_busy" | head'

echo ""
echo "===== surfaceless EGL render node probe (proves render node usable) ====="
$SSH 'EGL_PLATFORM=surfaceless eglinfo -B 2>/dev/null | grep -iE "renderer|vendor|EGL_PLATFORM|Device" | head; echo "---"; EGL_PLATFORM=device eglinfo 2>/dev/null | grep -iE "renderer|vendor|device path" | head'
echo DONE

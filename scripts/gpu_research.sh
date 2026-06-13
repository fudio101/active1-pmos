#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"
echo "===== GPU dmesg ====="
$SSH 'dmesg 2>/dev/null | grep -iE "adreno|a5xx|a530|a512|zap|msm_gpu| gmu|gpummu|drm:.*gpu" | tail -22'
echo ""
echo "===== firmware on rootfs: qcom a5xx + zap + postmarketos ====="
$SSH 'ls -la /lib/firmware/qcom/ 2>/dev/null | grep -iE "a5|a530|a512" ; echo ---postmarketos---; ls -la /lib/firmware/postmarketos/ 2>/dev/null; echo ---a530dir---; ls /lib/firmware/qcom/sdm660/ 2>/dev/null'
echo ""
echo "===== what firmware-qcom-adreno-a530 installs ====="
$SSH 'apk info -L firmware-qcom-adreno-a530 2>/dev/null | grep -iE "a5|zap|\.fw|\.mbn"'
echo ""
echo "===== Active 1 own zap/adreno fw in stock partitions (msm-firmware-loader mounts) ====="
$SSH 'echo 147147 | sudo -S sh -c "find /run/msm-firmware-loader/mnt -iname \"*a512*\" -o -iname \"*a530*\" -o -iname \"*zap*\" 2>/dev/null | head -10"'
echo ""
echo "===== DRM / GPU node + renderer ====="
$SSH 'ls /sys/class/drm/; echo ---; cat /sys/devices/platform/soc@0/*.gpu/*/devcoredump 2>/dev/null | head -1; command -v glxinfo eglinfo wlinfo 2>/dev/null'
echo DONE

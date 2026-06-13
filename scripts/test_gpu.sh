#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"
echo "=== deploy a512_zap.mbn to running rootfs ==="
sshpass -p 147147 scp $SSHOPT /tmp/a512_zap.elf fudio101@$IP:/tmp/a512_zap.mbn
$SSH 'echo 147147 | sudo -S sh -c "mkdir -p /lib/firmware/postmarketos && cp /tmp/a512_zap.mbn /lib/firmware/postmarketos/a512_zap.mbn && ls -la /lib/firmware/postmarketos/a512_zap.mbn"'
echo "=== reboot (PRESS POWER at corrupt warning) ==="
$SSH 'echo 147147 | sudo -S reboot' 2>/dev/null || true
sleep 25
for i in $(seq 1 48); do $SSH 'true' 2>/dev/null && { echo "ssh back ~$((25+i*5))s"; break; }; sleep 5; done
sleep 6
echo "=== GPU dmesg after reboot ==="
$SSH 'echo 147147 | sudo -S dmesg 2>/dev/null | grep -iE "adreno|a5xx|zap|msm_gpu|gpu_|gmu|chip-id" | tail -16'
echo "=== any zap/firmware error left? ==="
$SSH 'echo 147147 | sudo -S dmesg 2>/dev/null | grep -iE "zap|a530_pm4|adreno_request_fw" | tail -6'
echo "=== renderer (freedreno = hw, llvmpipe = sw) ==="
$SSH 'command -v eglinfo >/dev/null || (echo 147147 | sudo -S apk add --no-progress mesa-demos 2>&1 | tail -1); eglinfo -B 2>/dev/null | grep -iE "renderer|vendor|device path" | head; echo ---; ls /sys/class/drm/'
echo DONE

#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6"
# try LAN first then USB
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
echo "using IP=$IP"
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "=== htop installed? ==="
$SSH 'command -v htop && echo HTOP_OK || echo NO_HTOP'
echo ""
echo "=== DRM cards / fb / dri ==="
$SSH 'ls -la /dev/dri/ 2>&1; echo ---fb---; ls -la /dev/fb* 2>&1'
echo ""
echo "=== drm connector status (any connected display?) ==="
$SSH 'for c in /sys/class/drm/card*-*/status; do echo "$c = $(cat $c 2>/dev/null)"; done'
echo ""
echo "=== simpledrm / framebuffer / dpu in dmesg ==="
$SSH 'dmesg 2>/dev/null | grep -iE "simple-frame|simpledrm|\[drm\]|msm_dpu|panel|fb0" | tail -14'
echo ""
echo "=== input devices (any keyboard/usb?) ==="
$SSH 'ls /dev/input/ 2>&1; echo ---; cat /proc/bus/input/devices 2>/dev/null | grep -E "Name=" | head'
echo DONE

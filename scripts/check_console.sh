#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"
echo "=== getty / login on the framebuffer console (tty1)? ==="
$SSH 'systemctl --no-pager | grep -iE "getty" ; echo ---; systemctl status getty@tty1 2>/dev/null | head -4'
echo ""
echo "=== current console / active tty ==="
$SSH 'cat /sys/class/tty/tty0/active 2>/dev/null; echo ---fbcon---; dmesg | grep -iE "fbcon|Console:|switching to" | tail -4'
echo ""
echo "=== is fb0 the msm framebuffer (console shows on screen)? ==="
$SSH 'cat /sys/class/graphics/fb0/name 2>/dev/null; cat /sys/class/graphics/fb0/virtual_size 2>/dev/null'
echo ""
echo "=== handy TUI tools available? ==="
$SSH 'for p in tmux htop nano vim mc ncdu; do printf "%s " "$p"; command -v $p >/dev/null && echo yes || echo no; done'
echo DONE

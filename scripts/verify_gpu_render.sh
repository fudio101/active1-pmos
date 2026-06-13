#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"
echo "===== glmark2 off-screen (full output) ====="
$SSH 'glmark2-es2 --off-screen -b build:duration=2.0 2>&1 | head -25'
echo ""
echo "===== did the GPU microcode load (success lines)? ====="
$SSH 'echo 147147 | sudo -S dmesg 2>/dev/null | grep -iE "a530_pm4|a530_pfp|gpmu|ME init|PFP|adreno.*Loaded|chip-id|GPU initialized|hangcheck|fault" | tail -16'
echo ""
echo "===== msm gpu debug state ====="
$SSH 'echo 147147 | sudo -S sh -c "cat /sys/kernel/debug/dri/*/gpu 2>/dev/null | head -22"'
echo DONE

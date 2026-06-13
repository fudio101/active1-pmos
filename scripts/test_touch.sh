#!/bin/bash
# Run AFTER booting the himax-enabled kernel. Confirms the touch driver probes,
# registers an input device, and emits events when you touch the screen.
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"

echo "=== 1) himax driver messages (probe / product id / errors) ==="
$SSH 'echo 147147 | sudo -S dmesg 2>/dev/null | grep -iE "himax|hx831|Himax|touchscreen|0-0048|i2c.*48" | head -20'

echo ""
echo "=== 2) input devices (look for Himax Touchscreen) ==="
$SSH 'echo 147147 | sudo -S sh -c "cat /proc/bus/input/devices" 2>/dev/null | grep -iE "Name=|Handlers=|himax" '

echo ""
echo "=== 3) capture touch events for ~20s -- PLEASE TOUCH/SWIPE THE SCREEN NOW ==="
$SSH 'echo 147147 | sudo -S sh -c "command -v evtest >/dev/null || apk add --no-progress evtest >/dev/null 2>&1; \
  EV=\$(grep -B5 -i himax /proc/bus/input/devices | grep -oE \"event[0-9]+\" | head -1); \
  [ -z \"\$EV\" ] && EV=\$(grep -iA5 \"Himax\" /proc/bus/input/devices | grep -oE \"event[0-9]+\" | head -1); \
  echo using /dev/input/\$EV; \
  timeout 20 evtest /dev/input/\$EV 2>&1 | grep -iE \"ABS_MT|BTN_TOUCH|SYN_REPORT|Event:|Testing|Input device name\" | head -40"'
echo DONE

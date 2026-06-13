#!/bin/bash
# Issues a normal `reboot` and checks whether the device comes back to SSH
# ON ITS OWN (no power button). Confirms the warm-reboot-hang fix.
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"
BID=$($SSH 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null)
echo "boot_id BEFORE = $BID"
echo ">>> issuing reboot now (DO NOT touch the power button)..."
$SSH 'echo 147147 | sudo -S systemctl reboot' 2>/dev/null
sleep 30
BACK=""
for i in $(seq 1 48); do
  if $SSH 'true' 2>/dev/null; then BACK=$((30+i*5)); break; fi
  printf '.'; sleep 5
done
echo ""
if [ -n "$BACK" ]; then
  NEW=$($SSH 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null)
  UP=$($SSH 'cut -d. -f1 /proc/uptime' 2>/dev/null)
  echo "SSH BACK after ~${BACK}s | new boot_id=$NEW (uptime ${UP}s)"
  if [ "$BID" != "$NEW" ]; then
    echo "RESULT: ✅✅ UNATTENDED REBOOT WORKS — came back with NO power button!"
  else
    echo "RESULT: ⚠️ same boot_id (did it really reboot?)"
  fi
else
  echo "RESULT: ❌ did not return within ~270s (still hanging, or you cold-booted)"
fi
echo DONE

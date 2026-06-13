#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"

BID_BEFORE=$($SSH 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null)
UP_BEFORE=$($SSH 'cut -d. -f1 /proc/uptime' 2>/dev/null)
echo "boot_id BEFORE = $BID_BEFORE (uptime ${UP_BEFORE}s)"

echo ">>> Triggering PS_HOLD hard reset now..."
$SSH 'echo 147147 | sudo -S sh -c "sync; nohup python3 -c \"import mmap,os,struct; fd=os.open(chr(47)+chr(100)+chr(101)+chr(118)+chr(47)+chr(109)+chr(101)+chr(109),os.O_RDWR|os.O_SYNC); m=mmap.mmap(fd,4096,offset=0x10ac000); m.write(struct.pack(chr(60)+chr(73),0))\" >/dev/null 2>&1 &"' 2>/dev/null
echo "(reset triggered; SSH will drop)"

echo ">>> Waiting for device to come back on its own (no power button)..."
BACK=""
for i in $(seq 1 50); do
  sleep 5
  if $SSH 'true' 2>/dev/null; then BACK=$((i*5)); break; fi
  printf '.'
done
echo ""
if [ -n "$BACK" ]; then
  BID_AFTER=$($SSH 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null)
  UP_AFTER=$($SSH 'cut -d. -f1 /proc/uptime' 2>/dev/null)
  echo "SSH BACK after ~${BACK}s"
  echo "boot_id AFTER  = $BID_AFTER (uptime ${UP_AFTER}s)"
  if [ "$BID_BEFORE" != "$BID_AFTER" ]; then
    echo "RESULT: ✅ REBOOTED CLEANLY via PS_HOLD (new boot_id, low uptime) — fix confirmed"
  else
    echo "RESULT: ⚠️ same boot_id — did not actually reboot?"
  fi
else
  echo "RESULT: ❌ did NOT come back within ~250s (may be hung, or you cold-booted). "
fi
echo DONE

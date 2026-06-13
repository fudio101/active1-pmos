#!/bin/bash
cd ~/pmbootstrap
echo "=== running init (piped answers) ==="
# Order (pmbootstrap 3.x): workpath, channel, vendor, codename, [kernel], username, ui, ...rest defaults
printf '\n\nxiaomi\njasmine_sprout\nuser\nnone\n\n\n\n\n\n\n\n\n\n\n' | ./pmbootstrap.py init 2>&1 | tail -40
echo ""
echo "=== EXIT=${PIPESTATUS[0]} ==="
echo "=== resulting config (device/ui/channel) ==="
./pmbootstrap.py config 2>&1 | grep -iE 'device|^ui|channel' || true
echo "DONE_INIT"

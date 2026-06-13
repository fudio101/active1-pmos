#!/bin/bash
D=$(find ~/pmaports-explore/device -name 'device-xiaomi-jasmine_sprout' -type d | head -1)
echo "DEVICE_PATH: $D"
echo "===== deviceinfo ====="
cat "$D/deviceinfo"
echo ""
echo "===== files in dir ====="
ls -la "$D"
echo ""
echo "===== deviceinfo cua 1 device dung lk2nd (vd nokia-pl2 hoac asus-x00td) ====="
for d in device-nokia-pl2 device-asus-x00td device-xiaomi-lavender; do
  DD=$(find ~/pmaports-explore/device -name "$d" -type d | head -1)
  if [ -n "$DD" ]; then
    echo "--- $d ---"
    grep -iE 'lk2nd|dtb|append|cmdline|generate_|flash_offset|bootimg|gpu|chassis' "$DD/deviceinfo"
  fi
done
echo "DONE"

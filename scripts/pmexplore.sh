#!/bin/bash
cd ~
if [ ! -d ~/pmaports-explore ]; then
  echo "=== cloning pmaports (shallow) ==="
  git clone --depth=1 https://gitlab.postmarketos.org/postmarketOS/pmaports.git ~/pmaports-explore 2>&1 | tail -2
fi
P=~/pmaports-explore
echo ""
echo "===== device-xiaomi-jasmine (Mi A2) - deviceinfo ====="
cat "$P/device/community/device-xiaomi-jasmine/deviceinfo" 2>&1
echo ""
echo "===== thu muc device-xiaomi-jasmine ====="
ls -la "$P/device/community/device-xiaomi-jasmine/" 2>&1
echo ""
echo "===== kernel package linux-postmarketos-qcom-sdm660 - APKBUILD (dau) ====="
find "$P" -path '*linux-postmarketos-qcom-sdm660*' -name APKBUILD 2>/dev/null | head -1 | xargs cat 2>&1 | head -60
echo ""
echo "===== cac device SDM660 da co (deviceinfo_dtb) ====="
grep -rl "qcom-sdm660" "$P/device/" 2>/dev/null | xargs -I{} dirname {} | xargs -I{} basename {} | sort -u
echo "DONE"

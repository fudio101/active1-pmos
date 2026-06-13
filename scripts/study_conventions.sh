#!/bin/bash
P=~/pmaports-explore
echo "===== device/ co nhung nhanh nao (testing/community/main...) ====="
ls "$P/device/"
echo ""
echo "===== so device moi nhanh ====="
for d in "$P"/device/*/; do echo "$(basename $d): $(ls "$d" | wc -l)"; done
echo ""
echo "===== file trong 1 device port DIEN HINH (vd nokia-pl2, cung sdm660) ====="
ND=$(find "$P/device" -name 'device-nokia-pl2' -type d | head -1)
echo "PATH (tuong doi): ${ND#$P/}"
ls -la "$ND"
echo ""
echo "===== co device nao kem KERNEL rieng (de xem layout kernel) ====="
find "$P/device" -name 'APKBUILD' -path '*linux*' 2>/dev/null | head -3
echo ""
echo "===== convention dts trong kernel: deviceinfo_dtb tro vao dau ====="
grep -h 'deviceinfo_dtb=' "$ND/deviceinfo"
echo ""
echo "===== file huong dan dong gop / porting trong pmaports ====="
ls "$P" | grep -iE 'README|CONTRIB|porting|HACKING'
find "$P" -maxdepth 2 -iname '*.md' 2>/dev/null | grep -iE 'device|port|contrib' | head
echo ""
echo "===== deviceinfo format: liet ke cac key chuan (tu 1 device day du) ====="
LD=$(find "$P/device" -name 'device-xiaomi-lavender' -type d | head -1)
grep -oE '^deviceinfo_[a-z_]+' "$LD/deviceinfo" | head -40
echo DONE

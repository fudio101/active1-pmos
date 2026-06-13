#!/bin/bash
sudo apt-get install -y -qq device-tree-compiler 2>&1 | tail -1
# chon stock boot image
BOOT=/mnt/c/adb/stock_boot.img
[ -f "$BOOT" ] || BOOT="/mnt/c/adb/[FileSell]_PQ6001-2.0.4-20191212-1605-vin-user-62-OS9-Fastboot/boot.img"
echo "BOOT=$BOOT ($(stat -c %s "$BOOT" 2>/dev/null) bytes)"
mkdir -p /tmp/dtbs
python3 - "$BOOT" <<'PY'
import struct,sys,os
img=open(sys.argv[1],'rb').read()
magic=b'\xd0\x0d\xfe\xed'; i=0; n=0
for f in os.listdir('/tmp/dtbs'):
    os.remove('/tmp/dtbs/'+f)
while True:
    j=img.find(magic,i)
    if j<0: break
    ts=struct.unpack('>I',img[j+4:j+8])[0]
    if 0x100<ts<3000000 and j+ts<=len(img):
        open('/tmp/dtbs/%d.dtb'%n,'wb').write(img[j:j+ts]); n+=1; i=j+ts
    else:
        i=j+4
print("extracted",n,"dtb(s)")
PY
echo "=== decompile + grep touch/panel/wcn ==="
for d in /tmp/dtbs/*.dtb; do
  dtc -I dtb -O dts "$d" -o "${d%.dtb}.dts" 2>/dev/null
done
echo "--- TOUCH controllers ---"
grep -rhiE 'focaltech|fts|goodix|gt[0-9]{3}|synaptics|himax|hx[0-9]|novatek|nt[0-9]{5}|atmel|melfas' /tmp/dtbs/*.dts 2>/dev/null | grep -iE 'compatible|label|touch' | sort -u | head -20
echo "--- PANEL ---"
grep -rhiE 'qcom,mdss-dsi-panel-name|hx83112|himax' /tmp/dtbs/*.dts 2>/dev/null | sort -u | head -10
echo "--- WCN / WIFI / BT ---"
grep -rhiE 'wcn3990|wlan|bluetooth|wifi|qca6174|cnss' /tmp/dtbs/*.dts 2>/dev/null | grep -iE 'compatible|status' | sort -u | head -10
echo DONE

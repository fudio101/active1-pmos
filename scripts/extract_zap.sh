#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"
echo "=== copy a512_zap from stock vendor to /tmp (readable) ==="
$SSH 'echo 147147 | sudo -S sh -c "cp /run/msm-firmware-loader/mnt/vendor_a/firmware/a512_zap.* /tmp/ && chmod 644 /tmp/a512_zap.* && ls -la /tmp/a512_zap.*"'
echo "=== scp a512_zap.elf + .mdt + .bNN to WSL ==="
sshpass -p 147147 scp $SSHOPT "fudio101@$IP:/tmp/a512_zap.*" /tmp/ 2>&1
ls -la /tmp/a512_zap.* 2>/dev/null
echo ""
echo "=== does our dts already have the GPU/zap node? ==="
grep -niE 'zap|gpu@|firmware-name|adreno|qcom,adreno' ~/active1-pmos/kernel/sdm660-vsmart-zangyapro.dts || echo "(no zap/gpu node found in dts)"
echo ""
echo "=== jasmine dts gpu/zap for reference ==="
grep -niE 'zap|gpu@|firmware-name|adreno|qcom,adreno' ~/active1-pmos/kernel/sdm660-xiaomi-jasmine.dts || echo "(none in jasmine either -> inherited from sdm660.dtsi)"
echo DONE

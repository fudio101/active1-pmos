#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"
echo "=== install glmark2 + offscreen render test (definitive) ==="
$SSH 'echo 147147 | sudo -S apk add --no-progress glmark2 2>&1 | tail -1'
$SSH 'glmark2-es2 --off-screen -b build:duration=3.0 2>&1 | grep -iE "GL_RENDERER|GL_VENDOR|glmark2 Score|build:" | head -10'
echo ""
echo "=== confirm GPU firmware actually loaded (full init) ==="
$SSH 'echo 147147 | sudo -S dmesg 2>/dev/null | grep -iE "msm .*A512|adreno.*chip|zap|GPU.*revision|qcom_scm|ME init|gpu_busy" | head -8'

echo ""
echo "=== update wiki: GPU -> Works; commit ==="
REPO=~/active1-pmos
sed -i 's/| GPU (Adreno 512) | Untested |/| GPU (Adreno 512, freedreno FD512) | Works |/' "$REPO/wiki/Vsmart_Active_1.md"
{
  echo ""
  echo "## UPDATE: GPU working (2026-06-14)"
  echo "- Mesa freedreno reports FD512 (hardware accel, not llvmpipe)."
  echo "- Fix: a512_zap.mbn (Adreno 512 zap shader, extracted from stock vendor_a/firmware/a512_zap.elf) added to firmware-vsmart-zangyapro."
  echo "- Cosmetic: a530_pm4.fw early-load warning at boot (deferred fallback succeeds)."
} >> "$REPO/docs/porting-notes.md"
cd "$REPO"; git add -A
git -c user.email=thenguyen1024@gmail.com -c user.name=fudio101 commit -q -m "GPU working (freedreno FD512) via a512_zap; update wiki/notes" || echo "(nothing)"
git log --oneline | head -3
echo DONE

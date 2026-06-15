#!/usr/bin/env bash
# active1-pmos - dev helper for the postmarketOS port of the Vsmart Active 1
# (PQ6001 / codename zangyapro, Qualcomm SDM660). Runs on Linux/macOS (WSL works).
#
#   ./dev.sh <command>     # run without args to list commands
#
# Repo layout mirrors upstream so files can be contributed directly:
#   pmaports/device/testing/device-vsmart-zangyapro/   -> copy into pmaports MR
#   kernel/sdm660-vsmart-zangyapro.dts (+ .patch)       -> kernel contribution
#   wiki/Vsmart_Active_1.md                             -> postmarketOS wiki page
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional local overrides (gitignored). Copy dev.config.example -> dev.config and put your
# own SSH_USER / PASS / PHONE_IP / FASTBOOT there, instead of editing this tracked file or
# exporting env vars every time. The device login user/password come from `pmbootstrap init`.
if [ -f "$HERE/dev.config" ]; then . "$HERE/dev.config"; fi

# ---- Configuration (override via dev.config, env, or edit here) ----
# Defaults below are the original porter's values (user fudio101); change for your own setup.
PMB="${PMB:-$HOME/pmbootstrap}"                  # pmbootstrap checkout
KSRC="${KSRC:-$HOME/linux-sdm660}"               # kernel source (sdm660-mainline/linux)
# The PR targets the active qcom-sdm660-7.0.y branch (6.19 is EOL). 7.0.y has no
# release tag yet, so clone the branch; switch KTAG to a v7.0.x-sdm660 tag once one is cut.
KTAG="${KTAG:-qcom-sdm660-7.0.y}"
KPKG="linux-postmarketos-qcom-sdm660"            # shared SoC kernel package
DEVICE="vsmart-zangyapro"
DTS="sdm660-vsmart-zangyapro.dts"
PASS="${PASS:-147147}"
PHONE_IP="${PHONE_IP:-172.16.42.1}"
SSH_USER="${SSH_USER:-fudio101}"
EXPORT_DIR="${EXPORT_DIR:-/tmp/pmos-export}"
FASTBOOT="${FASTBOOT:-fastboot}"                 # WSL: set FASTBOOT=/mnt/c/adb/fastboot.exe

DTS_SRC="$HERE/kernel/$DTS"
DEVPKG_SRC="$HERE/pmaports/device/testing/device-$DEVICE"

pmb(){ (cd "$PMB" && ./pmbootstrap.py "$@"); }
say(){ printf '\033[1;36m== %s\033[0m\n' "$*"; }

cmd_setup(){   # first run on a fresh Linux/macOS machine
  say "install host deps (git, kpartx, dtc)"
  sudo apt-get update -qq && sudo apt-get install -y -qq git kpartx device-tree-compiler || true
  [ -d "$PMB" ]  || git clone --depth=1 https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git "$PMB"
  [ -d "$KSRC" ] || git clone --depth=1 --branch "$KTAG" https://github.com/sdm660-mainline/linux.git "$KSRC"
  say "now run: (cd $PMB && ./pmbootstrap.py init)  then  ./dev.sh sync"
}

cmd_sync(){    # push dts + device package into the live build trees
  say "sync dts -> kernel source"
  cp -v "$DTS_SRC" "$KSRC/arch/arm64/boot/dts/qcom/$DTS"
  local MK="$KSRC/arch/arm64/boot/dts/qcom/Makefile"
  # Insert the dtb entry tab-indented and in alphabetical order: before the
  # first sdm660-xiaomi-* line, since "vsmart" sorts before "xiaomi".
  local TAB; TAB=$(printf '\t')
  grep -q "${DTS%.dts}.dtb" "$MK" || \
    sed -i "0,/sdm660-xiaomi-.*\.dtb/s/^.*sdm660-xiaomi-.*\.dtb.*\$/dtb-\$(CONFIG_ARCH_QCOM)${TAB}+= ${DTS%.dts}.dtb\n&/" "$MK"
  say "sync device package -> pmaports"
  local APORTS; APORTS="$(pmb config aports | tr -d '[:space:]')"
  local D="$APORTS/device/testing/device-$DEVICE"; mkdir -p "$D"
  cp -v "$DEVPKG_SRC"/* "$D/"
  pmb checksum "device-$DEVICE"
  pmb config device "$DEVICE" >/dev/null; pmb config user "$SSH_USER" >/dev/null
  say "synced"
}

cmd_patch(){   # regenerate kernel/*.patch from the committed dts in $KSRC
  say "generating kernel patch from $KSRC"
  ( cd "$KSRC"
    git add "arch/arm64/boot/dts/qcom/$DTS" "arch/arm64/boot/dts/qcom/Makefile"
    git commit -q -m "arm64: dts: qcom: sdm660: add Vsmart Active 1 (zangyapro)" || true
    git format-patch -1 --stdout ) > "$HERE/kernel/0001-arm64-dts-qcom-sdm660-add-vsmart-active1.patch"
  ls -la "$HERE/kernel/"*.patch
}

cmd_build(){   say "build kernel (--src $KSRC)"; pmb build "$KPKG" --src "$KSRC"; }
cmd_install(){ say "install rootfs+boot (pass=$PASS)"; pmb install --password "$PASS"; }
cmd_export(){  say "export -> $EXPORT_DIR"; pmb export "$EXPORT_DIR"; ls -la "$EXPORT_DIR"; }
cmd_all(){     cmd_sync; cmd_build; cmd_install; cmd_export; echo; say "next: put phone in fastboot, then ./dev.sh flash"; }

cmd_bootboot(){ say "fastboot boot (test, no write)"; "$FASTBOOT" boot "${1:-$EXPORT_DIR/boot.img}"; }
cmd_flash(){
  say "fastboot flash boot + userdata + reboot"
  "$FASTBOOT" flash boot "$EXPORT_DIR/boot.img"
  if [ -f "$EXPORT_DIR/$DEVICE.img" ]; then "$FASTBOOT" flash userdata "$EXPORT_DIR/$DEVICE.img"
  else "$FASTBOOT" flash userdata "$EXPORT_DIR"/*-root.img; fi
  "$FASTBOOT" reboot
}
cmd_ssh(){    ssh "$SSH_USER@$PHONE_IP"; }
cmd_telnet(){ command -v telnet >/dev/null && telnet "$PHONE_IP" 23 || nc "$PHONE_IP" 23; }
cmd_dmesg(){  ssh "$SSH_USER@$PHONE_IP" "dmesg | tail -n ${1:-60}"; }

case "${1:-help}" in
  setup|sync|patch|build|install|export|all|bootboot|flash|ssh|telnet|dmesg) c="cmd_$1"; shift; "$c" "$@";;
  *) cat <<EOF
active1-pmos/dev.sh  (Linux/macOS)
  setup       first-time: install deps + clone pmbootstrap/kernel
  sync        copy dts + device package into kernel/pmaports trees + checksum
  patch       regenerate kernel/*.patch (git format-patch) for upstreaming
  build       build kernel (pmbootstrap build --src \$KSRC)
  install     build rootfs + boot image (pass=$PASS)
  export      export images to \$EXPORT_DIR ($EXPORT_DIR)
  all         sync + build + install + export
  bootboot    fastboot boot [img]  (test without flashing)
  flash       fastboot flash boot+userdata + reboot
  ssh         ssh $SSH_USER@$PHONE_IP
  telnet      telnet the initramfs debug shell
  dmesg [N]   fetch dmesg over ssh

Env overrides: PMB KSRC DEVICE PASS PHONE_IP SSH_USER FASTBOOT EXPORT_DIR
WSL: phone USB is on the Windows side -> FASTBOOT=/mnt/c/adb/fastboot.exe ./dev.sh flash
Dev loop:  edit kernel/$DTS  ->  ./dev.sh all  ->  ./dev.sh flash
EOF
;;
esac

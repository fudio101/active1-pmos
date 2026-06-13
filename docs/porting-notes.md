# Porting notes / status

## Done
- [x] Proved the Active 1 boots mainline Linux (probe: `fastboot boot` of the jasmine kernel) —
      storage/USB/network/console OK, verity bypassed.
- [x] pmbootstrap 3.10.1 set up (WSL2; passwordless sudo, kpartx, dtc installed).
- [x] Kernel source at `~/linux-sdm660` (tag v6.19.10-sdm660).
- [x] `sdm660-vsmart-zangyapro.dts` (iteration 1: jasmine copy with renamed model/compatible)
      + Makefile entry.
- [x] Device package `device-vsmart-zangyapro` (deviceinfo/APKBUILD/modules-initfs), checksummed,
      device + user configured.
- [x] Stock dtb extracted -> touch/panel/WiFi values (see hardware.md).
- [x] Project organised (upstream-mirroring layout) with `dev.sh`.

## In progress
- [ ] First kernel build with the zangyapro dts (`./dev.sh build`).

## Next (iteration 1 - base server)
- [ ] `./dev.sh install` -> rootfs + boot image.
- [ ] `./dev.sh export`.
- [ ] Phone to fastboot -> `./dev.sh flash` (overwrites boot_a + userdata).
- [ ] Reboot -> `./dev.sh ssh` (fudio101@172.16.42.1, password 147147).
- [ ] Verify: storage mount, networking, whether WiFi/BT come up.

## Iteration 2 - hardware completion
- [ ] WiFi/BT (WCN3990): check after install; if absent, add firmware/calibration + enable nodes.
- [ ] Panel HX83112A: add the DRM panel node (DJN timings) if a real display is wanted.
- [ ] Touch (Himax): skip for headless unless genuinely needed.
- [ ] Clean the dts: drop jasmine-only nodes (nt36672a panel/touch) to remove error spam,
      add a proper SPDX/copyright header before upstreaming.

## Tips
- Dev loop: edit `kernel/sdm660-vsmart-zangyapro.dts` -> `./dev.sh all` -> `./dev.sh flash`.
- Non-destructive test: `./dev.sh bootboot /tmp/pmos-export/boot.img`.
- WSL flashing: `FASTBOOT=/mnt/c/adb/fastboot.exe ./dev.sh flash`, or use usbipd-win, or move
  to a native Linux/macOS host.
- Regenerate the kernel patch for upstreaming: `./dev.sh patch`.

## UPDATE: iteration 1 complete + WiFi/BT working (2026-06-14)
- pmOS boots; SSH up (fudio101@172.16.42.1 over USB, 192.168.1.2 over WiFi).
- Storage: 50.5G root (auto-expanded) + 5.3G zram swap.
- Bluetooth: hci0 (WCN3990) up.
- WiFi: wlan0 works (scans 2.4+5GHz, connected to LAN with internet).
- Fix: device package now depends on firmware-xiaomi-jasmine_sprout (WCN3990 board-2.bin).
- Remaining: per-device WiFi MAC (currently random); avoid 'press power' on reboot (AVB).

## UPDATE: GPU working (2026-06-14)
- Mesa freedreno reports FD512 (hardware accel, not llvmpipe).
- Fix: a512_zap.mbn (Adreno 512 zap shader, extracted from stock vendor_a/firmware/a512_zap.elf) added to firmware-vsmart-zangyapro.
- Cosmetic: a530_pm4.fw early-load warning at boot (deferred fallback succeeds).

## UPDATE: GPU render confirmed via benchmark (2026-06-14)
- glmark2-es2-drm (real GPU submit to panel): GL_RENDERER=FD512, Mesa 26.1.1 (GLES 3.1).
  build 677 FPS, texture 413 FPS, shading 451 FPS, **glmark2 Score: 512** (hardware, not llvmpipe).
- Headless: EGL_PLATFORM=surfaceless and =device both report freedreno/FD512, so the GPU is
  usable without a display (renderD128) for any future Wayland compositor.

## KNOWN ISSUE: unattended/soft reboot hangs (NOT yet fixed)
Symptom: `reboot` (or any soft reboot) -> bootloader -> pmOS splash -> black screen -> hang;
never reaches SSH. Only recovery is hold-Power (force power-off) then power on (cold boot).
Cold boot from power button always works. Blocks fully-headless reboots.

Investigation (2026-06-14):
- Restart handler: PSCI (prio 129) wins over PS_HOLD/msm-poweroff (prio 128).
- Root-cause candidate: PMIC pm660 PON PS_HOLD reset type was WARM_RESET (reg 0x85a=0x01).
  A warm reset restarts the CPUs but does NOT power-cycle peripherals (eMMC, remoteprocs,
  SMMU), so the 2nd boot hangs on dirty hardware. Cold boot power-cycles everything -> clean.
- Tried fix (REVERTED, did not work): patched qcom-pon.c to set PS_HOLD reset type =
  HARD_RESET (0x85a=0x07, confirmed active via regmap debugfs + dmesg "PS_HOLD configured for
  hard reset") and bumped msm-poweroff restart priority 128->130 so PS_HOLD beats PSCI.
  Even with hard reset active, `reboot` still hung -> so the warm-vs-hard reset type is NOT
  the (only) cause. Reverted both kernel edits.
- Next ideas to try: (a) verbose boot image (drop `quiet splash`, add `ignore_loglevel`) and
  photograph the panel at the hang to localize the stuck driver; (b) suspect eMMC/sdhci or a
  remoteproc not re-initialising on the 2nd boot; (c) check whether the bootloader takes a
  different path on a warm boot. ramoops (ramoops@a0000000) is wiped by the forced cold boot,
  so it cannot capture the hang.
Workaround for now: treat as a cold-boot-only device; avoid soft reboots.

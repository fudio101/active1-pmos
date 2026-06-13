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

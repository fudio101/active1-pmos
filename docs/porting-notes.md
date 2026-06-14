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

## KNOWN ISSUE: touchscreen (Himax HX83112A) - WIP, parked
Hardware confirmed working at the bus level:
- Touch IC is on blsp_i2c1 (i2c-0, c175000.i2c) at address **0x48** (irq gpio67, reset gpio66).
- The IC responds and reports **product id 0x83112a** (the panel is a HX83112A TDDI).
- Power/reset are fine (the in-cell touch is powered with the panel rail).
Mainline driver himax_hx83112b only knows id 0x83112b. A DT node with
compatible="himax,hx83112a" + a driver hx83112a chip variant was tried; the IC was read
correctly (id 0x83112a) but probe still went through the hx83112b id-check path and failed
with -EINVAL ("Unknown product id: 83112a"). The chip-variant selection needs another look
(of_match vs i2c_get_match_data picking the wrong himax_chip). Reverted for now.
To resume: add `static const struct himax_chip hx83112a_chip = { .id = 0x83112a,
.check_id = himax_check_product_id, .read_events = himax_read_events };` + of_match
"himax,hx83112a", enable CONFIG_TOUCHSCREEN_HIMAX_HX83112B, DT node touchscreen@48
(reg 0x48, irq gpio67 LEVEL_LOW, reset gpio66, size 1080x2160). Verify the right chip
variant is bound before debugging the protocol.

## FIX: A/B boot-slot retry -> dropped to fastboot (2026-06-14)
A/B device. pmOS did not mark the slot successful, so the bootloader decremented slot_a retry
on each boot/power-cycle until it hit 0 -> slot unbootable -> dropped to fastboot (seen after the
battery drained flat and the device power-cycled). Recovery: fastboot set_active a ; fastboot reboot.
Permanent fix (baked in): added qbootctl to device-vsmart-zangyapro depends; its qbootctl.service
runs qbootctl -m at boot to mark the slot successful. Verified Successful=1 on slot _a.

## NOTE: charging works, but needs a strong charger (mainline pm660 charger)
Charger-type detection works (BC1.2): laptop/weak port -> SDP, input capped ~450mA; a real fast
wall charger -> DCP, input 1.5A. At 450mA the running load (CPU+WiFi+BT, ~0.5A) exceeds input so
the battery NET-DISCHARGES even while "Charging" (this is why it died plugged into a weak port).
On a 2A+ DCP charger: current_max=1.5A, battery current_now ~+1.15A = charges fine while running.
Takeaway for the headless server: power it from a 2A+ wall charger, never a laptop/weak USB port.

## Device measurements (2026-06-14, idle: WiFi+BT+console)
- Power draw ~2.4 W, measured as charger input power minus battery charge power
  (e.g. 1.41 A x 4.71 V in, 1.08 A x 3.98 V into battery -> 6.65 - 4.30 = 2.35 W). Heavy CPU
  load pushes it to ~4-5 W.
- Battery runtime on battery alone (built-in UPS): ~4.5 h from 100 %, ~3.5 h from 80 %
  (3000 mAh, ~2.4 W idle).
- Charging: a weak/laptop SDP port is capped ~450 mA -> net discharge while running; a 2 A DCP
  wall charger gives ICL 1.5 A and ~1.1 A into the battery while running (charge ~40-55 %/h in
  the low-SoC region).
- Temps under charge + load: CPU 53-58 C, GPU ~57 C, SoC (pm660) ~55 C, battery ~44 C - all safe.
- Charger driver qcom_smbx DOES read constant-charge-current/voltage and voltage-max-design from
  the battery DT, but the defaults (ICL/FCC 1.5 A, CV 4.4 V from voltage-max-design) are already
  sensible, so no extra charge-limit DT fields were added (would be redundant).

## Protecting the local packages from apk
device/firmware/kernel are local builds, absent from any public repo, so
`apk upgrade -a|--available|--prune` will downgrade/remove them (it tried to downgrade the kernel
to the repo version that lacks this DTS). Mitigations applied on the device:
- All three pinned in /etc/apk/world (immune to --prune orphan removal).
- Operating rule: only ever run plain `apk upgrade` (never -a / --available / --prune).
- Full immunity would need a signed local repo on the device, or upstreaming to pmaports.

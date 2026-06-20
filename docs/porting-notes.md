# Porting notes / status

Technical bring-up record for the Vsmart Active 1 (vsmart-zangyapro) pmOS port. The user-facing
summary lives in the [postmarketOS wiki](https://wiki.postmarketos.org/wiki/Vsmart_Active_1_(vsmart-zangyapro)) (source: [`../wiki/Vsmart_Active_1.wiki`](../wiki/Vsmart_Active_1.wiki)) and
[`../README.md`](../README.md); this file keeps the deeper findings and the resume instructions
for the open items.

## Status
- Boots mainline Linux; the bootloader's android-verity / `skip_initramfs` cmdline is ignored by
  the mainline kernel, so no verity workaround / lk2nd is needed.
- **Working:** eMMC (HS400, ~50 G auto-expanded root + zram swap), USB + WiFi networking,
  Bluetooth (WCN3990), GPU (Adreno 512 / freedreno FD512), **DSI display** (Himax HX83112A DJN
  1080×2160, real DPU + DSI + panel console — not simple-framebuffer), SSH, charging (with a
  ≥2 A charger), A/B-slot survival across reboots (`qbootctl`).
- **Open:** touchscreen parked; per-device WiFi MAC is random; modem untested. (Soft reboot,
  previously thought broken, now works on a healthy battery — see the reboot note below.)
- **Firmware:** `firmware-vsmart-zangyapro` (hard dep of `device-vsmart-zangyapro`) provides:
  `board-2.bin` (WCN3990 RF-calibration, self-hosted in `vendor-blobs/` — linux-firmware's copy
  crashes SDM660, pmaports #3803), `a512_zap.mbn` (Adreno 512 zap, TheMuppets fetch),
  `firmware-5.bin` (generated at build by `ath10k-fwencoder`), `wlanmdsp.mbn` (from
  `linux-firmware-ath10k` dep). Adreno a530 microcode from `firmware-qcom-adreno-a530`.
  Full provenance: `vendor-blobs/README.md`.

## Tips
- Dev loop: edit `kernel/sdm660-vsmart-zangyapro.dts` -> `./dev.sh all` -> `./dev.sh flash`.
- Non-destructive kernel test: `./dev.sh bootboot /tmp/pmos-export/boot.img`.
- WSL flashing: `FASTBOOT=/mnt/c/adb/fastboot.exe ./dev.sh flash`. Large `userdata` transfers
  fail over 32-bit `fastboot.exe`; split into ~20 MB sparse chunks (`img2simg` + `simg2simg`)
  and flash sequentially.
- Regenerate the kernel patch for upstreaming: `./dev.sh patch`.
- If `pmbootstrap install` fails with exit 125 (`busybox su pmos ... mkdir rootfs`), run
  `pmbootstrap shutdown` and retry (re-registers the qemu binfmt).

## GPU (Adreno 512) — works
- Mesa freedreno reports **FD512** (hardware accel, not llvmpipe).
- Fix: `a512_zap.mbn` (Adreno 512 zap shader, extracted from the stock
  `vendor_a/firmware/a512_zap.elf`) added to `firmware-vsmart-zangyapro`.
- Render confirmed: `glmark2-es2-drm` -> GL_RENDERER=FD512, Mesa 26.1.1 (GLES 3.1),
  **glmark2 Score 512** (build 677 / texture 413 / shading 451 FPS), 3D visibly rendered on the
  panel. Headless: `EGL_PLATFORM=surfaceless` and `=device` both report freedreno/FD512, so the
  GPU is usable without a display (renderD128) for any future Wayland compositor.
- Cosmetic: an `a530_pm4.fw` early-load warning at boot; the deferred fallback load succeeds.

## Display panel (Himax HX83112A DJN 1080×2160) — works
The panel is a **DJN HX83112A** in a 1080×2160 command/video mode (the stock cmdline calls it
`qcom,mdss_dsi_hx83112a_djn_fhd_video`). The console runs through the real **DPU → DSI → panel**
pipeline (`card0-DSI-1`), not the bootloader simple-framebuffer.

Mainline already has `drivers/gpu/drm/panel/panel-himax-hx83112a.c` for the Fairphone 3's DJN
panel (1080×2340). It was extended into a **multi-variant** driver (panel-descriptor pattern,
like panel-himax-hx83102.c): the FP3 variant is kept byte-for-byte and a new
`djn,a1-hx83112a` variant adds the 1080×2160 mode (H fp40/bp12/pw4, V fp32/bp2/pw2, 60 Hz,
4-lane burst RGB888) plus a binding entry. Kernel changes are carried as patches in
[`../kernel/`](../kernel) (binding, driver, dts) and need
`CONFIG_DRM_PANEL_HIMAX_HX83112A=m` in the `linux-postmarketos-qcom-sdm660` config.

**Init strategy (important):** the stock bootloader fully programs the panel IC and the supplies
are always-on, so the `djn,a1-hx83112a` variant uses a **minimal init** (exit-sleep +
display-on) and **does not pulse reset** (`soft_reset = false`) — pulsing reset would wipe the
bootloader's register init and blank the panel. This lit the panel on the first try with no DCS
errors. The DSI supplies are vddio = L11A (1.8 V) and the LAB/IBB rails emulated by the
always-on `lcdb` fixed regulator (5.4 V); backlight is `pm660l_wled`; reset is gpio53.

The panel module is added to the device package's `modules-initfs` so it loads in the initramfs
alongside `msm`, bringing the display up early in boot. Verify on device:
`cat /sys/class/drm/card0-DSI-1/status` (→ connected), `.../modes` (→ 1080x2160),
`lsmod | grep hx83112a`, and the backlight under `/sys/class/backlight/*/brightness`.

## Soft reboot — most likely a low-power (brownout) issue, not a peripheral hang
Earlier symptom: `reboot` (or any soft reboot) -> bootloader -> pmOS splash -> black screen ->
hang; never reaches SSH, only a hold-Power cold boot recovered it. At the time this happened
**consistently** -- but always while the battery was draining on a weak (SDP, ~450 mA) charger
and it eventually died flat.

**Update: with a healthy battery (>90 %) on a 2 A wall charger, `reboot` AND `poweroff` both
complete normally and the device comes back up on its own.** So the "hang" was very likely a
**brownout / insufficient power during the warm reboot**, not the peripheral/reset-type theory
below. This also explains why the PS_HOLD HARD_RESET patch did not help (it addressed reset
type, not power). **Confirmed on the standard rebuild:** `sudo systemctl reboot` at 91 %
battery came back unattended (new boot_id, no power button), and WiFi/Tailscale/BT/GPU all
survived.

Practical guidance: power the device from a 2 A+ charger; a reboot on a weak/low battery may
still brown out. If a true hang ever recurs on a *charged* device, resume the old investigation:
verbose boot image (drop `quiet splash`, add `ignore_loglevel`) and read the panel at the hang.

Historical investigation (PS_HOLD theory, now believed not the cause):
- Restart handler: PSCI (prio 129) wins over PS_HOLD/msm-poweroff (prio 128).
- The PMIC pm660 PON PS_HOLD reset type was WARM_RESET (reg 0x85a=0x01). Patched qcom-pon.c to
  set HARD_RESET (0x85a=0x07, confirmed active) and bumped msm-poweroff priority 128->130 so
  PS_HOLD beats PSCI; `reboot` still hung, so reset type was not the cause. Both edits reverted.

## KNOWN ISSUE: touchscreen (Himax HX83112A) - WIP, parked
Only the **touch** half of the HX83112A is parked; the **display** half is done (see the panel
section above). The two are separate drivers: the panel is a DRM/DSI driver, the touch is a
separate i2c input driver.

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

## FIX: A/B boot-slot retry -> dropped to fastboot
A/B device. pmOS did not mark the slot successful, so the bootloader decremented slot_a retry
on each boot/power-cycle until it hit 0 -> slot unbootable -> dropped to fastboot (seen after the
battery drained flat and the device power-cycled). Recovery: `fastboot set_active a ; fastboot
reboot`. Permanent fix (baked in): added `qbootctl` to device-vsmart-zangyapro depends; its
qbootctl.service runs `qbootctl -m` at boot to mark the slot successful. Verified Successful=1
on slot _a.

## NOTE: charging works, but needs a strong charger (mainline pm660 charger)
Charger-type detection works (BC1.2): laptop/weak port -> SDP, input capped ~450 mA; a real fast
wall charger -> DCP, input 1.5 A. At 450 mA the running load (CPU+WiFi+BT, ~0.5 A) exceeds input
so the battery NET-DISCHARGES even while "Charging" (this is why it died plugged into a weak
port). On a 2 A+ DCP charger: current_max=1.5 A, battery current_now ~+1.15 A = charges fine
while running. Takeaway for the headless server: power it from a 2 A+ wall charger, never a
laptop/weak USB port.

## Device measurements (idle: WiFi+BT+console)
- Power draw ~2.4 W, measured as charger input power minus battery charge power
  (e.g. 1.41 A x 4.71 V in, 1.08 A x 3.98 V into battery -> 6.65 - 4.30 = 2.35 W). Heavy CPU
  load pushes it to ~4-5 W.
- Battery runtime on battery alone (built-in UPS): ~4.5 h from 100 %, ~3.5 h from 80 %
  (3000 mAh design, ~2.4 W idle). NOTE: indicative only - this is a used unit with a
  degraded (worn) battery, so real usable capacity is below 3000 mAh and these runtimes are
  optimistic; a healthy battery will differ.
- Charging: a weak/laptop SDP port is capped ~450 mA -> net discharge while running; a 2 A DCP
  wall charger gives ICL 1.5 A and ~1.1 A into the battery while running (charge ~40-55 %/h in
  the low-SoC region).
- Temps under charge + load: CPU 53-58 C, GPU ~57 C, SoC (pm660) ~55 C, battery ~44 C - all safe.
- Charger driver qcom_smbx DOES read constant-charge-current/voltage and voltage-max-design from
  the battery DT, but the defaults (ICL/FCC 1.5 A, CV 4.4 V from voltage-max-design) are already
  sensible, so no extra charge-limit DT fields were added (would be redundant).
- Battery percentage: the pmi8998_fg driver reads SoC straight from the FG hardware register
  (BATT_MONOTONIC_SOC); it does NOT use a DT OCV table, so adding `ocv-capacity-table` has no
  effect. After a flat discharge the % sticks/jumps until a full charge cycle recalibrates it.

## Protecting the local packages from apk
device/firmware/kernel are local builds, absent from any public repo, so
`apk upgrade -a|--available|--prune` will downgrade/remove them (it tried to downgrade the kernel
to the repo version that lacks this DTS). Mitigations applied on the device:
- All three pinned in /etc/apk/world (immune to --prune orphan removal).
- Operating rule: only ever run plain `apk upgrade` (never -a / --available / --prune).
- Full immunity would need a signed local repo on the device, or upstreaming to pmaports.

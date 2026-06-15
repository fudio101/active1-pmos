# Vsmart Active 1 (vsmart-zangyapro)

> Draft postmarketOS wiki page. Convert the infobox to `{{Infobox device|...}}` and the
> feature list to the wiki status template when publishing.

| | |
|---|---|
| Manufacturer | Vsmart |
| Name | Active 1 |
| Codename | vsmart-zangyapro |
| Released | 2018 |
| Type | handset |
| Chipset | Qualcomm Snapdragon 660 (SDM660) |
| CPU | Octa-core (4x2.2 GHz Kryo 260 Gold + 4x1.8 GHz Kryo 260 Silver) |
| GPU | Adreno 512 |
| Display | 1080 x 2160, Himax HX83112A (DJN) |
| RAM | 4 GB |
| Storage | 64 GB eMMC |
| Battery | 3000 mAh |
| Architecture | aarch64 |
| Original software | Android 9 |

## postmarketOS

| | |
|---|---|
| Category | testing |
| Pre-built images | no |
| Mainline | yes (shared `linux-postmarketos-qcom-sdm660`) |
| Kernel | 7.0.x |

The Vsmart Active 1 is a rebrand of the **BQ Aquaris X2 Pro** and is very close to the
**Xiaomi Mi A2 (jasmine)**; the port is derived from the latter. It is used here as a
small **headless home server**.

> **Note on verified boot:** the Vsmart bootloader enforces dm-android-verity and injects
> `skip_initramfs` / `dm=...android-verity...` into the kernel command line, which blocks
> Android GSIs. The mainline kernel ignores these parameters (they are passed to userspace),
> so postmarketOS boots without any verity workaround. **lk2nd is not required.**

## Feature status

| Feature | Status |
|---|---|
| Flashing | Works |
| Booting (fastboot boot / flashed boot) | Works |
| Internal storage (eMMC HS400) | Works |
| microSD slot | Enabled (not yet runtime-tested — no card on hand) |
| USB Networking | Works |
| USB OTG | Untested |
| Display (DRM DSI panel HX83112A DJN 1080×2160) | Works |
| Touchscreen (Himax HX83112A) | Parked (see Known issues) |
| WiFi (WCN3990) | Works |
| Bluetooth (WCN3990) | Works |
| GPU (Adreno 512, freedreno FD512) | Works (glmark2 score 512, renders 3D on the panel) |
| Charging (PM660) | Works (needs a ≥2 A charger; reporting WIP) |
| Battery percentage (PMI8998 FG) | Partial (recalibrates over a charge cycle) |
| A/B slot survival across reboots | Works (via `qbootctl`) |
| Soft / unattended reboot | Works on a healthy battery (earlier hangs were a low-power brownout) |
| Modem (calls/SMS/data) | Untested |

## Unlocking the bootloader

1. Enable **OEM unlocking** + USB debugging in Android developer options.
2. Reboot to fastboot (**Volume Down + Power**) and run:
   ```
   fastboot flashing unlock
   fastboot flashing unlock_critical
   ```
   (`fastboot oem unlock` is not supported on this bootloader.)

## How to enter flash mode

**Volume Down + Power** boots into fastboot mode.

## Installation

Follow the standard [Installation guide](https://wiki.postmarketos.org/wiki/Installation_guide).
The mainline kernel sidesteps the OEM verity, so a plain boot image works:

```
pmbootstrap init        # vendor: vsmart, device: zangyapro
pmbootstrap install
pmbootstrap flasher flash_kernel     # -> boot partition
pmbootstrap flasher flash_rootfs     # -> userdata
fastboot reboot
```

To test without flashing: `pmbootstrap flasher boot` (or `fastboot boot boot.img`).

**Flashing the rootfs over a 32-bit `fastboot.exe` (Windows):** large `fastboot flash userdata`
transfers fail on this stack ("Invalid sparse file format" / "Write to device failed"). Split
the raw image into ~20 MB sparse chunks (`img2simg` + `simg2simg ... 20000000`) and flash them
sequentially; a USB-2.0 hub improves stability.

## Running as a headless server

- **Power draw** (idle: WiFi + Bluetooth + console) is about **2.4 W**, measured from the
  charger input minus the battery charge power. Under heavy CPU load it rises to ~4-5 W.
- The 3000 mAh battery is effectively a **built-in UPS**: at idle it lasts roughly **~4.5 h
  from 100 %** (~3.5 h from 80 %) on battery alone during a power cut. **These figures are only
  indicative** — they were derived on a used unit whose battery is degraded (worn), so its real
  usable capacity is below the 3000 mAh design and the runtime computed from the design figure
  is optimistic; a device with a healthy battery will differ.
- **Charging needs a real ≥2 A wall charger.** BC1.2 detection works: a weak/laptop (SDP) port
  is capped at ~450 mA, which is *less* than the running load, so the battery slowly drains
  even while "Charging". A 2 A DCP charger pulls ~1.5 A and charges at ~1.1 A while running.
- **`qbootctl`** is a hard dependency of the device package; its service marks the active A/B
  slot "successful" at every boot. Without it, the bootloader counts down the slot retry
  counter on each power-cycle and eventually drops to fastboot (see Known issues).
- Connect over USB (`ssh user@172.16.42.1`) or WiFi/Tailscale. Bluetooth auto-starts at boot
  (BT keyboard at the console). See `docs/connecting.md`.

## Known issues

### Soft reboot — needs adequate power (earlier "hang" was a brownout)

Early on, `reboot` consistently hung after the splash (black screen, no SSH) and only a
hold-Power cold boot recovered it — but always while the battery was draining on a weak
(~450 mA) charger and eventually died flat. With a **healthy battery on a 2 A wall charger,
`reboot` and `poweroff` both complete normally** and the device comes back on its own. The
hang was therefore most likely a brownout during the warm reboot, not a driver issue (which is
why the PMIC PS_HOLD HARD_RESET patch did not help). Keep the device on a 2 A+ charger; a reboot
on a low/weak battery may still fail. See `docs/porting-notes.md`.

### Dropped to fastboot after running flat

A/B device: if the active slot is not marked "successful", the bootloader decrements its retry
counter every power-cycle and eventually declares it unbootable, landing in fastboot (typically
after the battery drains flat). Recovery: `fastboot set_active a && fastboot reboot`. This is
fixed permanently by the `qbootctl` dependency (above).

### Battery percentage is inaccurate after a flat discharge

The `pmi8998_fg` driver reads the state-of-charge directly from the fuel-gauge hardware
register; it does **not** use a DT OCV table, so adding `ocv-capacity-table` has no effect.
After the battery dies flat the FG loses its reference and the percentage sticks/jumps until a
full charge cycle recalibrates it. A proper fix would require loading the device battery
profile into the FG SRAM (mainline does not do this yet).

### WiFi MAC address is randomised

The WCN3990 has no MAC stored for mainline to read, so the WiFi interface gets a **random MAC on
every boot**. WiFi itself works; if you rely on DHCP reservations, pin a fixed MAC (e.g. a
NetworkManager `cloned-mac-address` setting or a systemd-networkd `.link` file).

### Touchscreen (Himax HX83112A) — Parked

The touch IC is a Himax HX83112A on i2c-0 (`c175000.i2c`) at address **0x48** (irq gpio67,
reset gpio66) and reports product id **0x83112a**. The mainline `himax_hx83112b` driver only
knows id `0x83112b`; a DT node with `compatible = "himax,hx83112a"` plus a matching chip
variant read the IC correctly but the wrong chip variant got bound and probe failed. Parked;
not needed for headless use.

## Notes

- The display works through the real DPU + DSI + panel pipeline using a mainline DRM panel
  driver. The mainline `panel-himax-hx83112a` (Fairphone 3, 1080×2340) was extended with a
  `djn,a1-hx83112a` 1080×2160 variant for this device; the bootloader inits the IC so the
  variant only does exit-sleep + display-on and skips reset. Only the in-cell touch is parked.
- WiFi/BT use the same WCN3990 as the Mi A2. The firmware (`board-2.bin`) lives in the rootfs
  (`firmware-vsmart-zangyapro`), so it is absent during `fastboot boot` probes.

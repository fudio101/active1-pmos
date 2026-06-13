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
| Architecture | aarch64 |
| Original software | Android 9 |

## postmarketOS

| | |
|---|---|
| Category | testing |
| Pre-built images | no |
| Mainline | yes (shared `linux-postmarketos-qcom-sdm660`) |
| Kernel | 6.19.x |

The Vsmart Active 1 is a rebrand of the **BQ Aquaris X2 Pro** and is very close to the
**Xiaomi Mi A2 (jasmine)**; the port is derived from the latter.

> **Note on verified boot:** the Vsmart bootloader enforces dm-android-verity and injects
> `skip_initramfs` / `dm=...android-verity...` into the kernel command line, which blocks
> Android GSIs. The mainline kernel ignores these parameters (they are passed to userspace),
> so postmarketOS boots without any verity workaround. **lk2nd is not required.**

## Feature status

| Feature | Status |
|---|---|
| Flashing | Works |
| Booting (fastboot boot / flashed boot) | Works |
| Internal storage (eMMC HS400, 50.5G root) | Works |
| USB Networking | Works |
| USB OTG | Untested |
| Display (console via simple-framebuffer) | Works |
| Display (DRM panel HX83112A) | WIP |
| Touchscreen (Himax in-cell) | Broken / WIP |
| Battery / charging (PM660) | Partial |
| WiFi (WCN3990) | Works |
| Bluetooth (WCN3990) | Works |
| Modem (calls/SMS/data) | Untested |
| GPU (Adreno 512, freedreno FD512) | Works (glmark2 score 512, 3D renders on panel) |
| Soft / unattended reboot | Broken (cold-boot only, see Known issues) |

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

## Mainline status

**Working:** CPU/SMP, eMMC (HS400), USB (gadget networking), framebuffer console, fastboot
boot, WiFi + Bluetooth (WCN3990), GPU (Adreno 512 via freedreno — glmark2 score 512, renders
3D on the panel and works headless via the render node).

**Partial:** charging (enabled by PMIC by default; battery reporting WIP).

**Not working / WIP:** DRM panel node (HX83112A not yet added — console uses the bootloader
framebuffer), touchscreen (Himax in-cell; no good mainline driver), modem, soft reboot.

## Known issues

### Soft / unattended reboot hangs (cold-boot only)

`reboot` (or any software-initiated reboot) restarts into the bootloader and the pmOS splash,
then the screen goes black and the boot hangs before SSH comes up. The only recovery is to
hold **Power** to force the device off and then power it on again (a cold boot), which always
works. This makes the device effectively **cold-boot-only** and blocks fully-headless reboots.

Diagnosis so far: a soft reboot performs a *warm* reset (CPUs restart but peripherals — eMMC,
remoteprocs, SMMU — keep their previous state), and the second boot hangs on that dirty
hardware; a real power cycle clears it. Forcing the PMIC (pm660) PON `PS_HOLD` reset type from
WARM_RESET to HARD_RESET (and making PS_HOLD outrank the PSCI restart handler) was tried and
**did not** fix it, so the reset *type* is not the (only) cause. `ramoops` is wiped by the
forced cold boot, so the hang is not captured. Next step: boot a verbose image (drop
`quiet splash`, add `ignore_loglevel`) and read the panel at the hang to localise the stuck
driver. See `docs/porting-notes.md` for the full write-up.

## Notes

- Touch is in-cell with the HX83112A panel; mainline support is limited and not needed for
  a headless server use case.
- WiFi/BT use the same WCN3990 as the Mi A2; expected to work once firmware/calibration is
  in place (firmware lives in the rootfs, so it is absent during `fastboot boot` probes).

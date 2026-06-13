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
| Internal storage (eMMC HS400) | Works |
| USB Networking | Works |
| USB OTG | Untested |
| Display (console via simple-framebuffer) | Works |
| Display (DRM panel HX83112A) | WIP |
| Touchscreen (Himax in-cell) | Broken / WIP |
| Battery / charging (PM660) | Partial |
| WiFi (WCN3990) | Untested |
| Bluetooth (WCN3990) | Untested |
| Modem (calls/SMS/data) | Untested |
| GPU (Adreno 512) | Untested |

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

**Working:** CPU/SMP, eMMC (HS400), USB (gadget networking), framebuffer console, fastboot boot.

**Partial:** charging (enabled by PMIC by default; battery reporting WIP).

**Not working / WIP:** DRM panel (HX83112A node not yet added), touchscreen (Himax in-cell;
no good mainline driver), WiFi/BT (WCN3990 firmware/calibration), modem, GPU.

## Notes

- Touch is in-cell with the HX83112A panel; mainline support is limited and not needed for
  a headless server use case.
- WiFi/BT use the same WCN3990 as the Mi A2; expected to work once firmware/calibration is
  in place (firmware lives in the rootfs, so it is absent during `fastboot boot` probes).

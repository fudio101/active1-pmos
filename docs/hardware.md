# Vsmart Active 1 (zangyapro) hardware reference

SoC **Qualcomm SDM660**, PMIC **PM660 + PM660L**, A/B partitions, eMMC.
Nearly identical to the **Xiaomi Mi A2 (jasmine)** — `sdm660-xiaomi-jasmine.dts` is the base.

## Core blocks (confirmed working on the port)
| Block | Status | Notes |
|---|---|---|
| CPU | OK | 8 cores, aarch64 |
| RAM | OK | 3.67 GB usable (4 GB part) |
| eMMC | OK | HS400, 58.2 GiB, `mmcblk1`, controller `c0c4000.mmc` |
| USB | OK | NCM gadget; host 172.16.42.2, phone 172.16.42.1 |
| Framebuffer console | OK | `simple-framebuffer` @ 0x9d400000, 1080x2160 a8r8g8b8 |
| Charger / battery | OK | `pm660-charger` + `qcom-battery` (PMI8998 FG); needs a >=2 A charger |

## Peripherals (status + reference values)
Stock values were read from the stock dtb (`/tmp/dtbs`). See `porting-notes.md` for the
bring-up details and the open items.
| Block | Reference values | Status |
|---|---|---|
| WiFi/BT | `qca,wcn3990` + `qcom,icnss`; firmware `board-2.bin` (ath10k WCN3990) | **Works** (firmware ships in `firmware-vsmart-zangyapro`; absent during `fastboot boot`). MAC is random. |
| GPU | Adreno 512; zap shader `a512_zap.mbn` (from stock `vendor_a/firmware/a512_zap.elf`) | **Works** (freedreno FD512); firmware in `firmware-vsmart-zangyapro`. |
| Panel | "DJN hx83112a 1080p video mode" | Console via simplefb works; **DRM DSI panel node not wired up** (the mainline HX83112A driver targets a 2340-line variant). |
| Touch | Himax **HX83112A** TDDI, i2c-0 @ **0x48**, irq gpio67, rst gpio66, product id **0x83112a** | **WIP / parked** — mainline `himax_hx83112b` only knows id 0x83112b; needs an hx83112a variant. |
| Fingerprint | `goodix,fingerprint` | Not needed |

## Verified boot / why pmOS boots and Android GSIs don't
The Vsmart bootloader injects into the cmdline:
```
root=/dev/dm-0 dm="system none ro,0 1 android-verity /dev/mmcblk0p15" skip_initramfs androidboot.veritymode=enforcing
```
The mainline kernel logs:
```
Unknown kernel command line parameters "skip_initramfs ... dm=android-verity ...", will be passed to user space
```
i.e. it ignores them, uses its own initramfs and mounts the pmOS rootfs. No android-verity,
no lk2nd required.

## Partition mapping (Android name -> pmOS use)
- `boot` (boot_a/_b): pmOS boot image.
- `userdata` (~53 GB): pmOS rootfs image (carries its own /boot and / subpartitions).
- Stock backups (FileSell fastboot package + EDL package) are kept to restore Android.

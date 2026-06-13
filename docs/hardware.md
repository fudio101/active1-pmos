# Vsmart Active 1 (zangyapro) hardware reference

SoC **Qualcomm SDM660**, PMIC **PM660 + PM660L**, A/B partitions, eMMC.
Nearly identical to the **Xiaomi Mi A2 (jasmine)** — `sdm660-xiaomi-jasmine.dts` is the base.

## Confirmed working (probe: jasmine kernel via `fastboot boot`)
| Block | Status | Notes |
|---|---|---|
| CPU | OK | 8 cores, aarch64 |
| RAM | OK | 3.67 GB usable (4 GB part) |
| eMMC | OK | HS400, 58.2 GiB, `mmcblk1`, controller `c0c4000.mmc` |
| USB | OK | NCM gadget; host 172.16.42.2, phone 172.16.42.1 |
| Framebuffer console | OK | `simple-framebuffer` @ 0x9d400000, 1080x2160 a8r8g8b8 |
| Charger / battery | OK | `pm660-charger` + `qcom-battery` |

## To do (iteration 2) — values from the stock dtb (`/tmp/dtbs`, 111 dtbs)
| Block | Stock value | Mainline plan |
|---|---|---|
| WiFi/BT | `qca,wcn3990` + `qcom,icnss` | Same as jasmine; node already present. Needs firmware (in rootfs), so absent during `fastboot boot`. Likely works after a full install; calibration/MAC may need a partition. |
| Panel | "DJN hx83112a 1080p video mode" | Driver `panel-himax-hx83112a.c` exists; add the panel node + DJN timings. (Console already works via simplefb.) |
| Touch | `himax,hxcommon` in-cell, irq-gpio 67, rst-gpio 66 | Weak mainline Himax touch support; not needed for a headless server. |
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

# Flashing faster (and less often)

Findings from 2026-10-09. The phone was off at the time, so items marked *untested* still need a
run on the device.

## The problem

On this phone (and many Qualcomm devices, especially SDM660/636), the **bootloader's (ABL)
fastboot** does not get along with many USB 3 / xHCI host ports. The phone is not detected, the
connection drops mid-flash, or you get `Write to device failed`. The usual workaround, and the one
used here, is a USB 2.0 port or hub. On Windows there is a registry `usbflags` hack
(`osvc`, `SkipBOSDescriptorQuery`, `SkipContainerIdQuery` for `18D1D00D0100`). macOS has no
host-side fix.

The bug is in **ABL fastboot, not in Linux**, so the strategy is to use fastboot as little as
possible.

## 1. Updating packages: skip fastboot entirely

`deviceinfo_flash_kernel_on_update="true"` means that installing a kernel apk *on the device*
rewrites the boot partition by itself. Kernel, device and firmware updates do not need a reflash,
and the rootfs and its state (Home Assistant, WiFi, Tailscale) stay untouched.

```bash
# keep a rollback first: the boot.img that currently boots
cp -L <export>/boot.img build-output/boot-known-good.img   # or the previous export

scp linux-postmarketos-qcom-sdm660-<ver>.apk phone-ha:/tmp/
ssh phone-ha 'sudo apk add /tmp/linux-postmarketos-qcom-sdm660-<ver>.apk && sudo reboot'
```

Built apks are in `~/.local/var/pmbootstrap/packages/*/aarch64/` inside the VM.

**Rollback:** if the new kernel does not boot, run
`fastboot flash boot build-output/boot-known-good.img` (about 24 MB, a few seconds even through the
hub).

Never use `apk upgrade -a` (see CLAUDE.md / cheatsheet). `apk add ./file.apk` of the pinned
package is fine.

## 2. Full reflash: send a sparse image

The rootfs image is mostly empty space. Measured on the 2026-10 image:

| | size |
|---|---|
| raw `vsmart-zangyapro.img` | 1,478,492,160 B (1.48 GB) |
| `img2simg` sparse | 713,549,852 B (714 MB, about 48 %) |

Ways to produce it:

- `pmbootstrap install --sparse` (the option is in `pmb/install/_install.py`; it runs `img2simg` in
  the native chroot), or
- `deviceinfo_flash_sparse="true"` in deviceinfo. Not set today; this would change the upstream
  device package, so it should be a deliberate decision.

*Untested:* recent `fastboot` / libsparse may already skip zero blocks when it re-sparses a large
raw image, so the real speedup could be anywhere from negligible to about 2×. Time both ways once.

## 3. Bypass ABL fastboot for the rootfs: USB mass storage (*untested*)

The pmOS/Nura initramfs can expose a block device as a USB mass-storage disk through configfs:

- kernel cmdline `pmos.debug-shell` and `pmos.usb-storage=<block device>`, or
- in the debug shell: `setup_usb_storage_configfs /dev/<device>`.

Steps:

1. `fastboot boot boot.img` with that cmdline. Only about 24 MB goes over the hub.
2. The phone appears on the Mac as a disk. USB is now driven by Linux's dwc3 gadget, not ABL, so
   a **direct USB-C port may work** without the hub.
3. `dd` the **raw** image onto it (`diskutil list`, then `sudo dd if=vsmart-zangyapro.img
   of=/dev/rdiskN bs=4m`). Triple-check `N`.

Still open: the exact userdata device path in the initramfs (for example
`/dev/disk/by-partlabel/userdata` or `/dev/mmcblk1pNN`), whether the debug-shell telnet and the
mass-storage function coexist, and the actual throughput.

## 4. Check the hub itself

USB 2.0 High-Speed is 480 Mbit/s, roughly 25–35 MB/s for fastboot, so a 1.48 GB flash takes about
a minute. Much slower than that suggests a Full-Speed (USB 1.1, 12 Mbit/s) hub or a bad cable.
To check:

- fastboot's `Sending sparse 'userdata' 1/N (… KB) OKAY [ x.xxxs]` lines give MB/s directly;
- `system_profiler SPUSBHostDataType` while the phone is attached shows the negotiated speed.

## Sources

- https://forum.sailfishos.org/t/failed-sailfish-flashing-fastboot-device-not-detected/6175
- https://community.e.foundation/t/howto-fix-fastboot-when-using-windows-10-usb-3/33982
- https://forums.ubports.com/post/63528
- https://droidwin.com/fix-mi-flash-tool-cannot-detect-device-in-fastboot-mode/
- https://droidwin.com/?p=11188 ("Write to device failed (no link)")
- https://community.st.com/stm32-mcus-embedded-software-32/usb-comms-failure-with-apple-silicon-arm-mac-125047
- initramfs `init_functions.sh` in pmaports (`setup_usb_storage_configfs`, `pmos.usb-storage`)

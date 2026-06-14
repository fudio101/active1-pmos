# postmarketOS for the Vsmart Active 1 (zangyapro)

A postmarketOS / mainline-Linux port for the **Vsmart Active 1** (PQ6001, codename
**zangyapro**, Qualcomm **SDM660**), aimed at running it as a **headless home server**.

The Vsmart Active 1 is a rebrand of the **BQ Aquaris X2 Pro** and is very close to the
**Xiaomi Mi A2 (jasmine)**, so the port is derived from the jasmine device tree.

**Why this works where Android GSIs fail:** the Vsmart bootloader enforces dm-android-verity
and injects `skip_initramfs` + `dm=...android-verity...` into the kernel cmdline. The mainline
kernel ignores those (they are passed to userspace), so it boots its own initramfs and mounts
the pmOS rootfs without ever touching android-verity. No lk2nd needed.

## Status

Running as a **headless home server**. Working: boot (eMMC HS400), USB + WiFi networking,
Bluetooth, **GPU** (Adreno 512 / freedreno), SSH, framebuffer console, charging (with a ≥2 A
charger), and A/B-slot survival across reboots (`qbootctl`). Soft reboot — once thought broken
— works on a healthy battery (the earlier hangs were a low-power brownout). Known issue: the
touchscreen is parked. See
[`docs/porting-notes.md`](docs/porting-notes.md), [`docs/hardware.md`](docs/hardware.md),
[`docs/connecting.md`](docs/connecting.md) and [`docs/cheatsheet.md`](docs/cheatsheet.md).

## Layout (mirrors upstream paths)

```
dev.sh                                              # build/flash/ssh helper
pmaports/device/testing/device-vsmart-zangyapro/   # device package -> copy into pmaports
  APKBUILD  deviceinfo  modules-initfs
kernel/
  sdm660-vsmart-zangyapro.dts                       # device tree (edit here)
  sdm660-xiaomi-jasmine.dts                         # upstream template (reference)
  *.patch                                           # kernel patch for upstreaming
wiki/Vsmart_Active_1.md                             # postmarketOS wiki page draft
docs/hardware.md  docs/porting-notes.md
build-output/                                       # boot image + build logs (gitignored)
scripts/                                            # one-off scripts used during bring-up
```

## Quick start (Linux/macOS, WSL works)

```bash
./dev.sh setup                              # install deps, clone pmbootstrap + kernel
(cd ~/pmbootstrap && ./pmbootstrap.py init) # vendor: any, will be overridden by sync
./dev.sh all                                # sync -> build kernel -> install -> export
# put the phone in fastboot (Volume Down + Power), then:
./dev.sh flash                              # flash boot + userdata + reboot
./dev.sh ssh                                # ssh fudio101@172.16.42.1 (password 147147)
```

Run `./dev.sh` with no arguments for the full command list. Dev loop:
**edit `kernel/sdm660-vsmart-zangyapro.dts` → `./dev.sh all` → `./dev.sh flash`.**

## Configuration

`fudio101` / `147147` throughout this repo are just the original porter's example credentials.
The **device login user and password are chosen when you run `pmbootstrap init`** — pick your
own there.

To point the `./dev.sh` helpers at your own values without editing the tracked script, copy
[`dev.config.example`](dev.config.example) to `dev.config` (gitignored) and set `SSH_USER`,
`PASS`, `PHONE_IP`, `FASTBOOT`, etc. (or just export them as env vars). Other defaults live at
the top of `dev.sh`: device `vsmart-zangyapro`, console UI, SSH enabled, kernel 6.19.x.

> The `maintainer=` field in the APKBUILDs is package metadata (who maintains the package
> upstream) and stays `fudio101` — you do not change it just by building, only if you take over
> maintenance.

## Upstreaming / publishing

The port is two upstream contributions, in order:

1. **Kernel device tree** — submit `kernel/0001-arm64-dts-qcom-sdm660-add-vsmart-active1.patch`
   to the SDM660 kernel tree ([sdm660-mainline/linux](https://github.com/sdm660-mainline/linux))
   and/or mainline. The pmaports kernel package builds from a release tarball, so the `.dts`
   must land there first. The patch already carries a proper subject + `Signed-off-by`.
2. **pmaports packages** — once a kernel tag ships the dtb, copy
   `pmaports/device/testing/device-vsmart-zangyapro/` and
   `pmaports/device/testing/firmware-vsmart-zangyapro/` into a
   [pmaports](https://gitlab.postmarketos.org/postmarketOS/pmaports) checkout and open a merge
   request (follow `COMMITSTYLE.md` there). `firmware-vsmart-zangyapro` ships the device-specific
   binary blobs (WCN3990 `board-2.bin`, Adreno 512 `a512_zap.mbn`).
3. **Wiki** — publish `wiki/Vsmart_Active_1.md`.

## Environment notes

- Native Linux/macOS: `fastboot` works directly (install `android-tools`).
- WSL: the phone's USB is on the Windows side, so flash with
  `FASTBOOT=/mnt/c/adb/fastboot.exe ./dev.sh flash` (or set up usbipd-win). Building works
  normally inside WSL.

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

Active 1 has been **confirmed to boot mainline Linux** (eMMC HS400, USB networking, framebuffer
console, charging). A dedicated `vsmart-zangyapro` device is being packaged. See
[`docs/porting-notes.md`](docs/porting-notes.md) and [`docs/hardware.md`](docs/hardware.md).

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

Defaults (editable at the top of `dev.sh`): device `vsmart-zangyapro`, user `fudio101`,
password `147147`, hostname `vsmart-zangyapro`, console UI, SSH enabled, kernel 6.19.x.

## Upstreaming / publishing

- **Device package:** copy `pmaports/device/testing/device-vsmart-zangyapro/` into a
  [pmaports](https://gitlab.postmarketos.org/postmarketOS/pmaports) checkout and open a merge
  request (see `COMMITSTYLE.md` / `docs/packaging-guidelines.md` there).
- **Kernel:** submit `kernel/*.patch` to the SDM660 kernel tree.
- **Wiki:** publish `wiki/Vsmart_Active_1.md`.

## Environment notes

- Native Linux/macOS: `fastboot` works directly (install `android-tools`).
- WSL: the phone's USB is on the Windows side, so flash with
  `FASTBOOT=/mnt/c/adb/fastboot.exe ./dev.sh flash` (or set up usbipd-win). Building works
  normally inside WSL.

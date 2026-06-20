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
Bluetooth, **GPU** (Adreno 512 / freedreno), **DSI display** (Himax HX83112A DJN 1080×2160, real
DPU+DSI panel console), SSH, charging (with a ≥2 A charger), and A/B-slot survival across
reboots (`qbootctl`). Soft reboot — once thought broken — works on a healthy battery (the
earlier hangs were a low-power brownout). Known issue: the touchscreen is parked. See
[`docs/porting-notes.md`](docs/porting-notes.md), [`docs/hardware.md`](docs/hardware.md),
[`docs/connecting.md`](docs/connecting.md) and [`docs/cheatsheet.md`](docs/cheatsheet.md).

## Layout (mirrors upstream paths)

```
dev.sh                                              # build/flash/ssh helper
pmaports/device/testing/device-vsmart-zangyapro/   # device package -> copy into pmaports
  APKBUILD  deviceinfo  modules-initfs
pmaports/device/testing/firmware-vsmart-zangyapro/
  APKBUILD                                          # firmware pkg (board-2.bin fetched from vendor-blobs/)
vendor-blobs/                                       # proprietary blobs with no public mirror
  board-2.bin                                       # WCN3990 RF-calibration (self-hosted, see README inside)
  README.md                                         # provenance + update instructions for all blobs
kernel/
  sdm660-vsmart-zangyapro.dts                       # device tree (edit here)
  sdm660-xiaomi-jasmine.dts                         # upstream template (reference)
  *.patch                                           # kernel patch for upstreaming
wiki/Vsmart_Active_1.wiki                            # source for the live wiki page
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

1. **Kernel** — the 4-patch series in [`kernel/`](kernel) (panel binding → driver → board binding
   → dts) **merged 2026-06-20** into `qcom-sdm660-7.0.y` as
   **[sdm660-mainline/linux#186](https://github.com/sdm660-mainline/linux/pull/186)**
   (branch `fudio101/vsmart-active1-7.0`; superseded #185 on EOL 6.19.y). First
   developed/tested on `v6.19.10-sdm660`; all patches pass `checkpatch`, `dt_binding_check` and
   `dtbs_check` clean on 7.0.y (the one dts `checkpatch` warning is the usual MAINTAINERS
   false-positive; `Assisted-by` tag clean under 7.0.y's checkpatch). The pmaports kernel package
   builds from a release tarball; 7.0.y has **no release tag yet**, so pmaports stays on
   `--src ~/linux-sdm660` until the **`v7.0.x-sdm660` tag is cut**.
2. **pmaports** — staged under [`pmaports-mr/`](pmaports-mr). Blocked on the
   **`v7.0.x-sdm660` tag** (device dtb + HX83112A panel driver only ship in that release
   tarball). Three commits to apply once the tag lands:
   - `device/testing/linux-postmarketos-qcom-sdm660`: enable
     `CONFIG_DRM_PANEL_HIMAX_HX83112A=m` and bump `_pkgver`/`_tag` to the new sdm660 tag.
   - `device/testing/device-vsmart-zangyapro/` — the device package
     (mirrored at `pmaports/device/testing/device-vsmart-zangyapro/`).
   - `device/testing/firmware-vsmart-zangyapro/` — device firmware pkg. `board-2.bin` (WCN3990
     RF-calibration) is self-hosted in `vendor-blobs/` (excluded from the MR) and fetched via
     raw GitHub URL; `a512_zap.mbn` (Adreno 512 zap) fetched from TheMuppets; `firmware-5.bin`
     (WCN3990 feature descriptor) generated at build by `ath10k-fwencoder` — not a blob.

   Copy these into a [pmaports](https://gitlab.postmarketos.org/postmarketOS/pmaports) checkout
   and open a merge request following its `COMMITSTYLE.md` (GitLab — needs `glab`/GitLab auth,
   not `gh`). See [`pmaports-mr/README.md`](pmaports-mr) for exact steps.
3. **Wiki** — published at **[wiki.postmarketos.org/wiki/Vsmart_Active_1_(vsmart-zangyapro)](https://wiki.postmarketos.org/wiki/Vsmart_Active_1_(vsmart-zangyapro))**. Source kept at [`wiki/Vsmart_Active_1.wiki`](wiki/Vsmart_Active_1.wiki).

## Environment notes

- Native Linux/macOS: `fastboot` works directly (install `android-tools`).
- WSL: the phone's USB is on the Windows side, so flash with
  `FASTBOOT=/mnt/c/adb/fastboot.exe ./dev.sh flash` (or set up usbipd-win). Building works
  normally inside WSL.

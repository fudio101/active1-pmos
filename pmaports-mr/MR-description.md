Adds the Vsmart Active 1 (PQ6001, `vsmart-zangyapro`), a 2018 Qualcomm SDM660 handset, to
`device/testing/`.

The kernel side is already upstream: the panel driver, its binding and the device dts were merged
into `qcom-sdm660-7.0.y` as [sdm660-mainline/linux#186][pr] and ship in `v7.0.14-sdm660`, which
this repo has packaged since 263089a0. Only the Kconfig symbol was still off.

[pr]: https://github.com/sdm660-mainline/linux/pull/186

### Commits

1. **`linux-postmarketos-qcom-sdm660: enable HX83112A panel driver`** — @alexeymin, this one is
   yours, so it is deliberately minimal: one Kconfig line plus `pkgrel`. `pkgver` is untouched.

   The change is additive — it builds one extra module, `panel-himax-hx83112a.ko`, which binds
   only to `djn,*-hx83112a` compatibles. No other sdm660 device tree references those, and no
   shared symbol is touched, so the other SDM660 devices see nothing but a `pkgrel` bump. Happy to
   test on any other sdm660 device you'd like covered.

   Thank you for the 7.0.14 bump in !9224 — that is what unblocked this.

2. **`vsmart-zangyapro: new device`** — device + firmware packages, in one commit per
   `COMMITSTYLE.md`.

### Firmware

`firmware-vsmart-zangyapro` carries only what genuinely cannot be built or sourced from
`linux-firmware`:

- **`board-2.bin`** — WCN3990 ath10k RF calibration, extracted from the device's stock vendor
  partition. `linux-firmware`'s file of the same name is a different table targeting sdm845
  boards; on SDM660 its `qmi-board-id=ff` entry carries the wrong RF data and triggers an MSS
  watchdog crash (#3803). This blob has no upstream home, so it is fetched from a
  **commit-pinned** raw URL — immutable, same approach as the TheMuppets pin below. Provenance
  and re-extraction instructions are documented in the APKBUILD.
- **`a512_zap.mbn`** — Adreno 512 zap shader, byte-identical across SDM660 devices, from
  TheMuppets `proprietary_vendor_xiaomi_wayne-common` at a pinned commit.
- **`firmware-5.bin`** is *not* a blob — it is generated at build time by `ath10k-fwencoder`, the
  same invocation whyred and tulip use.

### Testing

Boot-tested on the device — display, GPU, WiFi, Bluetooth, USB networking and charging all come
up; it runs as a headless server. Touch is not wired up yet, which is why the device stays in
`testing`. Local validation before pushing: `pmbootstrap kconfig check` passes, the kernel builds
from the release tarball (not `--src`), and `panel-himax-hx83112a.ko` plus
`boot/dtbs/qcom/sdm660-vsmart-zangyapro.dtb` are both confirmed present in the resulting apk.

Wiki: https://wiki.postmarketos.org/wiki/Vsmart_Active_1_(vsmart-zangyapro)

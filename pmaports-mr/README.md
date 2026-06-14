# pmaports MR staging — Vsmart Active 1

Step 2 of upstreaming (see [`../README.md`](../README.md#upstreaming--publishing)). pmaports
lives on **GitLab**, so this is a `glab` / GitLab merge request, not a `gh` PR.

> **Blocked on the kernel.** The kernel series is submitted as
> [sdm660-mainline/linux#185](https://github.com/sdm660-mainline/linux/pull/185). This MR can
> only be built/submitted once #185 **merges and a new `vX.Y.Z-sdm660` tag** is cut that ships
> the device dts **and** the HX83112A panel driver — the pmaports kernel package builds from a
> release tarball, not from patches. Until then the device builds locally via `./dev.sh build`
> (which uses `--src ~/linux-sdm660`).

## The three changes (one commit each — follow pmaports `COMMITSTYLE.md`)

### 1. `device/testing/linux-postmarketos-qcom-sdm660/` (shared SoC kernel)
- Bump `pkgver` to the new tag, e.g. `6.19.11`, so `_tag="v$pkgver-sdm660"` pulls the tarball
  that now contains the new dts + panel driver. (`pkgrel` resets to `0` on a `pkgver` bump.)
- Enable the panel in `config-postmarketos-qcom-sdm660.aarch64` — see
  [`linux-config.diff`](linux-config.diff): `CONFIG_DRM_PANEL_HIMAX_HX83112A=m`.
- `pmbootstrap kconfig check linux-postmarketos-qcom-sdm660`, then
  `pmbootstrap checksum linux-postmarketos-qcom-sdm660`.
- Commit: `linux-postmarketos-qcom-sdm660: enable Himax HX83112A panel, bump to v6.19.11-sdm660`

### 2. `device/testing/device-vsmart-zangyapro/` (new device)
- Copy from [`../pmaports/device/testing/device-vsmart-zangyapro/`](../pmaports/device/testing/device-vsmart-zangyapro).
- Reset `pkgrel=0` for the initial upstream submission (local iteration left it at 5).
- `modules-initfs` already lists `panel-himax-hx83112a` so the display comes up in the initramfs.
- Commit: `device-vsmart-zangyapro: new device`

### 3. `device/testing/firmware-vsmart-zangyapro/` (new firmware)
- Copy from [`../pmaports/device/testing/firmware-vsmart-zangyapro/`](../pmaports/device/testing/firmware-vsmart-zangyapro).
- Ships the device blobs: WCN3990 `board-2.bin` (WiFi) + Adreno 512 `a512_zap.mbn` (GPU zap).
- Commit: `firmware-vsmart-zangyapro: new firmware`

## Submit

```bash
glab auth login                                    # GitLab token (one-time)
glab repo fork postmarketOS/pmaports --clone       # or clone your existing fork
cd pmaports && git checkout -b vsmart-active1
# apply the three changes above, commit each per COMMITSTYLE.md
pmbootstrap build device-vsmart-zangyapro          # sanity-build from the MR tree (needs the new tag)
git push -u origin vsmart-active1
glab mr create --source-branch vsmart-active1 --target-branch master \
  --title "device-vsmart-zangyapro: new device" --fill
```

## Notes
- Keep the device in `device/testing/` until it has a second independent tester.
- Touch is intentionally not included (parked — see `../docs/porting-notes.md`).

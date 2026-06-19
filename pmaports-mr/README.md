# pmaports MR staging — Vsmart Active 1

Step 2 of upstreaming (see [`../README.md`](../README.md#upstreaming--publishing)). pmaports
lives on **GitLab**, so this is a `glab` / GitLab merge request, not a `gh` PR.

> **Blocked on the kernel.** The kernel series is submitted as
> [sdm660-mainline/linux#186](https://github.com/sdm660-mainline/linux/pull/186) (base
> `qcom-sdm660-7.0.y`; #185 on 6.19.y was closed since that branch is EOL). This MR can only be
> built/submitted once #186 **merges and a `v7.0.x-sdm660` tag is cut** that ships the device dts
> **and** the HX83112A panel driver — the pmaports kernel package builds from a release tarball, not
> from patches. **Note: 7.0.y has no tag yet**, so this is gated on the maintainer cutting the first
> 7.0 release. Until then the device builds locally via `./dev.sh build` (`--src ~/linux-sdm660`,
> now on the 7.0.y branch).

## Two commits (per pmaports `COMMITSTYLE.md` — new device + firmware in same commit)

### Commit 1: shared SoC kernel (gated on v7.0.x-sdm660 tag)
Package: `device/testing/linux-postmarketos-qcom-sdm660/`
- Bump `pkgver` to the new 7.0 tag (e.g. `7.0.0`); `_tag="v$pkgver-sdm660"` pulls the tarball
  that ships the new dts + HX83112A panel driver. (`pkgrel` resets to `0` on a `pkgver` bump.)
  This also moves pmaports off the EOL 6.19 kernel.
- Enable the panel in `config-postmarketos-qcom-sdm660.aarch64` — see
  [`linux-config.diff`](linux-config.diff): `CONFIG_DRM_PANEL_HIMAX_HX83112A=m`.
- `pmbootstrap kconfig check linux-postmarketos-qcom-sdm660`, then
  `pmbootstrap checksum linux-postmarketos-qcom-sdm660`.
- **Commit message:** `linux-postmarketos-qcom-sdm660: enable Himax HX83112A panel, bump to v7.0.x-sdm660`

### Commit 2: new device + firmware (one commit per COMMITSTYLE)
Packages: `device/testing/device-vsmart-zangyapro/` + `device/testing/firmware-vsmart-zangyapro/`
- Copy device pkg from [`../pmaports/device/testing/device-vsmart-zangyapro/`](../pmaports/device/testing/device-vsmart-zangyapro) — reset `pkgrel=0`.
- Copy firmware pkg from [`../pmaports/device/testing/firmware-vsmart-zangyapro/`](../pmaports/device/testing/firmware-vsmart-zangyapro) — `pkgrel=0`.
  Ships: WCN3990 `board-2.bin` (WiFi, committed blob — not found in any upstream source) +
  Adreno 512 `a512_zap.mbn` (fetched from TheMuppets wayne-common, pinned commit `785f4c95`) +
  `firmware-5.bin` (WCN3990 feature descriptor, committed).
- `modules-initfs` lists `panel-himax-hx83112a` so the display comes up in the initramfs.
- **Commit message:** `vsmart-zangyapro: new device`

## Submit

```bash
glab auth login                                    # GitLab token (one-time)
glab repo fork postmarketOS/pmaports --clone       # or clone your existing fork
cd pmaports && git checkout -b vsmart-active1
# apply commit 1 (kernel bump + panel config), then commit 2 (device + firmware together)
pmbootstrap build device-vsmart-zangyapro          # sanity-build from the MR tree (needs the new tag)
git push -u origin vsmart-active1
glab mr create --source-branch vsmart-active1 --target-branch master \
  --title "vsmart-zangyapro: new device" --fill
```

## Notes
- Keep the device in `device/testing/` until it has a second independent tester.
- Touch is intentionally not included (parked — see `../docs/porting-notes.md`).

## Checklist — When PR #186 Merges

```
[ ] Tag v7.0.x-sdm660 is cut
[ ] Pull latest pmaports checkout
[ ] pmaports-mr commit 1: update _tag + enable panel config (see Section 1 above)
[ ] pmbootstrap kconfig check linux-postmarketos-qcom-sdm660
[ ] pmbootstrap checksum linux-postmarketos-qcom-sdm660
[ ] glab auth login (GitLab personal access token)
[ ] Fork + clone postmarketOS/pmaports on GitLab (see Submit section above)
[ ] Apply 2 commits (commit 1: kernel; commit 2: device+firmware together), push branch vsmart-active1
[ ] glab mr create --title "vsmart-zangyapro: new device" --fill
[x] Wiki published: https://wiki.postmarketos.org/wiki/Vsmart_Active_1_(vsmart-zangyapro)
```

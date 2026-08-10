# pmaports MR staging — Vsmart Active 1

Step 2 of upstreaming (see [`../README.md`](../README.md#upstreaming--publishing)). pmaports
lives on **GitLab**, so this is a `glab` / GitLab merge request, not a `gh` PR. The target branch
is **`main`**.

> **Unblocked.** [sdm660-mainline/linux#186](https://github.com/sdm660-mainline/linux/pull/186)
> merged 2026-06-20 into `qcom-sdm660-7.0.y`, and the release tag **`v7.0.14-sdm660`** was cut
> 2026-08-02. The kernel package maintainer then bumped pmaports to 7.0.14 himself in
> [!9224](https://gitlab.postmarketos.org/postmarketOS/pmaports/-/merge_requests/9224) (commit
> `263089a0`, 2026-08-06) — his commit message lists this device and links our wiki page as the
> motivation. So the dts and the HX83112A driver **already ship in the packaged kernel**; all
> that is left is switching the panel driver on.

## Two commits (per pmaports `COMMITSTYLE.md` — new device + firmware in same commit)

### Commit 1: enable the panel in the shared SoC kernel

Package: `device/testing/linux-postmarketos-qcom-sdm660/` — **not ours**, maintained by
Alexey Minnekhanov. Keep the diff minimal.

- `CONFIG_DRM_PANEL_HIMAX_HX83112A=m` in `config-postmarketos-qcom-sdm660.aarch64`
  (see [`linux-config.diff`](linux-config.diff)).
- `pkgrel` 0 → 1. **Do not touch `pkgver`** — 7.0.14 is already upstream. Bumping it would send
  reviewers chasing a version that does not exist.
- You *must* edit the APKBUILD. pmaports CI derives build jobs only from changed `APKBUILD`
  files, so a config-only MR produces a green pipeline that compiled nothing.
- Prefer a **plain text edit over `pmbootstrap kconfig edit`**: menuconfig rewrites
  `CC_VERSION_TEXT` / `CLANG_VERSION` / `AS_VERSION` / `LLD_VERSION` / `PAHOLE_VERSION` against
  your local toolchain, turning a 1-line diff into a dozen lines of noise. The symbol's
  dependencies (`OF`, `DRM_MIPI_DSI`, `BACKLIGHT_CLASS_DEVICE`, `DRM_KMS_HELPER`) are all already
  enabled, so `syncconfig` cannot silently drop it.
- Then `pmbootstrap checksum linux-postmarketos-qcom-sdm660` (the config's sha512 changes; the
  tarball's must not).
- **Commit message:** `linux-postmarketos-qcom-sdm660: enable HX83112A panel driver`

### Commit 2: new device + firmware (one commit per COMMITSTYLE)

Packages: `device/testing/device-vsmart-zangyapro/` + `device/testing/firmware-vsmart-zangyapro/`

- Copy from [`../pmaports/device/testing/`](../pmaports/device/testing) — both already at
  `pkgver=1 pkgrel=0`.
- **Do not copy** `board-2.bin`, `a512_zap.mbn` or `firmware-5.bin` if they are present in a
  working tree — they are download/build artifacts, not sources.
- `firmware-vsmart-zangyapro` ships:
  - `board-2.bin` (WCN3990 RF-calibration, 480 KB, 25-entry vendor table) — **not committed in
    pmaports**. Self-hosted in `vendor-blobs/` at repo root (outside MR scope); the APKBUILD
    fetches it from a **commit-pinned** raw GitHub URL via `_board_commit`, mirroring how
    `_zap_commit` pins the TheMuppets blob. Cannot use linux-firmware's copy — that file is for
    sdm845 and causes an MSS watchdog crash on SDM660 (pmaports #3803). See
    `vendor-blobs/README.md`.
  - `a512_zap.mbn` (Adreno 512 GPU zap shader) — TheMuppets
    `proprietary_vendor_xiaomi_wayne-common`, pinned commit `785f4c95`.
  - `firmware-5.bin` (WCN3990 feature descriptor) — **generated at build** by `ath10k-fwencoder`,
    not a blob. Identical invocation to whyred/tulip/etc.
- `modules-initfs` lists `panel-himax-hx83112a` so the display comes up in the initramfs.
- **Commit message:** `vsmart-zangyapro: new device`

## Working tree

**Do not build the MR from `pmaports-explore/`.** That clone is shallow (depth 1), has 1091
symlinks dereferenced into regular files, and a bare `*` appended to `.gitignore` — committing
from it produces an enormous bogus diff. Use a fresh full clone on a native Linux filesystem
(cloning onto the macOS-mounted path is what dereferenced the symlinks):

```bash
git clone https://gitlab.postmarketos.org/postmarketOS/pmaports.git ~/pmos/pmaports
cd ~/pmos/pmbootstrap
./pmbootstrap.py config aports /home/$USER/pmos/pmaports
./pmbootstrap.py config auto_zap_misconfigured_chroots yes   # systemd-edge vs edge channel
./pmbootstrap.py zap
```

## Validate before pushing

```bash
./pmbootstrap.py checksum --verify linux-postmarketos-qcom-sdm660
./pmbootstrap.py kconfig check linux-postmarketos-qcom-sdm660      # MUST pass
./pmbootstrap.py build --arch aarch64 --force linux-postmarketos-qcom-sdm660   # from the tarball, NOT --src
./pmbootstrap.py build device-vsmart-zangyapro firmware-vsmart-zangyapro
./pmbootstrap.py ci --fast
```

Prove the module and dtb actually landed in the package — this is what catches a silently
dropped Kconfig symbol:

```bash
tar -tzf ~/.local/var/pmbootstrap/packages/*/aarch64/linux-postmarketos-qcom-sdm660-7.0.14-r1.apk \
  | grep -E 'panel-himax-hx83112a|sdm660-vsmart-zangyapro'
```

Then flash and boot-test on the real device before opening the MR.
`[ci:skip-kconfigcheck]` is forbidden when touching a kernel package — and is not needed here.

## Submit

```bash
glab auth login --hostname gitlab.postmarketos.org   # self-hosted; a gitlab.com login will not work
glab repo fork postmarketOS/pmaports
git push -u fork vsmart-zangyapro
glab mr create --source-branch vsmart-zangyapro --target-branch main \
  --title "vsmart-zangyapro: new device" --fill
```

`glab` is optional — plain `git push` to your fork plus the GitLab web UI works fine.

- **Tick "Allow commits from members who can merge to the target branch"**, or the `mr-settings`
  CI job fails.
- Ping **@alexeymin** in the description: commit 1 touches his package. Note the change is
  additive (one new module, no shared symbol touched), reference `263089a0`, and post your
  boot-test result in the thread — for multi-device MRs on edge, anyone confirming it works in
  the thread satisfies the testing requirement.
- Approvals needed: the package maintainer **plus** one other team member. If the maintainer does
  not respond within 2 weeks, any 2 approvals suffice; opening the maintainership-status issue is
  then the merger's job, not yours.

## Notes

- Keep the device in `device/testing/` until it has a second independent tester.
- Touch is intentionally not included (parked — see `../docs/porting-notes.md`).
- After the MR merges, run the cleanup checklist in [`../README.md`](../README.md) — **including
  deleting this directory.**

## Checklist

```
[x] Tag v7.0.14-sdm660 cut (2026-08-02)
[x] pmaports bumped to 7.0.14 upstream (!9224, 263089a0) — no pkgver work needed
[x] Fresh full pmaports clone on native Linux fs
[ ] Commit 1: panel config + pkgrel, checksum, kconfig check
[ ] Commit 2: device + firmware packages
[ ] Real build from tarball; .ko + .dtb verified present in the apk
[ ] Flash + boot test on device
[ ] glab auth login --hostname gitlab.postmarketos.org (or use the web UI)
[ ] Fork pmaports on GitLab, push branch vsmart-zangyapro
[ ] Open MR against main, tick "Allow commits from members…", ping @alexeymin
[x] Wiki published: https://wiki.postmarketos.org/wiki/Vsmart_Active_1_(vsmart-zangyapro)
[ ] After merge: fill initial_MR in the wiki + run the cleanup checklist in ../README.md
```

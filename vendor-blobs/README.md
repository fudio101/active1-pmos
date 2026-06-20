# vendor-blobs/

Holds proprietary firmware blobs used by the Vsmart Active 1 (zangyapro) that:
- cannot be regenerated from source, AND
- have no usable public mirror (either absent from linux-firmware or present but incompatible).

This directory lives at **repo root** (not under `pmaports/`) so it is automatically excluded from
the upstream pmaports MR while its GitHub `main`-branch raw URLs remain publicly fetchable by the
APKBUILD.

---

## Files stored here

### `board-2.bin`

| Property | Value |
|----------|-------|
| Purpose | ath10k WCN3990 RF-calibration container (`QCA-ATH10K-BOARD` magic, `bus=snoc` qmi-board-id table) |
| Size | 480048 bytes (25 entries, 18 unique blobs each 19152 bytes) |
| sha512 | `424d328ebc8cf56d2112f687ab4f175cdf97cb8eac37e9390b6aeee87c022c6b97b7ad29cb2a1b955a781df02a88cff900cd1495bbcda9029af86754289fefe4` |
| Device board-id | `qmi-board-id=ff` (from dmesg: `qmi chip_id 0x140 ... board_id 0xff`) |

**Origin:** Extracted from the Vsmart Active 1 stock Android ROM, path
`/vendor/firmware/wlan/` (the exact ath10k board calibration table shipped by Vsmart for the PQ6001
hardware). This file is **not available from kernel.org linux-firmware** — the upstream
`ath10k/WCN3990/hw1.0/board-2.bin` there is a different 867 KB table for Pixel/Dragonboard/Lenovo
variants whose bare `qmi-board-id=ff` entry carries different RF data and causes MSS watchdog
crashes on SDM660 (pmaports issue #3803).

**Inspect entries:**
```sh
# Inside Alpine chroot with qca-swiss-army-knife package:
ath10k-bdencoder -i board-2.bin
# Extract all entries to individual .bin files + JSON mapping:
ath10k-bdencoder -e board-2.bin -o extracted.json
```

**How to update:** Obtain a stock Active 1 ROM dump (firmware OTA zip or raw `vendor.img`). Mount
the vendor partition, locate `firmware/wlan/board-2.bin` (or `board-2.bin` directly). Verify the
new file is a valid `QCA-ATH10K-BOARD` container with a `bus=snoc` table. Replace this file,
recompute sha512, update `sha512sums` in
`pmaports/device/testing/firmware-vsmart-zangyapro/APKBUILD`.

---

## Blobs NOT stored here (but still required by the device)

### `a512_zap.mbn` — Adreno 512 GPU zap shader

- **Fetched by APKBUILD** from TheMuppets `proprietary_vendor_xiaomi_wayne-common` (any SDM660 Xiaomi
  device works; content is identical across variants).
- **Origin:** Qualcomm binary included in every SDM660 vendor image. TheMuppets mirrors it.
- **How to update:** Bump `_zap_commit` in the APKBUILD to a newer `wayne-common` commit hash, then
  run `pmbootstrap checksum firmware-vsmart-zangyapro` to refresh sha512.
  ```
  # Current pin: 785f4c95ad84bd1daa747bd71211fdd419c0af01
  # File:        proprietary/vendor/firmware/a512_zap.elf
  # Repo:        https://github.com/TheMuppets/proprietary_vendor_xiaomi_wayne-common
  ```

### `wlanmdsp.mbn` — WCN3990 WLAN DSP firmware

- **Provided by** the Alpine `linux-firmware-ath10k` package (via `depends=` in the APKBUILD).
- **Origin:** linux-firmware upstream, `ath10k/WCN3990/hw1.0/wlanmdsp.mbn.zst`.
- **How to update:** Track the Alpine `linux-firmware-ath10k` package version. No action needed
  in this repo unless the Alpine package regresses.

### Adreno 530 microcode

- **Provided by** the Alpine `firmware-qcom-adreno-a530` package (via `depends=` in
  `device-vsmart-zangyapro/APKBUILD`).
- **How to update:** Track the Alpine package.

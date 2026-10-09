# vendor-blobs/

Holds proprietary firmware blobs used by the Vsmart Active 1 (zangyapro) that have no usable
public mirror (absent from linux-firmware, or present there but incompatible).

This directory lives at **repo root** (not under `pmaports/`) so it is automatically excluded from
the upstream pmaports MR while its GitHub raw URLs remain publicly fetchable by the APKBUILD.

> **The APKBUILD pins the raw URL to a commit SHA, never a branch**, so the source is immutable.
> When you replace a blob here, point the APKBUILD's pinned revision at the commit that added it
> and refresh the sha512.
>
> Note this repo's default branch is **`master`**, not `main` — a `.../active1-pmos/main/...`
> raw URL returns 404.

---

## Files stored here

### `board-2.bin`

| Property | Value |
|----------|-------|
| Purpose | ath10k WCN3990 board data (BDF) container: `QCA-ATH10K-BOARD` magic, `bus=snoc` qmi-board-id table |
| Size | 480048 bytes (25 entries, 18 unique BDFs, each 19152 bytes) |
| sha512 | `424d328ebc8cf56d2112f687ab4f175cdf97cb8eac37e9390b6aeee87c022c6b97b7ad29cb2a1b955a781df02a88cff900cd1495bbcda9029af86754289fefe4` |
| Device board-id | `qmi-board-id=ff` (dmesg: `qmi chip_id 0x140 ... board_id 0xff`) |
| Status | Works: WiFi connects and stays up with it (tested 2026-06 to 2026-10) |

**Origin: unknown — not documented when the file was added.** It was committed in `6ea2567`
(2026-06-13) without a note on where it came from. An earlier version of this README said it was
extracted from the stock `/vendor/firmware/wlan/`. That is not true: on the phone that folder only
holds `qca_cld/` (`WCNSS_qcom_cfg.ini`, `wlan_mac.bin`), and no `board*.bin` exists on any vendor,
modem, dsp, bluetooth or persist partition.

**What it actually contains (verified 2026-10-10 against the phone):** the phone's own BDFs, with
a small modification. The modem partition (`modem_a/image/` and `modem_b/image/`, identical)
holds 25 per-board files:

| Modem file | board-2.bin entry |
|------------|-------------------|
| `bdwlan.bin` | `bus=snoc,qmi-board-id=ff` (the one this device loads) |
| `bdwlan.102` … `bdwlan.109` | `qmi-board-id=102` … `109` |
| `bdwlan.bXX` (b04, b07, b09, b0a, b0b, b0d, b0e, b0f, b14, b30–b37) | `qmi-board-id=XX` (4, 7, 9, a, …) |

Same 25 ids, same 19152-byte size, same 18 unique blobs. But **every entry differs from its modem
file in byte 12** (`01` or `04` on the phone, `05` in board-2.bin) and in the 16-bit checksum at
bytes 10–11; the `ff` entry also differs in byte 15 (`03` vs `00`). Everything else is identical.
What byte 12 means, and who changed it, is not known.

This file is **not** linux-firmware's `ath10k/WCN3990/hw1.0/board-2.bin`: that one is a different
867 KB table for Pixel/Dragonboard/Lenovo boards whose `qmi-board-id=ff` entry carries other RF data
and causes MSS watchdog crashes on SDM660 (pmaports issue #3803).

**Inspect entries:**
```sh
# Inside an Alpine chroot with qca-swiss-army-knife:
ath10k-bdencoder -i board-2.bin
```

**Could be rebuilt instead of stored** (not done yet; would need a WiFi re-test, since the result
would carry the unmodified byte 12): pack the phone's own `modem_a/image/bdwlan.*` with
`ath10k-bdencoder -c board-2.json`, the same way `firmware-xiaomi-whyred` builds its board-2.bin.

---

## Blobs NOT stored here (but still required by the device)

### `firmware-5.bin` — ath10k firmware feature descriptor

Not a blob: generated in the firmware package's `build()` by `ath10k-fwencoder` (WMI/HTT op
version tlv, fw API 5, the WCN3990 feature flags), the same way whyred and tulip do it.

### `a512_zap.mbn` — Adreno 512 GPU zap shader

- **Fetched by the APKBUILD** from TheMuppets `proprietary_vendor_xiaomi_wayne-common` at a pinned
  commit (`785f4c95ad84bd1daa747bd71211fdd419c0af01`, file `proprietary/vendor/firmware/a512_zap.elf`).
  The content is identical across SDM660 vendor images.
- The phone's own vendor partition also has `a512_zap.mdt` + `.b00`–`.b02`; the packaged copy wins
  because msm-firmware-loader prefers `/lib/firmware/postmarketos/`.

### `wlanmdsp.mbn` — WCN3990 WLAN DSP firmware

- **Comes from the phone's own modem partition** (`modem_a/image/wlanmdsp.mbn`), exposed by
  `msm-firmware-loader`. The running WLAN firmware reports
  `WLAN.HL.1.0.1.c2-00590-QCAHLSWMTPLZ-1.220465.1`, which matches that file and not
  linux-firmware's (`WLAN.HL.2.0-01387`). So `linux-firmware-ath10k` is not needed.

### Adreno 530 microcode

- **Provided by** the Alpine `firmware-qcom-adreno-a530` package (a dependency of
  `device-vsmart-zangyapro`). The kernel loads `qcom/a530_pm4.fw` / `a530_pfp.fw` from it.

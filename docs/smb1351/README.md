# SMB1351 parallel charger: notes for writing a driver

Collected on 2026-10-10 while debugging `charge_behaviour=force-discharge`. Tracking issue:
[#1](https://github.com/fudio101/active1-pmos/issues/1). Today the chip is configured by a
userspace stopgap (`profile/vsmart-zangyapro-homeserver/smb1351-setup`). These notes are what a
kernel driver needs.

## Hardware
| | |
|---|---|
| Chip | Qualcomm **SMB1351/SMB1350** family. Stock DT says `qcom,smb1351-charger`, but VERSION reg `0x2E` reads `0xb2` (bit 1 set), which downstream `smb_chip_get_version()` treats as **SMB1350**. The register layout used here is shared by both |
| Bus | `blsp_i2c2` = `i2c@c176000`, gpio6 (SDA) / gpio7 (SCL), 400 kHz. Same pins in stock and mainline `sdm630.dtsi` |
| Address | `0x1d` (7-bit) |
| Power | Powered from **VBUS only**: no ACK on battery alone. All configuration is lost when VBUS goes away |
| Enable pin | Driven by the **PM660 STAT pin** (PM660 `STAT_CFG` `0x1690`) |
| Topology | Parallel charger next to the PM660 SMB2 charger (`qcom,parallel-charger`) |
| Neighbour | `nxp,ptn36502@1a` (USB-C redriver) on the same bus, also unpowered without VBUS |

Stock DT node (decompiled from the stock kernel in `boot_b`; local copy outside this repo):
```dts
smb1351-charger@1d {
	compatible = "qcom,smb1351-charger";
	reg = <0x1d>;
	qcom,parallel-charger;
	qcom,float-voltage-mv = <4400>;      /* 0x1130 */
	qcom,recharge-mv = <100>;            /* 0x64 */
	qcom,parallel-en-pin-polarity = <1>; /* EN_BY_PIN_HIGH_ENABLE */
};
```
The battery is 3000 mAh, `voltage-max-design` 4.40 V.

## The problem on mainline
Nothing touches the chip, so it runs on its **OTP defaults**:
- `0x06` CHG_PIN_EN_CTRL = `0x6b` → bits 6:5 = `11` = **EN_BY_PIN_LOW_ENABLE**. The PM660 STAT
  pin is SW-overridden low (`0x1690` = `0x42`: override on, value 0), so the chip is
  **always enabled**.
- `0x03` VFLOAT = `0xf2` → bits 5:0 = `0x32` → 3500 + 50 × 20 = **4500 mV** on a 4.40 V battery.
- `0x02` VARIOUS_FUNC = `0x07`: suspend controlled by pin, AICL off, APSD on.

Behaviour (SMB1351 status regs read over I2C, PM660 regs via regmap debugfs):

| PM660 mode | PM660 input | SMB1351 `0x37` / `0x39` / `0x3A` | SMB1351 does | battery |
|---|---|---|---|---|
| auto | on | `0x10` / `0x00` / `0x09` (hold-off) | idle | charged by the PM660 only |
| inhibit-charge | on | idle | idle | ~0 mA |
| force-discharge (USBIN suspended) | **off** | `0x11` (on USB input) / `0x80` (charging) / `0x05` (**fast charge**) | **charges toward 4.50 V** | +390 mA, voltage rising |

So it takes over exactly when the PM660 stops drawing from VBUS. In auto, the PM660 alone
explains the measured current: about 1.4 A at a 1.5 A ICL, and 435 mA at a 500 mA ICL. How much
the SMB1351 could add as a real parallel charger is untested.

## Fix (verified)
Set the enable to **pin active high**, as stock does. The PM660 never raises STAT, so the
SMB1351 stays off:
```
0x30 |= 0x40          # CMD_I2C: CMD_BQ_CFG_ACCESS (volatile config writes)
0x06 = (0x06 & ~0x60) | 0x40   # EN_BY_PIN_HIGH_ENABLE
0x03 = (0x03 & ~0x3f) | 0x2d   # VFLOAT 4400 mV (belt and braces)
```
After this, force-discharge drains (-175 to -260 mA, SMB1351 `0x39` = `0x3A` = `0x00`).
Revert with `0x06 = 0x6b`, `0x30 = 0x00`, or by unplugging.

## What a driver has to do
1. **Configure on every VBUS arrival, not just at probe.** At boot the chip may be unpowered,
   and it forgets everything on unplug. Hook into the PM660 charger: a `power_supply` notifier on
   `pm660-charger` (USB online / usb-plugin irq) or a supplier relationship. Note that in
   force-discharge the PM660 reports `online=0` while VBUS is present and the SMB1351 is
   powered. A replug in that state must still be caught (the stopgap relies on the limiter
   noticing within 5 s). Unverified: whether the PM660 usb-plugin irq still fires on a replug while USBIN is suspended.
2. Right after plug-in the chip may NACK for a moment. Retry, and do not fail probe on NACK.
3. Minimal sequence (downstream `smb1351_parallel_set_chg_suspend(chip, 0)`):
   - `0x30` bit 6 = 1 (volatile writes)
   - `0x03` VFLOAT from `qcom,float-voltage-mv` (3500-4500 mV, 20 mV steps)
   - `0x04` auto-recharge enable + threshold (bit 7 = 0, bit 3 = 1 for 100 mV)
   - `0x02` suspend by I2C, APSD off (`SUSPEND_MODE_CTRL_BY_I2C`, clear `APSD_EN`)
   - `0x31` bit 6 = 1 (USB suspend) until a current is assigned
   - `0x06` bits 6:5 = pin polarity from DT (`0x40` active high), bit 4 = USBCS by I2C
   - `0x01` bits 1:0 = USB 2/3 selection by I2C, 500/100 polarity
   - `0x00` bits 7:4 = fast-charge current index
4. If it never does real parallel charging, steps 1 and 3 reduce to the enable polarity plus
   VFLOAT. That is enough for a 24/7 server. Real parallel charging also needs the PM660 side
   (raise STAT, split FCC, ICL), which `qcom_smbx` does not do.
5. Mainline has no SMB1351 driver. `smb347-charger.c` is a different family (SMB345/347/358).
   Search lore for `smb1351` / `smb1350` before writing one.

## Register map (subset; from downstream `smb1351-charger.c`)
| Reg | Name | Bits used | OTP value seen |
|---|---|---|---|
| `0x00` | CHG_CURRENT_CTRL | 7:4 fast-charge idx (1000…4640 mA), 3:0 AC ICL idx (500…3000 mA) | `0x02` |
| `0x01` | CHG_OTH_CURRENT_CTRL | 7:5 prechg, 4:2 iterm, 1 USB2/3 by I2C/pin, 0 500/100 polarity | `0x1d` |
| `0x02` | VARIOUS_FUNC | 7 suspend by pin/I2C, 4 AICL, 2 APSD | `0x07` |
| `0x03` | VFLOAT | 7:6 prechg→fast, 5:0 (mV − 3500) / 20 | `0xf2` (4.50 V) |
| `0x04` | CHG_CTRL | 7 auto-recharge disable, 6 iterm disable, 3 recharge 50/100 mV | `0x88` |
| `0x06` | CHG_PIN_EN_CTRL | 6:5 EN mode (00 I2C 0=dis, 01 I2C 0=en, 10 pin high, 11 pin low), 4 USBCS by pin | `0x6b` |
| `0x08` | WDOG_SAFETY_TIMER_CTRL | watchdog / safety timer | `0x00` |
| `0x0E` | VARIOUS_FUNC_2 | 7 hold-off after plug-in, 6 charge inhibit | `0x98` |
| `0x2E` | VERSION | bit 1: 1 = SMB1350 | `0xb2` |
| `0x30` | CMD_I2C | 7 reload, 6 volatile config access | `0x00` |
| `0x31` | CMD_INPUT_LIMIT | 6 USB suspend, 3 ICL by cmd, 2 USB3, 1:0 100/500/AC | `0x00` |
| `0x32` | CMD_CHG | 1 charge enable (only when EN is by I2C) | `0x00` |
| `0x36` | STATUS_0 | 7 AICL, 6:5 ICL | `0x16` |
| `0x37` | STATUS_1 | 0 input is USB | `0x10` / `0x11` |
| `0x38` | STATUS_2 | 7 fast chg, 5:0 float voltage | `0x32` |
| `0x39` | STATUS_3 | 7 charging, 3:0 fast-charge current | `0x00` / `0x80` |
| `0x3A` | STATUS_4 | 3 hold-off, 2:1 00 none / 01 pre / 10 fast / 11 taper | `0x09` / `0x05` |

Full dumps: `smb1351-i2c.txt` (here).

## PM660 side (SMB2 @ SID 0, base 0x1000)
| Reg | Name | auto | inhibit | force-discharge |
|---|---|---|---|---|
| `0x1006` | BATTERY_CHARGER_STATUS_1 | `03` FULLON | `47` DISABLE | `47` DISABLE |
| `0x100B` | BATTERY_CHARGER_STATUS_5 | `96` | `80` valid input | `40` DISABLE_CHARGING, no input |
| `0x1042` | CHARGING_ENABLE_CMD | `01` | `00` | `00` |
| `0x1340` | USBIN_CMD_IL | `00` | `00` | `01` suspend |
| `0x1607` | ICL_STATUS | `14` | `14` | `00` |
| `0x160B` | POWER_PATH_STATUS | `95` | `95` | `72` USBIN+DCIN suspended |
| `0x1690` | STAT_CFG | `42` | `42` | `42` (SW override, low) |

Full dumps of `0x1000-0x16ff`: `pm660-*.txt` (here). The rradc `usbin_i` channel reads garbage
(ramping to ~900 mA) while USBIN is suspended. Do not trust it in that state.

## How to poke it (needs a kernel with `blsp_i2c2` enabled, VBUS present, root)
```sh
i2cdump -y -r 0x00-0x4f 0 0x1d b                 # SMB1351
i2cget  -y 0 0x1d 0x06
dd if=/sys/kernel/debug/regmap/0-00/registers bs=9 skip=$((0x1340)) count=1   # PM660 (debugfs)
```
The regmap debugfs `registers` file has fixed 9-byte lines (`"%04x: %02x\n"`), so `dd` with
`bs=9 skip=<reg>` reads one register.

## References
- Downstream driver: LineageOS `android_kernel_xiaomi_sdm660` @ `49688d8750f2`:
  [`smb1351-charger.c`](https://github.com/LineageOS/android_kernel_xiaomi_sdm660/blob/49688d8750f2fca28271f936cfcfec5d97c0d7a4/drivers/power/supply/qcom/smb1351-charger.c)
  (see `smb1351_parallel_set_chg_suspend()`, `smb1351_parallel_set_property()`),
  [`smb-reg.h`](https://github.com/LineageOS/android_kernel_xiaomi_sdm660/blob/49688d8750f2fca28271f936cfcfec5d97c0d7a4/drivers/power/supply/qcom/smb-reg.h)
  and [`smb-lib.c`](https://github.com/LineageOS/android_kernel_xiaomi_sdm660/blob/49688d8750f2fca28271f936cfcfec5d97c0d7a4/drivers/power/supply/qcom/smb-lib.c)
  (PM660 side: `smblib_stat_sw_override_cfg()`, `smblib_set_prop_input_suspend()`).
- Kernel DT commit enabling the bus: fudio101/linux-sdm660 `7e32073c1088`
  (branch `fudio101/vsmart-active1-next`).
- Stopgap: `profile/vsmart-zangyapro-homeserver/smb1351-setup`, `smb1351.rules`, `charge-limit`.

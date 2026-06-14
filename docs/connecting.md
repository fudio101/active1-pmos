# Connecting to the Vsmart Active 1 (postmarketOS, headless)

User: `fudio101`  ·  password: `147147`  (for sudo: `echo 147147 | sudo -S <cmd>`)

---

## 1. Over the USB cable (no WiFi needed)

When you plug the phone into a laptop, it exposes a **USB network gadget** and answers at
**`172.16.42.1`**. This is the first way in, before any WiFi is configured.

### Host side (Linux / macOS / WSL)
A new network interface shows up (e.g. `usb0`, `enpXsY`). It usually gets an address by DHCP.
If it does not, set one by hand:

```sh
# find the new interface
ip link
# give the host an address on the phone's USB subnet
sudo ip addr add 172.16.42.2/24 dev <iface>
sudo ip link set <iface> up
```

### Finding the phone's IP over USB (no WiFi yet)
The phone's USB-gadget address is **fixed at `172.16.42.1`** — that is always the phone, so
in practice you do not need to "discover" it, just use it. To *confirm* the link is up:

```sh
# Linux / macOS / WSL host:
ip -4 addr | grep -B2 172.16.42        # which host iface is on the 172.16.42.x subnet
ip route | grep 172.16.42              # route to the phone's subnet
ping -c2 172.16.42.1                   # reachable?
ip neigh | grep 172.16.42.1            # the phone's entry in the neighbour table
# still unsure which address? scan the tiny USB subnet:
nmap -sn 172.16.42.0/24                # (or: arp-scan -l)
```

```powershell
# Windows host (PowerShell):
Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -like '172.16.42.*'
arp -a | findstr 172.16.42
ping 172.16.42.1
```

If you have a local keyboard/console on the phone itself, read it from the phone side:
```sh
ip -4 addr show usb0          # the gadget interface (usb0/rndis0/ncm0)
ip -4 addr | grep 172.16.42
```

### SSH — normal full system (use this 99% of the time)
```sh
ssh fudio101@172.16.42.1          # password: 147147
```

### Telnet — initramfs debug shell (only when boot is stuck)
Use this **only** if the phone is stuck early (e.g. "waiting for root partition", or a disk
unlock prompt). The initramfs runs a telnet server on the same USB address:
```sh
telnet 172.16.42.1               # or:  nc 172.16.42.1 23
```
On a normal boot you do not need telnet — go straight to SSH.

---

## 2. WiFi — scan & connect

NetworkManager and the WiFi backend (wpa_supplicant) ship in the image and manage WiFi
automatically — nothing to install or set up, just connect with `nmcli`:

```sh
nmcli dev wifi list                              # scan / list networks
nmcli dev wifi connect "SSID" password "PASS"    # connect
nmcli -g IP4.ADDRESS dev show wlan0              # the phone's WiFi IP
nmcli con show                                   # saved connections
nmcli con delete "SSID"                          # forget a network
```
Connections are saved and **auto-reconnect on the next boot**, so each network only needs the
password once.

Once WiFi is up you can SSH over the network instead of the cable:
```sh
ssh fudio101@<wifi-ip>
```

---

## 3. Bluetooth keyboard

WiFi and Bluetooth share the same WCN3990 chip; both work on mainline. **Bluetooth auto-starts
at boot** (the `device-vsmart-zangyapro` package enables `bluetooth.service`), so go straight to
`bluetoothctl` — no need to start it. If the controller reports off, unblock it once with
`sudo rfkill unblock bluetooth`.

```sh
bluetoothctl
```
Inside the `bluetoothctl` prompt:
```
power on
agent on
default-agent
scan on                 # wait a few seconds; note the keyboard's MAC (AA:BB:CC:DD:EE:FF)
scan off
pair AA:BB:CC:DD:EE:FF   # if a PIN is shown, TYPE IT ON THE BT KEYBOARD then Enter
trust AA:BB:CC:DD:EE:FF  # so it auto-reconnects after a reboot
connect AA:BB:CC:DD:EE:FF
exit
```
Verify the keyboard registered as an input device:
```sh
cat /proc/bus/input/devices | grep -iA4 -E "keyboard|kbd"
ls /dev/input/by-id/ 2>/dev/null
```
After `trust`, the keyboard reconnects automatically on later boots — useful for a headless
box where you occasionally want a local keyboard at the console (tty1).

---

## Quick reference

| Goal | Command |
|---|---|
| SSH over USB | `ssh fudio101@172.16.42.1` |
| Initramfs telnet (boot stuck) | `telnet 172.16.42.1` |
| Scan WiFi | `nmcli dev wifi list` |
| Connect WiFi | `nmcli dev wifi connect "SSID" password "PASS"` |
| WiFi IP | `nmcli -g IP4.ADDRESS dev show wlan0` |
| Pair BT keyboard | `bluetoothctl` → `scan on` → `pair/trust/connect <MAC>` |
| Reboot caveat | soft reboot hangs — power-cycle (hold Power, then power on) |

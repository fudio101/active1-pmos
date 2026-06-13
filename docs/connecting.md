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

### NetworkManager (preferred)
```sh
nmcli radio wifi on                              # make sure the radio is on
nmcli dev wifi list                              # scan / list networks
nmcli dev wifi connect "SSID" password "PASS"    # connect
nmcli dev status                                 # see wlan0 state
nmcli -g IP4.ADDRESS dev show wlan0              # the phone's WiFi IP
nmcli con delete "SSID"                          # forget a network
```
Connections are saved and auto-reconnect on the next boot.

### Fallback — wpa_supplicant (if `nmcli` is not installed)
```sh
sudo rfkill unblock wifi
wpa_passphrase "SSID" "PASS" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
sudo udhcpc -i wlan0            # get an IP (or: sudo dhcpcd wlan0)
ip addr show wlan0
```

Once WiFi is up you can SSH over the network instead of the cable:
```sh
ssh fudio101@<wifi-ip>
```

---

## 3. Bluetooth keyboard

WiFi and Bluetooth share the same WCN3990 chip; both work on mainline.

```sh
sudo rfkill unblock bluetooth
sudo systemctl start bluetooth          # (systemd image)  -- or: sudo rc-service bluetooth start
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

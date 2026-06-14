# Active 1 cheat sheet (postmarketOS / Alpine, systemd)

Handy commands for running this device as a headless server. Network/SSH/WiFi/BT setup is in
[`connecting.md`](connecting.md). `sudo` password is `147147` (or `echo 147147 | sudo -S <cmd>`).

## Packages (apk)

```sh
sudo apk add <pkg>                 # install            (e.g. htop, neovim, tmux)
sudo apk del <pkg>                 # uninstall
sudo apk fix [<pkg>]               # re-run repair / reinstall a package
apk info -vv | grep <pkg>          # is it installed? which version?
sudo apk upgrade                   # upgrade to newer versions  <-- USE THIS ONE
```

> **WARNING — do NOT run `apk upgrade -a` / `--available` / `--prune` on this device.**
> The general pmOS advice is to use `-a`, but our **kernel, `device-vsmart-zangyapro` and
> `firmware-vsmart-zangyapro` are local builds not in any public repo**, so `-a` would
> *downgrade* the kernel (losing the DTS → broken boot) and `--prune` would *remove* the
> device/firmware packages (losing WiFi + GPU). Plain `sudo apk upgrade` is safe. The three
> packages are pinned in `/etc/apk/world` as a safety net. (Resolved once the port is upstreamed
> to pmaports.)

```sh
cat /etc/apk/world                 # explicitly-installed packages (edit + `apk fix` to apply)
cat /etc/apk/repositories          # configured repos
```

## Services (systemd)

```sh
sudo systemctl status  <svc>       # e.g. NetworkManager, bluetooth, tailscaled, sshd
sudo systemctl start|stop|restart <svc>
sudo systemctl enable|disable <svc>          # on/off at boot
systemctl list-units --failed                # anything broken?
journalctl -u <svc> --no-pager -n 50         # service log
journalctl -b -p err --no-pager              # this boot's errors
```

## Reboot / power

```sh
sudo reboot                                  # works on a healthy battery (keep on a 2A charger)
sudo poweroff
sudo systemctl reboot --reboot-argument=bootloader   # reboot straight into fastboot (no key combo)
```

> The `--reboot-argument=bootloader` form is the clean way to get into fastboot over SSH for
> flashing — no need to power off and hold Volume-Down + Power.

## Device quick-checks (used during this port)

```sh
# Battery / charging
cat /sys/class/power_supply/qcom-battery/{capacity,status,voltage_now,current_now,temp}
#   current_now: + = charging, - = discharging ; temp is in 0.1 C
cat /sys/class/power_supply/pm660-charger/{usb_type,current_max}   # SDP=weak, DCP=wall charger

# Temperatures (SoC / GPU / battery)
for z in /sys/class/thermal/thermal_zone*; do \
  printf '%s %s\n' "$(cat $z/type)" "$(($(cat $z/temp)/1000))C"; done

# GPU (freedreno) – confirm hardware accel
glmark2-es2-drm -b build:duration=2.0 2>&1 | grep -E 'GL_RENDERER|Score'   # FD512 = HW

# WiFi
nmcli dev wifi list
nmcli dev wifi connect "SSID" password "PASS"
nmcli -g IP4.ADDRESS dev show wlan0

# Bluetooth (auto-started)
bluetoothctl              # power on / scan on / pair,trust,connect <MAC>

# Tailscale
tailscale status
tailscale ip -4

# A/B boot slot (qbootctl keeps the active slot "successful")
sudo qbootctl             # shows Active/Successful/Bootable per slot

# Storage / memory
df -h /                   # root usage
free -h ; swapon --show   # RAM + zram swap
```

## Misc niceties

```sh
sudo apk add mandoc man-pages docs     # man pages (not installed by default)
sudo apk add bash htop tmux ncdu       # a friendlier shell + monitors
chsh -s /bin/bash                      # change login shell
sudo apk add etckeeper                 # track /etc changes (incl. package changes) in git
```

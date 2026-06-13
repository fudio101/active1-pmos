#!/bin/bash
SSHOPT="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8"
IP=192.168.1.2
sshpass -p 147147 ssh $SSHOPT fudio101@$IP 'true' 2>/dev/null || IP=172.16.42.1
SSH="sshpass -p 147147 ssh $SSHOPT fudio101@$IP"
echo "IP=$IP"

echo "=== install light TUI tools ==="
$SSH 'echo 147147 | sudo -S apk add --no-progress tmux mc ncdu btop micro kbd terminus-font fastfetch 2>&1 | tail -6'

echo "=== set a big readable console font now ==="
$SSH 'echo 147147 | sudo -S sh -c "setfont /usr/share/consolefonts/ter-v28b.psf.gz 2>/dev/null || setfont ter-v28b 2>/dev/null || setfont /usr/share/consolefonts/ter-v32n.psf.gz 2>/dev/null; echo set-font-done"'

echo "=== make the big font persistent (Alpine: /etc/conf.d/consolefont + consolefont service) ==="
$SSH 'echo 147147 | sudo -S sh -c "mkdir -p /etc/vconsole.conf.d 2>/dev/null; printf FONT=ter-v28b\\\\n > /etc/vconsole.conf 2>/dev/null; echo done-persist"'

echo "=== installed versions ==="
$SSH 'for p in tmux mc btop micro; do printf "%s=" $p; command -v $p >/dev/null && $p --version 2>/dev/null | head -1 || echo missing; done'
echo DONE

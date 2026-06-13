#!/bin/bash
. /etc/os-release
echo "distro: $PRETTY_NAME"
echo "kernel: $(uname -r)"
echo "python3: $(python3 --version 2>&1)"
echo "git: $(command -v git) $(git --version 2>&1)"
echo "pip3: $(command -v pip3 || echo MISSING)"
echo "pipx: $(command -v pipx || echo MISSING)"
echo "git(wsl-native): $(ls -l /usr/bin/git 2>&1 | head -1)"
echo "--- sudo NOPASSWD? ---"
if sudo -n true 2>/dev/null; then echo "SUDO_NOPASSWD_OK"; else echo "SUDO_NEEDS_PASSWORD"; fi
echo "--- loop device support (pmbootstrap can) ---"
ls /dev/loop-control 2>&1
echo "--- disk home ---"
df -h "$HOME" 2>&1 | tail -1
echo "--- whoami ---"; whoami
echo "DONE"

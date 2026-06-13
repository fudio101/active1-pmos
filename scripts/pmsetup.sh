#!/bin/bash
echo "=== sudo NOPASSWD check ==="
if sudo -n true 2>/dev/null; then echo "SUDO_NOPASSWD_OK"; else echo "FAIL: sudo still needs password"; exit 1; fi

echo "=== clone pmbootstrap ==="
cd ~
if [ ! -d ~/pmbootstrap ]; then
  git clone --depth=1 https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git ~/pmbootstrap 2>&1 | tail -3
else
  echo "already cloned"
fi

cd ~/pmbootstrap
echo "=== try direct run ==="
if ./pmbootstrap.py --version 2>/dev/null; then
  echo "DIRECT_RUN_OK"
else
  echo "direct run failed -> try pipx install"
  sudo apt-get update -qq 2>&1 | tail -1
  sudo apt-get install -y -qq pipx 2>&1 | tail -2
  pipx ensurepath 2>&1 | tail -1
  ~/.local/bin/pipx install pmbootstrap 2>&1 | tail -5 || pipx install pmbootstrap 2>&1 | tail -5
  echo "--- pmbootstrap via pipx ---"
  ~/.local/bin/pmbootstrap --version 2>&1 | head -2 || pmbootstrap --version 2>&1 | head -2
fi
echo "DONE"

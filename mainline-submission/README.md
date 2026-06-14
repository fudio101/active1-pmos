# Mainline drm-misc submission — HX83112A Vsmart Active 1 variant

The "proper home" for the panel driver + binding is mainline `drm-misc`, in parallel with the
sdm660-mainline PR ([#185](https://github.com/sdm660-mainline/linux/pull/185)). This dir stages a
ready-to-send **2-patch series** (binding + driver). **You** send it (a mailing-list post is your
call) — nothing here is sent automatically.

## What's here
- `0000-cover-letter.patch` — `[PATCH 0/2]` cover letter (honest write-up of the minimal-init design).
- `0001-...himax,hx83112a...patch` — `[PATCH 1/2]` dt-binding: add `djn,a1-hx83112a`.
- `0002-...panel-himax-hx83112a...patch` — `[PATCH 2/2]` driver: multi-variant + DJN 1080x2160.
- `cc-list.txt` — To/Cc from `get_maintainer.pl`.

Both patches apply on **current torvalds master / drm-misc-next**: the driver base file is
byte-identical to mainline, and the binding hunk applies cleanly (verified with `git apply --check`).
Both are `checkpatch.pl --strict` clean (0/0/0) under the *current* checkpatch (the one that knows
the `Assisted-by` tag — our local 6.19.y tree's older checkpatch falsely flags it).

## One-time setup (git send-email + Gmail SMTP)
```
sudo apt-get install -y git-email
git config --global sendemail.smtpServer smtp.gmail.com
git config --global sendemail.smtpServerPort 587
git config --global sendemail.smtpEncryption tls
git config --global sendemail.smtpUser thenguyen1024@gmail.com
# Use a Google "App Password" (not your normal password) for sendemail.smtpPass,
# or let git prompt for it.
```

## Send
Best practice is to base the series on a fresh `drm-misc-next` (or torvalds master) checkout and
re-generate, but since the patches apply as-is you can also send the staged files directly:
```
cd ~/active1-pmos/mainline-submission
git send-email \
  --to="Neil Armstrong <neil.armstrong@linaro.org>" \
  --to="Rob Herring <robh@kernel.org>" \
  --to="Krzysztof Kozlowski <krzk+dt@kernel.org>" \
  --to="Conor Dooley <conor+dt@kernel.org>" \
  --cc="Jessica Zhang <jesszhan0024@gmail.com>" \
  --cc="Luca Weiss <luca.weiss@fairphone.com>" \
  --cc="dri-devel@lists.freedesktop.org" \
  --cc="devicetree@vger.kernel.org" \
  --cc="linux-kernel@vger.kernel.org" \
  0000-cover-letter.patch 0001-*.patch 0002-*.patch
```
(Add the remaining Cc names from `cc-list.txt` if you want the full set. `git send-email` threads
0001/0002 under the cover letter automatically.)

## Expect / heads-up
- The `djn,a1-hx83112a` variant does **minimal init + no reset** (bootloader does the IC init). The
  cover letter explains this with the downstream-DT evidence, but a drm/panel reviewer (Neil
  Armstrong) may still ask for a self-contained init. Reverse-engineering the lk init was decided
  against, so be ready to either discuss or drop the variant from mainline if pushed.
- After the binding + driver land in drm-misc, the **device tree** (`sdm660-vsmart-zangyapro.dts`)
  and the `arm/qcom.yaml` board compatible are a **separate** submission to the qcom / arm-soc tree
  (Bjorn Andersson, `linux-arm-msm`) — they reference `djn,a1-hx83112a` so they must wait.

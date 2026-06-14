# scripts

A few reusable helpers kept from bring-up. They SSH to the device (edit the IP/password at the
top) and assume the pmbootstrap layout. Everything else (one-off generators, extractors and
experiments) was removed; the build/flash workflow lives in ../dev.sh.

- `gpu_render_drm.sh`   - verify the GPU actually renders (glmark2-es2-drm, freedreno FD512).
- `diag_reboot_hang.sh` - collect diagnostics for the soft-reboot hang (open issue).
- `test_touch.sh`       - check Himax touch probe + capture events (for resuming the touch port).

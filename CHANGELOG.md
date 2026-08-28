# Changelog

## Unreleased

- Web apps resolve their name and icon through the desktop entry that launches
  the site, so every Omarchy web app gets its own icon instead of only WhatsApp
  and Discord.
- The bar rebuilds only on Hyprland events that change workspace contents and
  caches desktop-entry lookups per application.
- Workspace buttons register as bar click targets, matching the built-in widget.
- The hover panel fades out instead of disappearing.
- `scripts/install.sh` validates the staged plugin, ships `LICENSE`, and refuses
  to flatten an installation managed by `omarchy plugin add`.
- CI runs the model, contract and installer tests.

## 0.1.0 — 2026-08-18

- First release: grouped application icons per workspace, `+N` overflow, and a
  hover panel with window titles. WhatsApp and Discord web-app icons were
  verified after restarting Omarchy Shell.

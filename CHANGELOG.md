# Changelog

## Unreleased

- Web apps resolve their name and icon through the desktop entry that launches
  the site (by URL or `omarchy-webapp-handler-*` script), replacing the
  WhatsApp/Discord table. Sites without a desktop entry still fall back to the
  generic icon.
- The bar rebuilds only on Hyprland events that change workspace contents and
  caches desktop-entry lookups per application.
- Workspace buttons register as bar click targets; left clicks are routed by
  the bar host and right/middle clicks still focus the workspace.
- The hover panel fades out and releases the bar's popout slot on close; it is
  click-through while fading.
- The fallback icon tile and count badge follow the bar foreground and stay
  readable on transparent bars.
- `scripts/install.sh` validates the staged plugin, ships `LICENSE`, and refuses
  to flatten an installation managed by `omarchy plugin add`.
- CI runs the model, contract and installer tests.

## 0.1.0 — 2026-08-18

- First release: grouped application icons per workspace, `+N` overflow, and a
  hover panel with window titles. WhatsApp and Discord web-app icons were
  verified after restarting Omarchy Shell.

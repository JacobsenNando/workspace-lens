# Workspace Lens

Workspace Lens is an Omarchy Shell widget that makes applications in each
Hyprland workspace visible directly from the bar.

## Requirements

- Omarchy 4
- Quickshell 0.3
- Hyprland

## Installation

From a checkout of this repository, install the plugin into your user plugin
directory with:

```bash
bash scripts/install.sh
```

The installer writes only to
`~/.config/omarchy/plugins/jacobsennando.workspace-lens` (or the isolated
`WORKSPACE_LENS_INSTALL_ROOT` used by tests). It safely replaces a previous
Workspace Lens installation, but refuses to overwrite an unknown plugin.

Activation rescans Omarchy Shell plugins and enables Workspace Lens. Its
manifest metadata declares that it replaces `omarchy.workspaces`, so Omarchy
uses Workspace Lens in place of the built-in workspace widget.

## Experience

- Each workspace shows up to three grouped application icons and a `+N`
  overflow indicator.
- Group badges show the number of windows for an application.
- Hovering for 180 ms opens a contextual panel; it closes after 220 ms.
- The panel is informational and lists the applications and windows without
  changing native workspace switching.

## Development

Run the automated checks with:

```bash
node --test tests/*.test.mjs && bash tests/install.test.sh
```

To remove the plugin safely, disable it first, then remove only its exact user
plugin directory:

```bash
omarchy plugin disable jacobsennando.workspace-lens
rm -rf ~/.config/omarchy/plugins/jacobsennando.workspace-lens
```

## Status

Implemented and verified in a live Omarchy session with real Hyprland windows,
grouped application counts, overflow, hover crossing, and horizontal and
vertical bar positions. The durable visual rules live in [DESIGN.md](DESIGN.md),
and the approved direction remains available in the
[design specification](docs/superpowers/specs/2026-08-18-workspace-lens-design.md).

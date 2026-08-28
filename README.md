# Workspace Lens

Workspace Lens is an Omarchy Shell widget that makes applications in each
Hyprland workspace visible directly from the bar.

![Workspace Lens showing the workspace hover panel and icons on the bar](preview.png)

## Requirements

- Omarchy 4
- Quickshell 0.3
- Hyprland

## Installation

Install and enable the public plugin with:

```bash
omarchy plugin add https://github.com/JacobsenNando/workspace-lens.git --enable
```

From a checkout of this repository, the same command accepts a local path and
keeps the install updatable with `omarchy plugin update`:

```bash
omarchy plugin add ~/Projects/workspace-lens --enable
```

`scripts/install.sh` copies only the runtime files into
`~/.config/omarchy/plugins/jacobsennando.workspace-lens` (or the isolated
`WORKSPACE_LENS_INSTALL_ROOT` used by tests) for quick local iteration. It
validates the staged plugin, replaces a previous copy it made, and refuses to
overwrite an unknown plugin or a checkout managed by `omarchy plugin add`.

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

To remove the plugin, disable it and delete its directory in one step:

```bash
omarchy plugin remove jacobsennando.workspace-lens
```

Web apps installed with `omarchy webapp install` show their own icon: the
window class names the site, and the desktop entry that launches that site
supplies the name and icon.

The approved direction is in the
[design specification](docs/superpowers/specs/2026-08-18-workspace-lens-design.md);
changes are tracked in [CHANGELOG.md](CHANGELOG.md).

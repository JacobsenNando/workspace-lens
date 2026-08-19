---
name: Workspace Lens
description: An application-aware workspace map native to the Omarchy bar.
---

# Design System: Workspace Lens

## Overview

**Creative North Star: "Workspace Lens"**

Workspace Lens is an Operate-mode extension of the Omarchy bar: a compact,
application-aware map that helps users recognize where their work lives before
they switch. It favors spatial recognition, stable targets, and progressive
disclosure over decorative expression.

The plugin belongs visually to the active Omarchy environment. It inherits the
bar's live theme and component language instead of defining a portable palette,
type scale, or spacing system of its own. The bar carries identity and status;
the hover panel reveals window-level detail without becoming another control
surface.

**Key Characteristics:**

- Native to the active Omarchy theme and bar geometry.
- Compact application grouping with bounded overflow.
- Stable numbered targets in every supported orientation.
- One flat, informational detail surface with restrained hierarchy.
- State changes that preserve layout and use more than color alone.

## Colors

Workspace Lens has no independent color palette. It consumes the current
Omarchy `Color` roles at runtime: the bar foreground for text and identity,
`Color.accent` for focused emphasis and count highlights, and
`Color.background` for unresolved-icon fallbacks. Selected and hover fills are
derived through Omarchy's shared `Style` helpers, and border appearance comes
from the shared `Border` vocabulary.

The current theme can change every visible value without changing the plugin.
Theme-specific colors observed during verification are examples of the host
theme, not Workspace Lens tokens, so no fixed color values belong in this
system.

**The Host Palette Rule.** Use Omarchy color roles and derived fills; never
promote a theme's resolved colors into plugin constants.

**The Reinforced Focus Rule.** Communicate the focused workspace with selected
surface and border treatments plus an accent edge, never with color alone.

## Typography

All text uses the active Omarchy `Style.font.family`. Workspace numbers and
compact counts use the inherited caption role; application names and popover
headings use the inherited body role with bold emphasis; window titles and
summary totals use the inherited small-body role.

The hierarchy is intentionally shallow: workspace identity first, application
identity second, group count third, and individual window title last. Empty
workspace numbers remain legible but use half opacity unless focused. Long
application names and titles stay on one line and elide; a truncated title
reveals its full value through the bar's native tooltip.

**The Shell Type Rule.** Inherit family and size roles from `Style`; do not
introduce fixed font families, pixel sizes, or a plugin-specific type scale.

## Layout

Workspaces 1–5 remain visible, with occupied workspaces up to 10 appended in
numeric order. Workspace 10 is labeled `0`, matching the incumbent widget.
Every workspace keeps a full cross-axis target equal to the host bar size.

In a horizontal bar, targets form one row and read as workspace number,
application summary, then overflow. The summary shows at most three application
groups, each represented by one icon; remaining groups collapse into `+N`. In a
vertical bar, targets stack and retain the number above a more compact summary.
All measurements are expressed through `Style.space`, `Style.spaceReal`, the
host bar size, and `PopupCard` fitting helpers rather than an independent scale.

The popover is anchored to the hovered workspace target and opens inward through
the native `PopupCard` geometry. Its width and height are bounded by inherited
fitting helpers; content switches from a column to a clipped list only when the
height cap is exceeded. Placement, screen bounds, and monitor ownership remain
delegated to `PopupCard`. Multi-monitor behavior has not been tested in the
current single-monitor environment.

**The Stable Target Rule.** Hover, focus, grouping, and overflow may change
content or surface treatment, but they must not move neighboring workspace
targets.

**The Three-Group Rule.** Keep at most three application groups in the bar and
represent every additional group with one bounded `+N` label.

## Elevation & Depth

Workspace Lens does not define shadows or elevation tokens. The bar targets use
the shared `BorderSurface` fills and borders, while detail appears in one native
`PopupCard`. Separation comes from host-owned surface treatment, an accent edge
on the focused target, and restrained spacing between groups. Application
groups are never wrapped in nested cards.

**The Single Surface Rule.** Use one inherited popover surface for detail and
keep its internal groups flat.

## Shapes

Target surfaces and missing-icon fallbacks use the inherited
`Style.cornerRadius`. Count badges are circular, formed by setting their radius
to half their size. The focused accent edge is a narrow rounded strip that moves
from the bottom edge on horizontal bars to the right edge on vertical bars.

**The Inherited Geometry Rule.** Derive corners and dimensions from Omarchy
`Style` and host geometry; do not introduce fixed radii or bar dimensions.

## Components

### Workspace Target

Every target remains numbered and clickable, including empty workspaces. Empty
numbers are subdued; occupied targets add grouped application identities; the
focused target adds bold number weight, selected fill, selected border, and an
accent edge. Hover changes the inherited fill without changing layout. Pointer
activation and the accessible press action use the same workspace-switch path.

Horizontal targets use the larger inherited application-icon role. Vertical
targets use the smaller inherited icon role below the number. A multi-window
group adds a compact count: a circular accent badge horizontally and an accent
text marker in the constrained vertical layout.

### Application Icon

Each application group renders exactly one desktop-entry icon at a stable,
device-pixel-ratio-aware size. If resolution fails, a same-size inherited
background surface shows the first character of the application label, or `?`
when no character is available. Missing imagery never changes component
geometry.

### Workspace Popover

Hovering an occupied target for 180 ms opens one anchored informational panel;
empty workspaces never open it. Leaving both target and panel starts a 220 ms
close delay so the pointer can cross the anchor gap. Entering the panel cancels
that close. If the workspace disappears or becomes empty, pending and active
popover state is cleared.

The header shows the workspace number followed by pluralized application and
window totals. Each flat group contains an icon, bold application name, optional
count badge, and indented one-line window titles. The panel offers no
window-management actions and does not steal the workspace target's navigation
role.

## Do's and Don'ts

### Do:

- **Do** consume live Omarchy `Color`, `Style`, `Border`, `BorderSurface`, and
  `PopupCard` behavior.
- **Do** preserve numbered targets, deterministic workspace ordering, grouped
  application identity, and bounded overflow.
- **Do** keep names and titles single-line, ellipsized, and within the fitted
  popover bounds.
- **Do** retain stable geometry for unresolved application IDs, missing titles,
  and failed icon resolution.
- **Do** rebuild visual records from live Hyprland events so counts and rows do
  not become stale.

### Don't:

- **Don't** hard-code theme colors, font sizes, spacing, radii, or bar dimensions.
- **Don't** render one icon per window or allow the bar summary to exceed three
  application groups.
- **Don't** create nested cards inside the popover.
- **Don't** move targets on hover or reduce focused state to color alone.
- **Don't** make application or title rows actionable in the informational first
  release.
- **Don't** poll `hyprctl` for workspace state; consume Quickshell's live
  Hyprland models.

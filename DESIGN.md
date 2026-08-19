# Workspace Lens Design System

Workspace Lens is an Operate-mode extension of the Omarchy bar. It inherits the
active Omarchy theme and component language instead of defining a separate
palette or density scale.

## Foundations

- Colors come from `Color`, including the bar foreground, `Color.accent`,
  `Color.background`, and the popup surface roles owned by `PopupCard`.
- Spacing, type sizes, bar dimensions, and radii come from `Style`.
- Interactive surfaces use `BorderSurface`, `Border`, and the shared selected
  and hover fill helpers. No Hackerman-specific color is a product token.
- Application images use the Omarchy application library and Quickshell icon
  lookup. Source images request device-pixel-ratio-aware sizes.

## Workspace target

Every visible workspace keeps a numbered, clickable target. Workspaces 1–5 are
always present; occupied workspaces up to 10 may extend the set. Workspace 10
uses `0`, matching the incumbent widget.

The horizontal anatomy is number, application summary, then overflow. The
summary shows at most three application groups. Each group occupies one icon;
multiple windows add a compact count badge without duplicating the icon. Any
remaining groups collapse to `+N`, so content cannot grow without bound.

Horizontal bar icons use `Style.space(12)`. A vertical bar preserves the number
and uses `Style.space(8)` icons in a compact row. The target cross-axis remains
the bar size in either orientation. Empty workspaces show only the number and
never open a panel.

## States

- Empty: persistent number, no application summary.
- Occupied: number plus grouped application identities.
- Hover: shared Omarchy hover fill, without layout movement.
- Active: shared selected fill and border plus an accent edge, so focus is not
  communicated by color alone.
- Grouped: one icon plus the window count.
- Overflow: three icons followed by `+N`.
- Missing icon: a stable, background-token surface with the application's first
  letter; its dimensions match a resolved icon.

## Popover

The detail view is one inherited `PopupCard`, anchored to the hovered target and
therefore to its originating bar window and monitor. The card opens inward for
top, bottom, left, and right bars using the popup primitive's native geometry.

The header names the workspace and reports application and window totals. Each
group then shows a `Style.space(10)` icon, application name, optional count, and
its window titles. Titles are indented, restricted to one line, ellipsized, and
expose their full text through the bar tooltip when truncated. Content height is
capped and switches to a clipped list when necessary.

Hover intent opens after 180 ms. Leaving both target and panel closes after
220 ms, preserving the crossing path and preventing flashes during rapid scans.
The panel is informational and never activates or closes application windows.

## Orientation and resilience

Workspace ordering and target identity do not change with bar orientation.
Horizontal bars lay targets in columns; vertical bars stack them in rows. Popup
placement, screen bounds, and monitor ownership remain the responsibility of
`PopupCard`.

Unknown application IDs and missing titles retain stable layout through model
fallbacks. Names and titles never widen the card beyond its cap. Live Hyprland
events rebuild the active and pending records so moves, retitles, and closes do
not leave stale counts or rows.

## Anti-patterns

- Do not hard-code theme colors, font sizes, spacing, radii, or bar dimensions.
- Do not render one icon per window or let the bar grow past three groups.
- Do not create nested cards inside the popover.
- Do not poll `hyprctl`; consume Quickshell's live Hyprland models.
- Do not make title rows actionable in the informational first release.
- Do not replace the active edge with color-only state or move targets on hover.
